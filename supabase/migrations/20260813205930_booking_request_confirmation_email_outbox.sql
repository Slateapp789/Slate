-- Capture a public requester's email and commit a durable transactional-email
-- intent in the same transaction that confirms the request. Provider delivery
-- remains outside Postgres and is processed through a leased, service-role-only
-- outbox so an email outage never rolls back a confirmed booking.

alter table public.booking_requests
  add column if not exists email text;

alter table public.booking_requests
  drop constraint if exists booking_requests_email_check;

alter table public.booking_requests
  add constraint booking_requests_email_check check (
    email is null
    or (
      email = lower(btrim(email))
      and char_length(email) between 3 and 254
      and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    )
  );

comment on column public.booking_requests.email is
  'Normalized customer email captured by the public request flow. Nullable only for requests created before email capture was introduced.';

create table app_private.transactional_email_outbox (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  booking_request_id uuid not null
    references public.booking_requests(id) on delete cascade,
  event text not null check (event = 'booking_request_confirmed'),
  recipient_email text not null,
  payload jsonb not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'sent', 'failed')),
  attempt_count integer not null default 0
    check (attempt_count between 0 and 8),
  next_attempt_at timestamptz not null default clock_timestamp(),
  lease_token uuid,
  lease_expires_at timestamptz,
  delivery_expires_at timestamptz not null
    default (clock_timestamp() + interval '24 hours'),
  provider_message_id text,
  last_error text,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  sent_at timestamptz,
  unique (event, booking_request_id),
  check (char_length(recipient_email) between 3 and 254),
  check (jsonb_typeof(payload) = 'object'),
  check (provider_message_id is null or char_length(provider_message_id) <= 200),
  check (last_error is null or char_length(last_error) <= 500),
  check (
    (status = 'processing' and lease_token is not null and lease_expires_at is not null)
    or (status <> 'processing' and lease_token is null and lease_expires_at is null)
  ),
  check ((status = 'sent') = (sent_at is not null))
);

create index transactional_email_outbox_due_idx
  on app_private.transactional_email_outbox(next_attempt_at, created_at)
  where status in ('pending', 'processing');

alter table app_private.transactional_email_outbox enable row level security;
revoke all on table app_private.transactional_email_outbox
  from public, anon, authenticated;
grant select, insert, update on table app_private.transactional_email_outbox
  to service_role;

comment on table app_private.transactional_email_outbox is
  'Private leased outbox for bounded transactional email retries. Recipient and body data must never be written to application logs.';

-- Preserve the proven booking workflow implementation behind a new internal
-- name, then wrap it so request confirmation, contact enrichment and outbox
-- enqueue remain one Postgres transaction. The public RPC signature is stable.
alter function app_private.create_booking_workflow(jsonb)
  rename to create_booking_workflow_without_confirmation_email;

revoke all on function
  app_private.create_booking_workflow_without_confirmation_email(jsonb)
  from public, anon, authenticated;

