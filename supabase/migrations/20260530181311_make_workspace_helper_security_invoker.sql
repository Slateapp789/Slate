create or replace function public.is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists (
    select 1
    from workspace_members
    where workspace_id = target_workspace_id
      and user_id = auth.uid()
  );
$$;

grant execute on function public.is_workspace_member(uuid) to authenticated;

drop policy if exists "Members can read workspace members" on workspace_members;
create policy "Users can read their own workspace membership"
on workspace_members for select
to authenticated
using (user_id = auth.uid());
