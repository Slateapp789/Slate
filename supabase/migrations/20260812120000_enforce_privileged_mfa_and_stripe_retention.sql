-- Close privileged RPC boundaries for users who have enrolled a verified MFA
-- factor, and bound retention of Stripe webhook payloads that can contain PII.
-- This is a forward-only remediation for environments where the original MFA
-- migration has already been recorded. It deliberately does not change the
-- opt-in policy: users without a verified factor continue to use AAL1.

create or replace function public.current_user_meets_mfa_policy()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select app_private.current_user_meets_mfa_policy();
$$;

comment on function public.current_user_meets_mfa_policy() is
  'Safe current-user RPC used by authenticated Edge Functions. Requires AAL2 only when a verified MFA factor is enrolled.';

revoke all on function public.current_user_meets_mfa_policy()
  from public, anon;
grant execute on function public.current_user_meets_mfa_policy()
  to authenticated, service_role;

-- The onboarding implementation predates the public-wrapper convention. Move
-- it behind an internal name once, then keep the public contract stable.
do $$
begin
  if to_regprocedure(
    'app_private.complete_onboarding_implementation(text,text,text,jsonb,jsonb,numeric,jsonb)'
  ) is null then
    if to_regprocedure(
      'public.complete_onboarding(text,text,text,jsonb,jsonb,numeric,jsonb)'
    ) is null then
      raise exception 'complete_onboarding implementation is missing';
    end if;

    alter function public.complete_onboarding(
      text, text, text, jsonb, jsonb, numeric, jsonb
    ) rename to complete_onboarding_implementation;
    alter function public.complete_onboarding_implementation(
      text, text, text, jsonb, jsonb, numeric, jsonb
    ) set schema app_private;
  end if;
end;
$$;

revoke all on function app_private.complete_onboarding_implementation(
  text, text, text, jsonb, jsonb, numeric, jsonb
) from public, anon, authenticated;
grant execute on function app_private.complete_onboarding_implementation(
  text, text, text, jsonb, jsonb, numeric, jsonb
) to service_role;

