-- Remove legacy duplicate policies that predate the Slate V1 policy contract.
drop policy if exists appointments_policy on public.appointments;
drop policy if exists business_profiles_policy on public.business_profiles;
drop policy if exists contacts_policy on public.contacts;
drop policy if exists invoice_line_items_policy on public.invoice_line_items;
drop policy if exists invoices_policy on public.invoices;
drop policy if exists notifications_policy on public.notifications;
drop policy if exists services_policy on public.services;
drop policy if exists tasks_policy on public.tasks;
drop policy if exists workspace_members_policy on public.workspace_members;
drop policy if exists workspace_settings_policy on public.workspace_settings;

-- Keep auth lookups as initplans inside the shared RLS helper.
create or replace function public.is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_members
    where workspace_id = target_workspace_id
      and user_id = (select auth.uid())
  );
$$;

revoke execute on function public.is_workspace_member(uuid) from public;
revoke execute on function public.is_workspace_member(uuid) from anon;
grant execute on function public.is_workspace_member(uuid) to authenticated;

-- Missing FK indexes reported by Supabase advisors.
create index if not exists account_deletion_requests_workspace_id_idx
  on public.account_deletion_requests(workspace_id);
create index if not exists booking_requests_workspace_id_idx
  on public.booking_requests(workspace_id);
create index if not exists booking_requests_service_id_idx
  on public.booking_requests(service_id);
create index if not exists calendar_sync_accounts_workspace_id_idx
  on public.calendar_sync_accounts(workspace_id);
create index if not exists invoice_line_items_invoice_id_idx
  on public.invoice_line_items(invoice_id);
create index if not exists invoice_line_items_workspace_id_idx
  on public.invoice_line_items(workspace_id);
create index if not exists notifications_workspace_id_idx
  on public.notifications(workspace_id);
create index if not exists push_tokens_workspace_id_idx
  on public.push_tokens(workspace_id);
create index if not exists workspace_members_user_id_idx
  on public.workspace_members(user_id);

-- Direct auth.uid() policies optimized per Supabase advisor guidance.
drop policy if exists "Authenticated users can create workspaces" on public.workspaces;
create policy "Authenticated users can create workspaces"
on public.workspaces for insert
to authenticated
with check ((select auth.uid()) is not null);

drop policy if exists "Users can read their own workspace membership" on public.workspace_members;
create policy "Users can read their own workspace membership"
on public.workspace_members for select
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users can create their first workspace membership" on public.workspace_members;
create policy "Users can create their first workspace membership"
on public.workspace_members for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and (
    public.is_workspace_member(workspace_id)
    or not exists (
      select 1
      from public.workspace_members existing_members
      where existing_members.workspace_id = workspace_members.workspace_id
    )
  )
);
