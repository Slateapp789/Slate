create or replace function public.is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.workspace_members
      where workspace_id = target_workspace_id
        and user_id = (select auth.uid())
    );
$$;

revoke execute on function public.is_workspace_member(uuid) from public;
revoke execute on function public.is_workspace_member(uuid) from anon;
grant execute on function public.is_workspace_member(uuid) to authenticated;

create or replace function public.workspace_has_no_members(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (select auth.uid()) is not null
    and not exists (
      select 1
      from public.workspace_members
      where workspace_id = target_workspace_id
    );
$$;

revoke execute on function public.workspace_has_no_members(uuid) from public;
revoke execute on function public.workspace_has_no_members(uuid) from anon;
grant execute on function public.workspace_has_no_members(uuid) to authenticated;

drop policy if exists "Users can create their first workspace membership" on public.workspace_members;
create policy "Users can create their first workspace membership"
on public.workspace_members
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and (
    public.is_workspace_member(workspace_id)
    or public.workspace_has_no_members(workspace_id)
  )
);
