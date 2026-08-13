-- Users who opt in to MFA must present an AAL2 session before any direct
-- authenticated Data API access is allowed. Accounts without a verified
-- factor keep the existing AAL1 behaviour so rollout does not lock them out.
create or replace function app_private.current_user_meets_mfa_policy()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when (select auth.uid()) is null then false
    when exists (
      select 1
      from auth.mfa_factors as factor
      where factor.user_id = (select auth.uid())
        and factor.status = 'verified'
    ) then coalesce((select auth.jwt() ->> 'aal') = 'aal2', false)
    else true
  end;
$$;

comment on function app_private.current_user_meets_mfa_policy() is
  'Requires an AAL2 JWT only when the current user has opted in with a verified MFA factor.';

revoke all on function app_private.current_user_meets_mfa_policy()
  from public, anon;
grant execute on function app_private.current_user_meets_mfa_policy()
  to authenticated, service_role;

do $$
declare
  target_table record;
begin
  for target_table in
    select distinct grant_row.table_name
    from information_schema.role_table_grants as grant_row
    where grant_row.table_schema = 'public'
      and grant_row.grantee = 'authenticated'
      and grant_row.privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
  loop
    execute format(
      'drop policy if exists %I on public.%I',
      'Verified MFA users require AAL2',
      target_table.table_name
    );
    execute format(
      'create policy %I on public.%I as restrictive for all to authenticated using (app_private.current_user_meets_mfa_policy()) with check (app_private.current_user_meets_mfa_policy())',
      'Verified MFA users require AAL2',
      target_table.table_name
    );
  end loop;
end;
$$;

-- Trigger functions are not client RPCs. Revoking direct execution reduces
-- callable surface without affecting trigger execution.
revoke execute on function app_private.assign_invoice_number()
  from public, anon, authenticated;
revoke execute on function public.clear_inactive_task_notification()
  from public, anon, authenticated;
revoke execute on function public.set_task_completion_timestamp()
  from public, anon, authenticated;

grant execute on function app_private.assign_invoice_number() to service_role;
grant execute on function public.clear_inactive_task_notification() to service_role;
grant execute on function public.set_task_completion_timestamp() to service_role;

-- New functions must receive deliberate client grants in their own migration.
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;
alter default privileges for role postgres in schema app_private
  revoke execute on functions from public, anon, authenticated;
