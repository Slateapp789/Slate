begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(16);

select ok(
  to_regprocedure('public.current_user_meets_mfa_policy()') is not null,
  'authenticated Edge Functions have a bounded current-user MFA RPC'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.current_user_meets_mfa_policy()',
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.current_user_meets_mfa_policy()',
    'EXECUTE'
  ),
  'the MFA RPC is authenticated-only'
);

select is(
  (
    select count(*)::bigint
      from pg_proc procedure
      join pg_namespace namespace on namespace.oid = procedure.pronamespace
     where namespace.nspname = 'app_private'
       and procedure.proname = any(array[
         'create_task_workflow',
         'create_booking_workflow',
         'complete_booking_workflow'
       ])
       and has_function_privilege(
         'authenticated',
         procedure.oid,
         'EXECUTE'
       )
  ),
  0::bigint,
  'authenticated clients cannot bypass guarded workflow wrappers'
);

select is(
  (
    select count(*)::bigint
      from pg_proc procedure
      join pg_namespace namespace on namespace.oid = procedure.pronamespace
     where namespace.nspname = 'public'
       and procedure.proname = any(array[
         'create_task_workflow',
         'create_booking_workflow',
         'complete_booking_workflow'
       ])
       and procedure.prosecdef
       and procedure.prosrc like '%current_user_meets_mfa_policy%'
  ),
  3::bigint,
  'all three authenticated workflow wrappers enforce the MFA policy'
);

select ok(
  to_regprocedure(
    'app_private.complete_onboarding_implementation(text,text,text,jsonb,jsonb,numeric,jsonb)'
  ) is not null,
  'the onboarding implementation is private'
);

select ok(
  not has_function_privilege(
    'authenticated',
    'app_private.complete_onboarding_implementation(text,text,text,jsonb,jsonb,numeric,jsonb)',
    'EXECUTE'
  ),
  'authenticated clients cannot bypass guarded onboarding'
);

select ok(
  (
    select procedure.prosecdef
      from pg_proc procedure
     where procedure.oid = to_regprocedure(
       'public.complete_onboarding(text,text,text,jsonb,jsonb,numeric,jsonb)'
     )
  )
  and (
    select procedure.prosrc like '%current_user_meets_mfa_policy%'
      from pg_proc procedure
     where procedure.oid = to_regprocedure(
       'public.complete_onboarding(text,text,text,jsonb,jsonb,numeric,jsonb)'
     )
  ),
  'public onboarding is an MFA-aware security-definer wrapper'
);

select has_column(
  'app_private',
  'stripe_webhook_events',
  'workspace_id',
  'webhook events are tied to a Workloop workspace while active'
);

select has_column(
  'app_private',
  'stripe_webhook_events',
  'payload_expires_at',
  'webhook payload retention has an explicit deadline'
);

select has_column(
  'app_private',
  'stripe_webhook_events',
  'sanitized_at',
  'webhook payload scrubbing is auditable'
);

select ok(
  exists (
    select 1
      from pg_trigger trigger_row
      join pg_class relation on relation.oid = trigger_row.tgrelid
      join pg_namespace namespace on namespace.oid = relation.relnamespace
     where namespace.nspname = 'public'
       and relation.relname = 'workspaces'
       and trigger_row.tgname = 'scrub_stripe_webhooks_before_workspace_delete'
       and not trigger_row.tgisinternal
  ),
  'workspace deletion scrubs retained webhook PII'
);

select ok(
  has_function_privilege(
    'service_role',
    'app_private.scrub_expired_stripe_webhook_payloads()',
    'EXECUTE'
  )
  and not has_function_privilege(
    'authenticated',
    'app_private.scrub_expired_stripe_webhook_payloads()',
    'EXECUTE'
  ),
  'only the service role can run explicit payload cleanup'
);

select ok(
  exists (
    select 1
      from cron.job
     where jobname = 'workloop-scrub-stripe-webhook-payloads'
       and schedule = '17 * * * *'
  ),
  'expired webhook payload cleanup is scheduled hourly'
);

insert into public.workspaces(id, name)
values ('30000000-0000-4000-8000-000000000001', 'Retention contract');

insert into public.workspace_payment_accounts(
  workspace_id,
  stripe_account_id
) values (
  '30000000-0000-4000-8000-000000000001',
  'acct_RetentionContract'
);

select ok(
  public.claim_stripe_webhook_event(
    'evt_retention_contract',
    'acct_RetentionContract',
    'account.updated',
    false,
    '{"id":"evt_retention_contract","data":{"object":{"email":"private@example.com"}}}'::jsonb
  ),
  'an active workspace webhook is claimed'
);

select isnt(
  (
    select payload
      from app_private.stripe_webhook_events
     where stripe_event_id = 'evt_retention_contract'
  ),
  '{}'::jsonb,
  'an active payload remains available for bounded retry/support'
);

delete from public.workspaces
where id = '30000000-0000-4000-8000-000000000001';

select ok(
  (
    select payload = '{}'::jsonb
       and workspace_id is null
       and stripe_account_id is null
       and sanitized_at is not null
      from app_private.stripe_webhook_events
     where stripe_event_id = 'evt_retention_contract'
  ),
  'workspace deletion removes webhook payload PII and account identifiers'
);

select * from finish();
rollback;
