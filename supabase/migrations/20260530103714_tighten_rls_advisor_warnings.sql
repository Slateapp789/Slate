revoke execute on function public.is_workspace_member(uuid) from anon;
revoke execute on function public.is_workspace_member(uuid) from authenticated;

drop policy if exists "Authenticated users can create workspaces" on workspaces;
create policy "Authenticated users can create workspaces"
on workspaces for insert
to authenticated
with check (auth.uid() is not null);
