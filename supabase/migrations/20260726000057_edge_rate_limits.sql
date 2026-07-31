-- Edge-only rolling counters keep public booking writes and billable provider
-- lookups bounded. The functions below are intentionally callable only with a
-- service-role JWT; mobile clients cannot read or mutate the counter table.

create schema if not exists app_private;

create table if not exists app_private.edge_rate_limit_events (
  id bigint generated always as identity primary key,
  scope text not null check (
    scope in (
      'booking_source',
      'booking_phone',
      'places_autocomplete',
      'places_details'
    )
  ),
  resource_key text not null default '',
  subject_key text not null,
  created_at timestamptz not null default clock_timestamp()
);

create index if not exists edge_rate_limit_subject_window_idx
  on app_private.edge_rate_limit_events(
    scope,
    resource_key,
    subject_key,
    created_at desc
  );

create index if not exists edge_rate_limit_created_at_idx
  on app_private.edge_rate_limit_events(created_at);

alter table app_private.edge_rate_limit_events enable row level security;

revoke all on table app_private.edge_rate_limit_events from public;
revoke all on table app_private.edge_rate_limit_events from anon;
revoke all on table app_private.edge_rate_limit_events from authenticated;
grant select, insert, delete on table app_private.edge_rate_limit_events
  to service_role;

revoke all on sequence app_private.edge_rate_limit_events_id_seq from public;
revoke all on sequence app_private.edge_rate_limit_events_id_seq from anon;
revoke all on sequence app_private.edge_rate_limit_events_id_seq
  from authenticated;
grant usage, select on sequence app_private.edge_rate_limit_events_id_seq
  to service_role;

alter table public.booking_requests
  add column if not exists phone_normalized text
    generated always as (regexp_replace(phone, '[^0-9]', '', 'g')) stored,
  add column if not exists request_token uuid;

create unique index if not exists booking_requests_workspace_request_token_idx
  on public.booking_requests(workspace_id, request_token)
  where request_token is not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'booking_requests_normalized_phone_check'
      and conrelid = 'public.booking_requests'::regclass
  ) then
    alter table public.booking_requests
      add constraint booking_requests_normalized_phone_check
      check (char_length(phone_normalized) between 7 and 32)
      not valid;
  end if;
end $$;

create or replace function public.create_public_booking_request(
  p_workspace_id uuid,
  p_name text,
  p_phone text,
  p_service_id uuid,
  p_preferred_time_text text,
  p_message text,
  p_source_hash text,
  p_request_token uuid
)
returns table (
  booking_request_id uuid,
  outcome text
)
language plpgsql
security definer
set search_path = pg_catalog, public, app_private
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_phone_normalized text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  v_existing_id uuid;
  v_request_id uuid;
  v_source_count integer;
  v_phone_count integer;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  if p_workspace_id is null
    or p_request_token is null
    or p_source_hash is null
    or p_source_hash !~ '^[0-9a-f]{64}$'
    or char_length(btrim(coalesce(p_name, ''))) not between 1 and 80
    or char_length(btrim(coalesce(p_phone, ''))) not between 7 and 32
    or char_length(v_phone_normalized) not between 7 and 32
    or (
      p_preferred_time_text is not null
      and char_length(p_preferred_time_text) > 160
    )
    or (p_message is not null and char_length(p_message) > 1000)
  then
    raise exception 'invalid booking request' using errcode = '22023';
  end if;

  -- A workspace lock makes the rolling count and insert one serial operation.
  -- Workloop workspaces are single-owner and public-request volume is low, so
  -- this deliberately favours correctness over per-key lock complexity.
  perform pg_advisory_xact_lock(
    hashtextextended('workloop:booking:' || p_workspace_id::text, 0)
  );

  select request.id
  into v_existing_id
  from public.booking_requests as request
  where request.workspace_id = p_workspace_id
    and request.request_token = p_request_token
  limit 1;

  if v_existing_id is not null then
    return query select v_existing_id, 'duplicate'::text;
    return;
  end if;

  if not exists (
    select 1
    from public.business_profiles as profile
    where profile.workspace_id = p_workspace_id
      and profile.booking_mode = 'manual'
  ) then
    return query select null::uuid, 'profile_unavailable'::text;
    return;
  end if;

  if p_service_id is not null and not exists (
    select 1
    from public.services as service
    where service.id = p_service_id
      and service.workspace_id = p_workspace_id
      and service.show_on_profile = true
      and service.active = true
  ) then
    return query select null::uuid, 'invalid_service'::text;
    return;
  end if;

  delete from app_private.edge_rate_limit_events
  where created_at < v_now - interval '1 day';

  select count(*)::integer
  into v_source_count
  from app_private.edge_rate_limit_events
  where scope = 'booking_source'
    and resource_key = p_workspace_id::text
    and subject_key = p_source_hash
    and created_at >= v_now - interval '15 minutes';

  if v_source_count >= 5 then
    return query select null::uuid, 'rate_limited_source'::text;
    return;
  end if;

  select count(*)::integer
  into v_phone_count
  from app_private.edge_rate_limit_events
  where scope = 'booking_phone'
    and resource_key = p_workspace_id::text
    and subject_key = v_phone_normalized
    and created_at >= v_now - interval '15 minutes';

  if v_phone_count >= 3 then
    return query select null::uuid, 'rate_limited_phone'::text;
    return;
  end if;

  insert into public.booking_requests (
    workspace_id,
    name,
    phone,
    service_id,
    preferred_time_text,
    message,
    status,
    source_hash,
    request_token
  )
  values (
    p_workspace_id,
    btrim(p_name),
    btrim(p_phone),
    p_service_id,
    nullif(btrim(coalesce(p_preferred_time_text, '')), ''),
    nullif(btrim(coalesce(p_message, '')), ''),
    'pending',
    p_source_hash,
    p_request_token
  )
  returning id into v_request_id;

  insert into app_private.edge_rate_limit_events(
    scope,
    resource_key,
    subject_key,
    created_at
  )
  values
    ('booking_source', p_workspace_id::text, p_source_hash, v_now),
    ('booking_phone', p_workspace_id::text, v_phone_normalized, v_now);

  insert into public.notifications(
    workspace_id,
    type,
    title,
    body,
    deep_link
  )
  values (
    p_workspace_id,
    'booking_request',
    'New booking request',
    btrim(p_name) || ' requested a booking.',
    '/booking-requests'
  );

  return query select v_request_id, 'created'::text;
