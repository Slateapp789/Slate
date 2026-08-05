begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(36);

select has_table('public', table_name, table_name || ' exists')
from unnest(array[
  'workspaces',
  'workspace_members',
  'workspace_settings',
  'contacts',
  'services',
  'appointments',
  'invoices',
  'invoice_line_items',
  'tasks',
  'business_profiles',
  'booking_requests',
  'notifications',
  'notification_preferences',
  'push_tokens',
  'calendar_sync_accounts',
  'account_deletion_requests',
  'task_checklist_items',
  'expenses',
  'account_deletion_audit',
  'notes',
  'workspace_payment_accounts',
  'payment_transactions',
  'payment_refunds'
]) as expected(table_name);

select is(
  (
    select count(*)::bigint
    from pg_class relation
    join pg_namespace namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname = any(array[
        'workspaces',
        'workspace_members',
        'workspace_settings',
        'contacts',
        'services',
        'appointments',
        'invoices',
        'invoice_line_items',
        'tasks',
        'business_profiles',
        'booking_requests',
        'notifications',
        'notification_preferences',
        'push_tokens',
        'calendar_sync_accounts',
        'account_deletion_requests',
        'task_checklist_items',
        'expenses',
        'account_deletion_audit',
        'notes',
        'workspace_payment_accounts',
        'payment_transactions',
        'payment_refunds'
      ])
      and not relation.relrowsecurity
  ),
  0::bigint,
  'every public Workloop data table has RLS enabled'
);

select is(
  (
    select count(*)::bigint
    from information_schema.table_privileges
    where table_schema = 'public'
      and lower(grantee) in ('anon', 'public')
      and table_name = any(array[
        'workspaces',
        'workspace_members',
        'workspace_settings',
        'contacts',
        'services',
        'appointments',
        'invoices',
        'invoice_line_items',
        'tasks',
        'business_profiles',
        'booking_requests',
        'notifications',
        'notification_preferences',
        'push_tokens',
        'calendar_sync_accounts',
        'account_deletion_requests',
        'task_checklist_items',
        'expenses',
        'account_deletion_audit',
        'notes',
        'workspace_payment_accounts',
        'payment_transactions',
        'payment_refunds'
      ])
  ),
  0::bigint,
  'anonymous clients have no direct table privileges'
);

select is(
  (
    select count(*)::bigint
    from information_schema.table_privileges
    where table_schema = 'app_private'
      and lower(grantee) in ('anon', 'authenticated', 'public')
  ),
  0::bigint,
  'client roles have no private-table privileges'
);

select is(
  (
    select count(*)::bigint
    from pg_class relation
    join pg_namespace namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname = any(array[
        'workspaces',
        'workspace_members',
        'contacts',
        'services',
        'appointments',
        'invoices',
        'invoice_line_items',
        'tasks',
        'business_profiles',
        'booking_requests',
        'notifications',
        'task_checklist_items',
        'expenses',
        'notes',
        'workspace_payment_accounts',
        'payment_transactions',
        'payment_refunds'
      ])
      and not exists (
        select 1
        from pg_constraint constraint_row
        where constraint_row.conrelid = relation.oid
          and constraint_row.contype = 'p'
      )
  ),
  0::bigint,
  'every row-identity table has a primary key'
);

select ok(
  to_regprocedure('public.create_booking_workflow(jsonb)') is not null,
  'authenticated booking workflow wrapper exists'
);
select ok(
  to_regprocedure('public.complete_booking_workflow(jsonb)') is not null,
  'authenticated completion workflow wrapper exists'
);
select ok(
  to_regprocedure('public.create_task_workflow(jsonb)') is not null,
  'authenticated task workflow wrapper exists'
);
select ok(
  to_regprocedure('app_private.create_booking_workflow(jsonb)') is not null,
  'private booking implementation exists'
);
select ok(
  to_regprocedure('app_private.complete_booking_workflow(jsonb)') is not null,
  'private completion implementation exists'
);
select ok(
  to_regprocedure(
    'public.claim_stripe_webhook_event(text,text,text,boolean,jsonb)'
  ) is not null,
  'service-only Stripe webhook claim function exists'
);
select ok(
  to_regprocedure(
    'public.finish_stripe_webhook_event(text,text,text)'
  ) is not null,
  'service-only Stripe webhook completion function exists'
);

select is(
  (
    select count(*)::bigint
    from information_schema.table_privileges
    where table_schema = 'app_private'
      and lower(grantee) in ('anon', 'authenticated', 'public')
      and privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
  ),
  0::bigint,
  'private workflow state is outside the Data API roles'
);

select is(
  (
    select count(*)::bigint
    from pg_constraint constraint_row
    join pg_class relation on relation.oid = constraint_row.conrelid
    join pg_namespace namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relname in (
        'appointments',
        'invoices',
        'tasks',
        'notes',
        'booking_requests',
        'invoice_line_items',
        'task_checklist_items'
      )
      and constraint_row.contype = 'f'
      and constraint_row.conname like '%workspace_%_fk'
  ),
  12::bigint,
  'tenant-aware relationship foreign keys are present'
);

select * from finish();
rollback;