create or replace function public.complete_onboarding(
  business_name text,
  industry_name text,
  profile_handle text,
  service_rows jsonb,
  working_hours_value jsonb,
  revenue_target_value numeric,
  first_booking_value jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not app_private.current_user_meets_mfa_policy() then
    raise exception 'Multi-factor authentication is required'
      using errcode = '42501';
  end if;

  return app_private.complete_onboarding_implementation(
    business_name,
    industry_name,
    profile_handle,
    service_rows,
    working_hours_value,
    revenue_target_value,
    first_booking_value
  );
end;
$$;

revoke all on function public.complete_onboarding(
  text, text, text, jsonb, jsonb, numeric, jsonb
) from public, anon;
grant execute on function public.complete_onboarding(
  text, text, text, jsonb, jsonb, numeric, jsonb
) to authenticated;

create or replace function public.create_task_workflow(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not app_private.current_user_meets_mfa_policy() then
    raise exception 'Multi-factor authentication is required'
      using errcode = '42501';
  end if;
  return app_private.create_task_workflow(p_payload);
end;
$$;

create or replace function public.create_booking_workflow(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not app_private.current_user_meets_mfa_policy() then
    raise exception 'Multi-factor authentication is required'
      using errcode = '42501';
  end if;
  return app_private.create_booking_workflow(p_payload);
end;
$$;

create or replace function public.complete_booking_workflow(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not app_private.current_user_meets_mfa_policy() then
    raise exception 'Multi-factor authentication is required'
      using errcode = '42501';
  end if;
  return app_private.complete_booking_workflow(p_payload);
end;
$$;

revoke all on function public.create_task_workflow(jsonb),
  public.create_booking_workflow(jsonb),
  public.complete_booking_workflow(jsonb)
  from public, anon;
grant execute on function public.create_task_workflow(jsonb),
  public.create_booking_workflow(jsonb),
  public.complete_booking_workflow(jsonb)
  to authenticated;

-- Clients must enter through the guarded public wrappers. Trigger-only and
-- counter functions remain available to their owning functions/service role.
revoke execute on function app_private.create_task_workflow(jsonb),
  app_private.create_booking_workflow(jsonb),
  app_private.complete_booking_workflow(jsonb),
  app_private.next_payment_number(uuid)
  from public, anon, authenticated;

comment on function public.create_task_workflow(jsonb) is
  'MFA-aware authenticated wrapper for atomic task creation.';
comment on function public.create_booking_workflow(jsonb) is
  'MFA-aware authenticated wrapper for atomic booking creation.';
comment on function public.complete_booking_workflow(jsonb) is
  'MFA-aware authenticated wrapper for atomic booking completion and linked payment handling.';

alter table app_private.stripe_webhook_events
  add column if not exists workspace_id uuid,
  add column if not exists payload_expires_at timestamptz,
  add column if not exists sanitized_at timestamptz;

update app_private.stripe_webhook_events as event
   set workspace_id = account.workspace_id
  from public.workspace_payment_accounts as account
 where event.workspace_id is null
   and event.stripe_account_id = account.stripe_account_id;

update app_private.stripe_webhook_events
   set payload_expires_at = received_at + interval '30 days'
 where payload_expires_at is null;

-- Events that cannot be tied to an active Workloop workspace have no retry or
-- support need that justifies retaining their full provider payload.
update app_private.stripe_webhook_events
   set payload = '{}'::jsonb,
       stripe_account_id = null,
       error_message = null,
       sanitized_at = coalesce(sanitized_at, now())
 where workspace_id is null
    or payload_expires_at <= now();

alter table app_private.stripe_webhook_events
  alter column payload_expires_at set default (now() + interval '30 days'),
  alter column payload_expires_at set not null;

alter table app_private.stripe_webhook_events
  drop constraint if exists stripe_webhook_events_workspace_id_fkey;
alter table app_private.stripe_webhook_events
  add constraint stripe_webhook_events_workspace_id_fkey
  foreign key (workspace_id)
  references public.workspaces(id)
  on delete set null;

create index if not exists stripe_webhook_payload_expiry_idx
  on app_private.stripe_webhook_events (payload_expires_at)
  where sanitized_at is null;

-- The workspace link drives deletion-time scrubbing. Index the FK so deleting
-- one workspace does not scan the entire webhook ledger.
create index if not exists stripe_webhook_events_workspace_idx
  on app_private.stripe_webhook_events (workspace_id)
  where workspace_id is not null;

create or replace function app_private.scrub_expired_stripe_webhook_payloads()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_scrubbed integer;
begin
  update app_private.stripe_webhook_events
     set payload = '{}'::jsonb,
         stripe_account_id = null,
         error_message = null,
         sanitized_at = coalesce(sanitized_at, now())
   where sanitized_at is null
     and payload_expires_at <= now();
  get diagnostics v_scrubbed = row_count;
  return v_scrubbed;
end;
$$;

revoke all on function app_private.scrub_expired_stripe_webhook_payloads()
  from public, anon, authenticated;
grant execute on function app_private.scrub_expired_stripe_webhook_payloads()
  to service_role;

create or replace function app_private.scrub_workspace_stripe_webhook_payloads()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update app_private.stripe_webhook_events
     set payload = '{}'::jsonb,
         stripe_account_id = null,
         workspace_id = null,
         error_message = null,
         sanitized_at = coalesce(sanitized_at, now())
   where workspace_id = old.id;
  return old;
end;
$$;

revoke all on function app_private.scrub_workspace_stripe_webhook_payloads()
  from public, anon, authenticated;
grant execute on function app_private.scrub_workspace_stripe_webhook_payloads()
  to service_role;

drop trigger if exists scrub_stripe_webhooks_before_workspace_delete
  on public.workspaces;
create trigger scrub_stripe_webhooks_before_workspace_delete
before delete on public.workspaces
for each row execute function
  app_private.scrub_workspace_stripe_webhook_payloads();

create or replace function public.claim_stripe_webhook_event(
  p_event_id text,
  p_account_id text,
  p_event_type text,
  p_livemode boolean,
  p_payload jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_claimed boolean;
  v_workspace_id uuid;
begin
  perform app_private.scrub_expired_stripe_webhook_payloads();

  select account.workspace_id
    into v_workspace_id
    from public.workspace_payment_accounts as account
   where account.stripe_account_id = p_account_id;

  insert into app_private.stripe_webhook_events(
    stripe_event_id,
    workspace_id,
    stripe_account_id,
    event_type,
    livemode,
    payload,
    payload_expires_at,
    sanitized_at,
    status,
    attempt_count,
    last_attempted_at
  ) values (
    p_event_id,
    v_workspace_id,
    case when v_workspace_id is null then null else p_account_id end,
    p_event_type,
    p_livemode,
    case when v_workspace_id is null then '{}'::jsonb else p_payload end,
    now() + interval '30 days',
    case when v_workspace_id is null then now() else null end,
    'processing',
    1,
    now()
  )
  on conflict (stripe_event_id) do update
    set workspace_id = excluded.workspace_id,
        stripe_account_id = excluded.stripe_account_id,
        event_type = excluded.event_type,
        livemode = excluded.livemode,
        payload = excluded.payload,
        payload_expires_at = excluded.payload_expires_at,
        sanitized_at = excluded.sanitized_at,
        status = 'processing',
        error_message = null,
        processed_at = null,
        attempt_count =
          app_private.stripe_webhook_events.attempt_count + 1,
        last_attempted_at = now()
  where app_private.stripe_webhook_events.status = 'failed'
     or (
       app_private.stripe_webhook_events.status = 'processing'
       and app_private.stripe_webhook_events.last_attempted_at
         < now() - interval '5 minutes'
     )
  returning true into v_claimed;

  return coalesce(v_claimed, false);
end;
$$;

revoke all on function public.claim_stripe_webhook_event(
  text, text, text, boolean, jsonb
) from public, anon, authenticated;
grant execute on function public.claim_stripe_webhook_event(
  text, text, text, boolean, jsonb
) to service_role;

comment on column app_private.stripe_webhook_events.payload_expires_at is
  'Full signed provider payload expires after 30 days for retry/support, then is scrubbed by the hourly retention job or opportunistically on webhook receipt.';
comment on column app_private.stripe_webhook_events.sanitized_at is
  'Set when payload, connected-account identifier, and error detail have been removed.';

-- Supabase Cron is backed by pg_cron. The named job is replaced so a replay or
-- repaired migration cannot create duplicate cleanup workers.
create extension if not exists pg_cron with schema pg_catalog;

do $$
declare
  v_job_id bigint;
begin
  for v_job_id in
    select jobid
      from cron.job
     where jobname = 'workloop-scrub-stripe-webhook-payloads'
  loop
    perform cron.unschedule(v_job_id);
  end loop;
end;
$$;

select cron.schedule(
  'workloop-scrub-stripe-webhook-payloads',
  '17 * * * *',
  'select app_private.scrub_expired_stripe_webhook_payloads();'
);
