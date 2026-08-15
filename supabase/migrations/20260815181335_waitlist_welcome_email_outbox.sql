-- Deliver a durable welcome receipt for every active launch-list signup.
-- The public table remains private; only the service-role Edge boundary can
-- enqueue, claim, or acknowledge mail. Existing active signups are backfilled
-- once so nobody who joined before this release is missed.

create table app_private.waitlist_email_outbox (
  id uuid primary key default gen_random_uuid(),
  waitlist_id bigint not null references app_private.launch_waitlist(id)
    on delete cascade,
  event text not null default 'launch_waitlist_joined'
    check (event = 'launch_waitlist_joined'),
  recipient_email text not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'sent', 'failed')),
  attempt_count integer not null default 0 check (attempt_count between 0 and 8),
  next_attempt_at timestamptz not null default clock_timestamp(),
  lease_token uuid,
  lease_expires_at timestamptz,
  delivery_expires_at timestamptz not null default clock_timestamp() + interval '24 hours',
  provider_message_id text,
  last_error text,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  sent_at timestamptz,
  unique (event, waitlist_id),
  constraint waitlist_email_outbox_recipient_check check (
    recipient_email = lower(btrim(recipient_email))
    and char_length(recipient_email) between 3 and 254
    and recipient_email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
  )
);

create index waitlist_email_outbox_due_idx
  on app_private.waitlist_email_outbox(next_attempt_at, created_at)
  where status in ('pending', 'processing');

alter table app_private.waitlist_email_outbox enable row level security;
revoke all on table app_private.waitlist_email_outbox
  from public, anon, authenticated;
grant select, insert, update on table app_private.waitlist_email_outbox
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
  v_waitlist_id bigint;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  if char_length(v_email) not between 3 and 254
    or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    or p_subject_hash is null or p_subject_hash !~ '^[0-9a-f]{64}$'
    or v_source !~ '^[a-z0-9_-]{1,40}$' then
    raise exception 'invalid waitlist request' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('workloop:waitlist:' || p_subject_hash, 0));
  delete from app_private.edge_rate_limit_events
   where created_at < v_now - interval '1 day';
  select count(*)::integer into v_source_count
    from app_private.edge_rate_limit_events
   where scope = 'waitlist_email' and resource_key = v_source
     and subject_key = p_subject_hash and created_at >= v_now - interval '15 minutes';
  if v_source_count >= 3 then return 'rate_limited'; end if;
  insert into app_private.edge_rate_limit_events(scope, resource_key, subject_key, created_at)
  values ('waitlist_email', v_source, p_subject_hash, v_now);

  select exists(select 1 from app_private.launch_waitlist where email = v_email)
    into v_existing;
  insert into app_private.launch_waitlist(email, source, status, consent_at, created_at, updated_at)
  values (v_email, v_source, 'active', v_now, v_now, v_now)
  on conflict (email) do update set source = excluded.source, status = 'active',
    consent_at = excluded.consent_at, updated_at = excluded.updated_at
  returning id into v_waitlist_id;

  insert into app_private.waitlist_email_outbox(waitlist_id, recipient_email)
  values (v_waitlist_id, v_email)
  on conflict (event, waitlist_id) do nothing;
  return case when v_existing then 'duplicate' else 'created' end;
end;
$$;

insert into app_private.waitlist_email_outbox(waitlist_id, recipient_email)
select id, email from app_private.launch_waitlist where status = 'active'
on conflict (event, waitlist_id) do nothing;

create or replace function public.claim_waitlist_welcome_emails(p_limit integer default 20)
returns table(outbox_id uuid, lease_token uuid, recipient_email text, attempt_count integer)
language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  if p_limit not between 1 and 50 then
    raise exception 'claim limit must be between 1 and 50' using errcode = '22023';
  end if;
  update app_private.waitlist_email_outbox email set status = 'failed',
    lease_token = null, lease_expires_at = null,
    last_error = 'Delivery window expired', updated_at = clock_timestamp()
  where email.status in ('pending', 'processing')
    and (email.delivery_expires_at <= clock_timestamp() or email.attempt_count >= 8);
  return query with candidates as (
    select email.id from app_private.waitlist_email_outbox email
    where email.status in ('pending', 'processing')
      and email.next_attempt_at <= clock_timestamp()
      and email.delivery_expires_at > clock_timestamp() and email.attempt_count < 8
      and (email.status = 'pending' or email.lease_expires_at <= clock_timestamp())
    order by email.next_attempt_at, email.created_at for update skip locked limit p_limit
  ), claimed as (
    update app_private.waitlist_email_outbox email set status = 'processing',
      attempt_count = email.attempt_count + 1, lease_token = gen_random_uuid(),
      lease_expires_at = clock_timestamp() + interval '5 minutes', updated_at = clock_timestamp()
    from candidates where email.id = candidates.id
    returning email.id, email.lease_token, email.recipient_email, email.attempt_count
  ) select claimed.id, claimed.lease_token, claimed.recipient_email, claimed.attempt_count from claimed;
end;
$$;

create or replace function public.finish_waitlist_welcome_email(
  p_outbox_id uuid, p_lease_token uuid, p_sent boolean,
  p_provider_message_id text default null, p_error text default null
)
returns text language plpgsql security definer set search_path = '' as $$
declare
  v_email app_private.waitlist_email_outbox%rowtype;
  v_status text;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;
  select email.* into v_email from app_private.waitlist_email_outbox email
  where email.id = p_outbox_id and email.status = 'processing'
    and email.lease_token = p_lease_token for update;
  if not found then raise exception 'email delivery lease was not found' using errcode = 'P0002'; end if;
  if p_sent then
    v_status := 'sent';
    update app_private.waitlist_email_outbox set status = 'sent',
      provider_message_id = left(nullif(btrim(p_provider_message_id), ''), 200),
      last_error = null, sent_at = clock_timestamp(), lease_token = null,
      lease_expires_at = null, updated_at = clock_timestamp() where id = p_outbox_id;
  elsif v_email.attempt_count >= 8 or v_email.delivery_expires_at <= clock_timestamp() then
    v_status := 'failed';
    update app_private.waitlist_email_outbox set status = 'failed',
      last_error = left(coalesce(nullif(btrim(p_error), ''), 'Provider delivery failed'), 500),
      lease_token = null, lease_expires_at = null, updated_at = clock_timestamp()
    where id = p_outbox_id;
  else
    v_status := 'pending';
    update app_private.waitlist_email_outbox set status = 'pending',
      next_attempt_at = clock_timestamp() + make_interval(mins => least(60,
        power(2::numeric, greatest(v_email.attempt_count - 1, 0))::integer)),
      last_error = left(coalesce(nullif(btrim(p_error), ''), 'Provider delivery failed'), 500),
      lease_token = null, lease_expires_at = null, updated_at = clock_timestamp()
    where id = p_outbox_id;
  end if;
  return v_status;
end;
$$;

revoke all on function public.claim_waitlist_welcome_emails(integer),
  public.finish_waitlist_welcome_email(uuid, uuid, boolean, text, text)
  from public, anon, authenticated;
grant execute on function public.claim_waitlist_welcome_emails(integer),
  public.finish_waitlist_welcome_email(uuid, uuid, boolean, text, text)
  to service_role;