create or replace function app_private.create_booking_workflow(
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
  v_workspace_id uuid;
  v_request_id uuid;
  v_contact_id uuid;
  v_request_email text;
  v_request_name text;
  v_business_name text;
  v_timezone text;
begin
  v_result := app_private.create_booking_workflow_without_confirmation_email(
    p_payload
  );

  begin
    v_workspace_id := nullif(p_payload ->> 'workspace_id', '')::uuid;
    v_request_id := nullif(p_payload ->> 'booking_request_id', '')::uuid;
    v_contact_id := nullif(v_result ->> 'contact_id', '')::uuid;
  exception when invalid_text_representation then
    -- The underlying workflow already validates these values. Keep a defensive
    -- error here in case its return contract changes later.
    raise exception 'Booking confirmation identifiers are invalid'
      using errcode = '22023';
  end;

  if v_request_id is null then
    return v_result || jsonb_build_object('booking_request_id', null);
  end if;

  select request.email, request.name, workspace.name, settings.timezone
    into v_request_email, v_request_name, v_business_name, v_timezone
    from public.booking_requests request
    join public.workspaces workspace on workspace.id = request.workspace_id
    left join public.workspace_settings settings
      on settings.workspace_id = request.workspace_id
   where request.id = v_request_id
     and request.workspace_id = v_workspace_id
     and request.status = 'confirmed';

  if not found then
    raise exception 'Confirmed booking request was not found'
      using errcode = 'P0002';
  end if;

  -- A phone match may intentionally reuse an existing client. Preserve a
  -- different known email; enrich only a blank record with the request email.
  if v_request_email is not null and v_contact_id is not null then
    update public.contacts
       set email = v_request_email
     where id = v_contact_id
       and workspace_id = v_workspace_id
       and nullif(btrim(coalesce(email, '')), '') is null;

    insert into app_private.transactional_email_outbox(
      workspace_id,
      booking_request_id,
      event,
      recipient_email,
      payload
    ) values (
      v_workspace_id,
      v_request_id,
      'booking_request_confirmed',
      v_request_email,
      jsonb_strip_nulls(jsonb_build_object(
        'booking_request_id', v_request_id,
        'customer_name', v_request_name,
        'business_name', v_business_name,
        'timezone', coalesce(nullif(btrim(v_timezone), ''), 'UTC'),
        'booking_title', nullif(btrim(coalesce(p_payload ->> 'title', '')), ''),
        'start_time', p_payload #>> '{appointments,0,start_time}',
        'end_time', p_payload #>> '{appointments,0,end_time}',
        'location', nullif(btrim(coalesce(p_payload ->> 'location', '')), '')
      ))
    )
    on conflict (event, booking_request_id) do nothing;
  end if;

  return v_result || jsonb_build_object(
    'booking_request_id', v_request_id
  );
end;
$$;

revoke all on function app_private.create_booking_workflow(jsonb)
  from public, anon, authenticated;
grant execute on function app_private.create_booking_workflow(jsonb)
  to service_role;

comment on function app_private.create_booking_workflow(jsonb) is
  'Atomic booking workflow wrapper that enriches a blank reused-client email and enqueues one confirmation email intent.';

-- Add the public email contract without breaking the previously deployed Edge
-- version during a staged rollout. The old service-role-only RPC can be retired
-- after every environment is running the new Edge function.
create or replace function public.create_public_booking_request_v2(
  p_workspace_id uuid,
  p_name text,
  p_phone text,
  p_email text,
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
set search_path = pg_catalog, public
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_result record;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  if char_length(v_email) not between 3 and 254
     or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'invalid booking request email' using errcode = '22023';
  end if;

  select request.booking_request_id, request.outcome
    into v_result
    from public.create_public_booking_request(
      p_workspace_id,
      p_name,
      p_phone,
      p_service_id,
      p_preferred_time_text,
      p_message,
      p_source_hash,
      p_request_token
    ) request;

  if v_result.booking_request_id is not null
     and v_result.outcome in ('created', 'duplicate') then
    update public.booking_requests
       set email = coalesce(email, v_email)
     where id = v_result.booking_request_id
       and workspace_id = p_workspace_id;
  end if;

  return query
    select v_result.booking_request_id::uuid, v_result.outcome::text;
end;
$$;

revoke all on function public.create_public_booking_request_v2(
  uuid, text, text, text, uuid, text, text, text, uuid
) from public, anon, authenticated;
grant execute on function public.create_public_booking_request_v2(
  uuid, text, text, text, uuid, text, text, text, uuid
) to service_role;

comment on function public.create_public_booking_request_v2(
  uuid, text, text, text, uuid, text, text, text, uuid
) is
  'Service-role-only public booking request workflow with normalized required email capture.';

create or replace function public.claim_booking_confirmation_emails(
  p_limit integer default 20,
  p_booking_request_id uuid default null
)
returns table (
  outbox_id uuid,
  booking_request_id uuid,
  lease_token uuid,
  recipient_email text,
  payload jsonb,
  attempt_count integer
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  if p_limit not between 1 and 50 then
    raise exception 'claim limit must be between 1 and 50'
      using errcode = '22023';
  end if;

  update app_private.transactional_email_outbox email
     set status = 'failed',
         lease_token = null,
         lease_expires_at = null,
         last_error = 'Delivery window expired',
         updated_at = clock_timestamp()
   where email.event = 'booking_request_confirmed'
     and email.status in ('pending', 'processing')
     and (
       email.delivery_expires_at <= clock_timestamp()
       or email.attempt_count >= 8
     );

  return query
  with candidates as (
    select email.id
      from app_private.transactional_email_outbox email
     where email.event = 'booking_request_confirmed'
       and email.status in ('pending', 'processing')
       and email.next_attempt_at <= clock_timestamp()
       and email.delivery_expires_at > clock_timestamp()
       and email.attempt_count < 8
       and (
         email.status = 'pending'
         or email.lease_expires_at <= clock_timestamp()
       )
       and (
         p_booking_request_id is null
         or email.booking_request_id = p_booking_request_id
       )
     order by email.next_attempt_at, email.created_at
     for update skip locked
     limit p_limit
  ), claimed as (
    update app_private.transactional_email_outbox email
       set status = 'processing',
           attempt_count = email.attempt_count + 1,
           lease_token = gen_random_uuid(),
           lease_expires_at = clock_timestamp() + interval '5 minutes',
           updated_at = clock_timestamp()
      from candidates
     where email.id = candidates.id
    returning email.id, email.booking_request_id, email.lease_token,
      email.recipient_email, email.payload, email.attempt_count
  )
  select claimed.id, claimed.booking_request_id, claimed.lease_token,
    claimed.recipient_email, claimed.payload, claimed.attempt_count
    from claimed;
end;
$$;

create or replace function public.finish_booking_confirmation_email(
  p_outbox_id uuid,
  p_lease_token uuid,
  p_sent boolean,
  p_provider_message_id text default null,
  p_error text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email app_private.transactional_email_outbox%rowtype;
  v_status text;
  v_backoff_minutes integer;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  select email.* into v_email
    from app_private.transactional_email_outbox email
   where email.id = p_outbox_id
     and email.status = 'processing'
     and email.lease_token = p_lease_token
   for update;
  if not found then
    raise exception 'email delivery lease was not found'
      using errcode = 'P0002';
  end if;

  if p_sent then
    v_status := 'sent';
    update app_private.transactional_email_outbox
       set status = 'sent',
           provider_message_id = left(nullif(btrim(p_provider_message_id), ''), 200),
           last_error = null,
           sent_at = clock_timestamp(),
           lease_token = null,
           lease_expires_at = null,
           updated_at = clock_timestamp()
     where id = p_outbox_id;
  elsif v_email.attempt_count >= 8
        or v_email.delivery_expires_at <= clock_timestamp() then
    v_status := 'failed';
    update app_private.transactional_email_outbox
       set status = 'failed',
           last_error = left(coalesce(nullif(btrim(p_error), ''), 'Provider delivery failed'), 500),
           lease_token = null,
           lease_expires_at = null,
           updated_at = clock_timestamp()
     where id = p_outbox_id;
  else
    v_status := 'pending';
    v_backoff_minutes := least(
      60,
      power(2::numeric, greatest(v_email.attempt_count - 1, 0))::integer
    );
    update app_private.transactional_email_outbox
       set status = 'pending',
           next_attempt_at = clock_timestamp()
             + make_interval(mins => v_backoff_minutes),
           last_error = left(coalesce(nullif(btrim(p_error), ''), 'Provider delivery failed'), 500),
           lease_token = null,
           lease_expires_at = null,
           updated_at = clock_timestamp()
     where id = p_outbox_id;
  end if;

  return v_status;
end;
$$;

create or replace function public.booking_confirmation_email_status(
  p_booking_request_id uuid
)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_status text;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  select email.status into v_status
    from app_private.transactional_email_outbox email
   where email.booking_request_id = p_booking_request_id
     and email.event = 'booking_request_confirmed';
  return coalesce(v_status, 'not_applicable');
end;
$$;

revoke all on function public.claim_booking_confirmation_emails(integer, uuid),
  public.finish_booking_confirmation_email(uuid, uuid, boolean, text, text),
  public.booking_confirmation_email_status(uuid)
  from public, anon, authenticated;
grant execute on function public.claim_booking_confirmation_emails(integer, uuid),
  public.finish_booking_confirmation_email(uuid, uuid, boolean, text, text),
  public.booking_confirmation_email_status(uuid)
  to service_role;

comment on function public.claim_booking_confirmation_emails(integer, uuid) is
  'Service-role-only bounded email claim with stale-lease recovery and an eight-attempt, 24-hour delivery cap.';
comment on function public.finish_booking_confirmation_email(uuid, uuid, boolean, text, text) is
  'Service-role-only outbox acknowledgement with capped exponential retry backoff.';