end;
$$;

revoke all on function public.create_public_booking_request(
  uuid,
  text,
  text,
  uuid,
  text,
  text,
  text,
  uuid
) from public;
revoke all on function public.create_public_booking_request(
  uuid,
  text,
  text,
  uuid,
  text,
  text,
  text,
  uuid
) from anon;
revoke all on function public.create_public_booking_request(
  uuid,
  text,
  text,
  uuid,
  text,
  text,
  text,
  uuid
) from authenticated;
grant execute on function public.create_public_booking_request(
  uuid,
  text,
  text,
  uuid,
  text,
  text,
  text,
  uuid
) to service_role;

create or replace function public.consume_places_rate_limit(
  p_subject_hash text,
  p_bucket text
)
returns table (
  allowed boolean,
  retry_after_seconds integer,
  remaining integer
)
language plpgsql
security definer
set search_path = pg_catalog, public, app_private
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_scope text;
  v_limit integer;
  v_window interval := interval '15 minutes';
  v_count integer;
  v_oldest timestamptz;
  v_retry_after integer;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  if p_subject_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid rate-limit subject' using errcode = '22023';
  end if;

  case p_bucket
    when 'autocomplete' then
      v_scope := 'places_autocomplete';
      v_limit := 90;
    when 'details' then
      v_scope := 'places_details';
      v_limit := 30;
    else
      raise exception 'invalid Places rate-limit bucket' using errcode = '22023';
  end case;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'workloop:places:' || v_scope || ':' || p_subject_hash,
      0
    )
  );

  delete from app_private.edge_rate_limit_events
  where created_at < v_now - interval '1 day';

  select count(*)::integer, min(created_at)
  into v_count, v_oldest
  from app_private.edge_rate_limit_events
  where scope = v_scope
    and resource_key = ''
    and subject_key = p_subject_hash
    and created_at >= v_now - v_window;

  if v_count >= v_limit then
    v_retry_after := greatest(
      1,
      ceil(extract(epoch from (v_oldest + v_window - v_now)))::integer
    );
    return query select false, v_retry_after, 0;
    return;
  end if;

  insert into app_private.edge_rate_limit_events(
    scope,
    resource_key,
    subject_key,
    created_at
  )
  values (v_scope, '', p_subject_hash, v_now);

  return query
    select true, 0, greatest(v_limit - v_count - 1, 0);
end;
$$;

revoke all on function public.consume_places_rate_limit(text, text)
  from public;
revoke all on function public.consume_places_rate_limit(text, text)
  from anon;
revoke all on function public.consume_places_rate_limit(text, text)
  from authenticated;
grant execute on function public.consume_places_rate_limit(text, text)
  to service_role;

comment on table app_private.edge_rate_limit_events is
  'Short-lived Edge-only events used for atomic rolling request budgets.';
comment on function public.create_public_booking_request(
  uuid,
  text,
  text,
  uuid,
  text,
  text,
  text,
  uuid
) is
  'Service-role-only atomic public booking insert, idempotency, and rate limit.';
comment on function public.consume_places_rate_limit(text, text) is
  'Service-role-only per-user rolling budget for billable Places calls.';
