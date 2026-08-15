begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(19);

select has_table(
  'app_private',
  'launch_waitlist',
  'launch interest is stored in a private table'
);
select has_column(
  'app_private',
  'launch_waitlist',
  'email',
  'waitlist stores the normalized email address'
);
select has_column(
  'app_private',
  'launch_waitlist',
  'consent_at',
  'waitlist stores when launch-contact consent was given'
);
select has_index(
  'app_private',
  'launch_waitlist',
  'launch_waitlist_status_created_idx',
  'operational status queries have a covering index'
);
select ok(
  (
    select relation.relrowsecurity
      from pg_class relation
      join pg_namespace namespace on namespace.oid = relation.relnamespace
     where namespace.nspname = 'app_private'
       and relation.relname = 'launch_waitlist'
  ),
  'private waitlist has RLS enabled as defense in depth'
);
select ok(
  not has_table_privilege('anon', 'app_private.launch_waitlist', 'SELECT'),
  'anonymous clients cannot read launch emails'
);
select ok(
  not has_table_privilege(
    'authenticated',
    'app_private.launch_waitlist',
    'SELECT'
  ),
  'authenticated app users cannot read launch emails'
);
select ok(
  has_table_privilege('service_role', 'app_private.launch_waitlist', 'SELECT')
  and has_table_privilege(
    'service_role',
    'app_private.launch_waitlist',
    'INSERT'
  )
  and has_table_privilege(
    'service_role',
    'app_private.launch_waitlist',
    'UPDATE'
  ),
  'only the trusted service boundary can manage the waitlist'
);
select ok(
  to_regprocedure('public.join_launch_waitlist(text,text,text)') is not null,
  'Edge Function has a bounded waitlist RPC'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.join_launch_waitlist(text,text,text)',
    'EXECUTE'
  ),
  'anonymous clients cannot bypass the Edge Function'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.join_launch_waitlist(text,text,text)',
    'EXECUTE'
  ),
  'authenticated clients cannot bypass the Edge Function'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.join_launch_waitlist(text,text,text)',
    'EXECUTE'
  ),
  'service role can invoke the waitlist RPC'
);

set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select is(
  public.join_launch_waitlist(
    '  Founder@Example.COM ',
    repeat('a', 64),
    'early-access'
  ),
  'created',
  'a valid launch signup is created'
);
reset role;
select is(
  (select email from app_private.launch_waitlist limit 1),
  'founder@example.com',
  'email is normalized before storage'
);
select is(
  (select source from app_private.launch_waitlist limit 1),
  'early-access',
  'bounded campaign source is retained'
);

set local role service_role;
select is(
  public.join_launch_waitlist(
    'founder@example.com',
    repeat('a', 64),
    'home'
  ),
  'duplicate',
  'resubmitting an email is idempotent'
);
reset role;
select is(
  (select count(*) from app_private.launch_waitlist),
  1::bigint,
  'duplicate signup keeps one waitlist row'
);

set local role service_role;
select throws_ok(
  $$select public.join_launch_waitlist('bad', repeat('c', 64), 'website')$$,
  '22023',
  'invalid waitlist request',
  'invalid email is rejected inside the database boundary'
);
reset role;

insert into app_private.edge_rate_limit_events(
  scope,
  resource_key,
  subject_key,
  created_at
)
select 'waitlist_email', 'pricing', repeat('b', 64), clock_timestamp()
  from generate_series(1, 3);

set local role service_role;
select is(
  public.join_launch_waitlist(
    'limited@example.com',
    repeat('b', 64),
    'pricing'
  ),
  'rate_limited',
  'repeated source submissions are rate limited before storing PII'
);
reset role;

select * from finish();
rollback;
