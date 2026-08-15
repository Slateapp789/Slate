-- Store public-launch interest behind an Edge-only boundary. Anonymous and
-- authenticated clients never receive table access; the public website calls
-- the join-waitlist Edge Function, which uses the service role after bounded
-- validation and salted email-based rate limiting.

alter table app_private.edge_rate_limit_events
  drop constraint if exists edge_rate_limit_events_scope_check;

alter table app_private.edge_rate_limit_events
  add constraint edge_rate_limit_events_scope_check check (
    scope in (
      'booking_source',
      'booking_phone',
      'places_autocomplete',
      'places_details',
      'waitlist_email'
    )
  );

create table if not exists app_private.launch_waitlist (
  id bigint generated always as identity primary key,
  email text not null unique,
  source text not null default 'website',
  status text not null default 'active'
    check (status in ('active', 'invited', 'unsubscribed')),
  consent_at timestamptz not null default clock_timestamp(),
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  constraint launch_waitlist_email_check check (
    email = lower(btrim(email))
    and char_length(email) between 3 and 254
    and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
  ),
  constraint launch_waitlist_source_check check (
    source ~ '^[a-z0-9_-]{1,40}$'
  )
);

create index if not exists launch_waitlist_status_created_idx
  on app_private.launch_waitlist(status, created_at desc);

alter table app_private.launch_waitlist enable row level security;

revoke all on table app_private.launch_waitlist from public, anon, authenticated;
grant select, insert, update on table app_private.launch_waitlist to service_role;

revoke all on sequence app_private.launch_waitlist_id_seq
  from public, anon, authenticated;
grant usage, select on sequence app_private.launch_waitlist_id_seq
  to service_role;

create or replace function public.join_launch_waitlist(
  p_email text,
  p_subject_hash text,
  p_source text default 'website'
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_source text := lower(btrim(coalesce(p_source, 'website')));
  v_source_count integer;
  v_existing boolean;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  if char_length(v_email) not between 3 and 254
    or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    or p_subject_hash is null
    or p_subject_hash !~ '^[0-9a-f]{64}$'
    or v_source !~ '^[a-z0-9_-]{1,40}$'
  then
    raise exception 'invalid waitlist request' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('workloop:waitlist:' || p_subject_hash, 0)
  );

  delete from app_private.edge_rate_limit_events
  where created_at < v_now - interval '1 day';

  select count(*)::integer
  into v_source_count
  from app_private.edge_rate_limit_events
  where scope = 'waitlist_email'
    and resource_key = v_source
    and subject_key = p_subject_hash
    and created_at >= v_now - interval '15 minutes';

  if v_source_count >= 3 then
    return 'rate_limited';
  end if;

  insert into app_private.edge_rate_limit_events(
    scope,
    resource_key,
    subject_key,
    created_at
  ) values ('waitlist_email', v_source, p_subject_hash, v_now);

  select exists (
    select 1
    from app_private.launch_waitlist
    where email = v_email
  ) into v_existing;

  insert into app_private.launch_waitlist(
    email,
    source,
    status,
    consent_at,
    created_at,
    updated_at
  ) values (
    v_email,
    v_source,
    'active',
    v_now,
    v_now,
    v_now
  )
  on conflict (email) do update set
    source = excluded.source,
    status = 'active',
    consent_at = excluded.consent_at,
    updated_at = excluded.updated_at;

  return case when v_existing then 'duplicate' else 'created' end;
end;
$$;

revoke all on function public.join_launch_waitlist(text, text, text)
  from public, anon, authenticated;
grant execute on function public.join_launch_waitlist(text, text, text)
  to service_role;
