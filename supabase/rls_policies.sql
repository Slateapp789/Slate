-- Slate V1 RLS policy contract.
-- Review before applying to production; policies assume auth.uid() maps to workspace_members.user_id.

create or replace function public.is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from workspace_members
    where workspace_id = target_workspace_id
      and user_id = auth.uid()
  );
$$;

revoke execute on function public.is_workspace_member(uuid) from public;
revoke execute on function public.is_workspace_member(uuid) from anon;
revoke execute on function public.is_workspace_member(uuid) from authenticated;

alter table if exists workspaces enable row level security;
alter table if exists workspace_members enable row level security;
alter table if exists workspace_settings enable row level security;
alter table if exists contacts enable row level security;
alter table if exists services enable row level security;
alter table if exists appointments enable row level security;
alter table if exists invoices enable row level security;
alter table if exists invoice_line_items enable row level security;
alter table if exists tasks enable row level security;
alter table if exists business_profiles enable row level security;
alter table if exists booking_requests enable row level security;
alter table if exists notifications enable row level security;
alter table if exists notification_preferences enable row level security;
alter table if exists push_tokens enable row level security;
alter table if exists calendar_sync_accounts enable row level security;
alter table if exists account_deletion_requests enable row level security;

drop policy if exists "Members can read workspaces" on workspaces;
create policy "Members can read workspaces"
on workspaces for select
using (public.is_workspace_member(id));

drop policy if exists "Members can update workspaces" on workspaces;
create policy "Members can update workspaces"
on workspaces for update
using (public.is_workspace_member(id))
with check (public.is_workspace_member(id));

drop policy if exists "Authenticated users can create workspaces" on workspaces;
create policy "Authenticated users can create workspaces"
on workspaces for insert
to authenticated
with check (auth.uid() is not null);

drop policy if exists "Members can read workspace members" on workspace_members;
create policy "Members can read workspace members"
on workspace_members for select
using (public.is_workspace_member(workspace_id));

drop policy if exists "Users can create their first workspace membership" on workspace_members;
create policy "Users can create their first workspace membership"
on workspace_members for insert
to authenticated
with check (
  user_id = auth.uid()
  and (
    public.is_workspace_member(workspace_id)
    or not exists (
      select 1
      from workspace_members existing_members
      where existing_members.workspace_id = workspace_members.workspace_id
    )
  )
);

drop policy if exists "Members can manage workspace settings" on workspace_settings;
create policy "Members can manage workspace settings"
on workspace_settings for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage contacts" on contacts;
create policy "Members can manage contacts"
on contacts for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage services" on services;
create policy "Members can manage services"
on services for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Public can read visible services" on services;
create policy "Public can read visible services"
on services for select
using (
  show_on_profile = true
  and exists (
    select 1
    from business_profiles
    where business_profiles.workspace_id = services.workspace_id
      and business_profiles.handle is not null
  )
);

drop policy if exists "Members can manage appointments" on appointments;
create policy "Members can manage appointments"
on appointments for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage invoices" on invoices;
create policy "Members can manage invoices"
on invoices for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage invoice line items" on invoice_line_items;
create policy "Members can manage invoice line items"
on invoice_line_items for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage tasks" on tasks;
create policy "Members can manage tasks"
on tasks for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage business profiles" on business_profiles;
create policy "Members can manage business profiles"
on business_profiles for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Public can read business profiles" on business_profiles;
create policy "Public can read business profiles"
on business_profiles for select
using (handle is not null and handle <> '');

drop policy if exists "Members can manage booking requests" on booking_requests;
create policy "Members can manage booking requests"
on booking_requests for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Public can create booking requests" on booking_requests;
create policy "Public can create booking requests"
on booking_requests for insert
with check (
  exists (
    select 1
    from business_profiles
    where business_profiles.workspace_id = booking_requests.workspace_id
      and business_profiles.booking_mode = 'manual'
  )
);

drop policy if exists "Members can manage notifications" on notifications;
create policy "Members can manage notifications"
on notifications for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage notification preferences" on notification_preferences;
create policy "Members can manage notification preferences"
on notification_preferences for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage push tokens" on push_tokens;
create policy "Members can manage push tokens"
on push_tokens for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage calendar sync accounts" on calendar_sync_accounts;
create policy "Members can manage calendar sync accounts"
on calendar_sync_accounts for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can create deletion requests" on account_deletion_requests;
create policy "Members can create deletion requests"
on account_deletion_requests for insert
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can read deletion requests" on account_deletion_requests;
create policy "Members can read deletion requests"
on account_deletion_requests for select
using (public.is_workspace_member(workspace_id));
