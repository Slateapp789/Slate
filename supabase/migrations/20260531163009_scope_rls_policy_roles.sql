drop policy if exists "Members can read workspaces" on public.workspaces;
create policy "Members can read workspaces"
on public.workspaces for select
to authenticated
using (public.is_workspace_member(id));

drop policy if exists "Members can update workspaces" on public.workspaces;
create policy "Members can update workspaces"
on public.workspaces for update
to authenticated
using (public.is_workspace_member(id))
with check (public.is_workspace_member(id));

drop policy if exists "Members can manage workspace settings" on public.workspace_settings;
create policy "Members can manage workspace settings"
on public.workspace_settings for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage contacts" on public.contacts;
create policy "Members can manage contacts"
on public.contacts for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage services" on public.services;
create policy "Members can manage services"
on public.services for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Public can read visible services" on public.services;
create policy "Public can read visible services"
on public.services for select
to anon
using (
  show_on_profile = true
  and exists (
    select 1
    from public.business_profiles
    where business_profiles.workspace_id = services.workspace_id
      and business_profiles.handle is not null
  )
);

drop policy if exists "Members can manage appointments" on public.appointments;
create policy "Members can manage appointments"
on public.appointments for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage invoices" on public.invoices;
create policy "Members can manage invoices"
on public.invoices for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage invoice line items" on public.invoice_line_items;
create policy "Members can manage invoice line items"
on public.invoice_line_items for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage expenses" on public.expenses;
create policy "Members can manage expenses"
on public.expenses for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage tasks" on public.tasks;
create policy "Members can manage tasks"
on public.tasks for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage task checklist items" on public.task_checklist_items;
create policy "Members can manage task checklist items"
on public.task_checklist_items for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage business profiles" on public.business_profiles;
create policy "Members can manage business profiles"
on public.business_profiles for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Public can read business profiles" on public.business_profiles;
create policy "Public can read business profiles"
on public.business_profiles for select
to anon
using (handle is not null and handle <> '');

drop policy if exists "Members can manage booking requests" on public.booking_requests;
create policy "Members can manage booking requests"
on public.booking_requests for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Public can create booking requests" on public.booking_requests;
create policy "Public can create booking requests"
on public.booking_requests for insert
to anon
with check (
  exists (
    select 1
    from public.business_profiles
    where business_profiles.workspace_id = booking_requests.workspace_id
      and business_profiles.booking_mode = 'manual'
  )
);

drop policy if exists "Members can manage notifications" on public.notifications;
create policy "Members can manage notifications"
on public.notifications for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage notification preferences" on public.notification_preferences;
create policy "Members can manage notification preferences"
on public.notification_preferences for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage push tokens" on public.push_tokens;
create policy "Members can manage push tokens"
on public.push_tokens for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage calendar sync accounts" on public.calendar_sync_accounts;
create policy "Members can manage calendar sync accounts"
on public.calendar_sync_accounts for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can create deletion requests" on public.account_deletion_requests;
create policy "Members can create deletion requests"
on public.account_deletion_requests for insert
to authenticated
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can read deletion requests" on public.account_deletion_requests;
create policy "Members can read deletion requests"
on public.account_deletion_requests for select
to authenticated
using (public.is_workspace_member(workspace_id));
