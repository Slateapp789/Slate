create schema if not exists app_private;

revoke all on schema app_private from public;
grant usage on schema app_private to authenticated, service_role;

create or replace function app_private.is_workspace_member(
  target_workspace_id uuid
)
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

revoke execute on function app_private.is_workspace_member(uuid) from public;
revoke execute on function app_private.is_workspace_member(uuid) from anon;
grant execute on function app_private.is_workspace_member(uuid) to authenticated;
grant execute on function app_private.is_workspace_member(uuid) to service_role;

create or replace function app_private.workspace_has_no_members(
  target_workspace_id uuid
)
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

revoke execute on function app_private.workspace_has_no_members(uuid) from public;
revoke execute on function app_private.workspace_has_no_members(uuid) from anon;
grant execute on function app_private.workspace_has_no_members(uuid) to authenticated;
grant execute on function app_private.workspace_has_no_members(uuid) to service_role;

drop policy if exists "Members can read workspaces" on public.workspaces;
create policy "Members can read workspaces"
on public.workspaces for select
to authenticated
using (app_private.is_workspace_member(id));

drop policy if exists "Members can update workspaces" on public.workspaces;
create policy "Members can update workspaces"
on public.workspaces for update
to authenticated
using (app_private.is_workspace_member(id))
with check (app_private.is_workspace_member(id));

drop policy if exists "Users can create their first workspace membership" on public.workspace_members;
create policy "Users can create their first workspace membership"
on public.workspace_members for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and (
    app_private.is_workspace_member(workspace_id)
    or app_private.workspace_has_no_members(workspace_id)
  )
);

drop policy if exists "Members can manage workspace settings" on public.workspace_settings;
create policy "Members can manage workspace settings"
on public.workspace_settings for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage contacts" on public.contacts;
create policy "Members can manage contacts"
on public.contacts for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage services" on public.services;
create policy "Members can manage services"
on public.services for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage appointments" on public.appointments;
create policy "Members can manage appointments"
on public.appointments for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage invoices" on public.invoices;
create policy "Members can manage invoices"
on public.invoices for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage notes" on public.notes;
create policy "Members can manage notes"
on public.notes for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage invoice line items" on public.invoice_line_items;
create policy "Members can manage invoice line items"
on public.invoice_line_items for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage expenses" on public.expenses;
create policy "Members can manage expenses"
on public.expenses for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage tasks" on public.tasks;
create policy "Members can manage tasks"
on public.tasks for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage task checklist items" on public.task_checklist_items;
create policy "Members can manage task checklist items"
on public.task_checklist_items for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage business profiles" on public.business_profiles;
create policy "Members can manage business profiles"
on public.business_profiles for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage booking requests" on public.booking_requests;
create policy "Members can manage booking requests"
on public.booking_requests for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage notifications" on public.notifications;
create policy "Members can manage notifications"
on public.notifications for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage notification preferences" on public.notification_preferences;
create policy "Members can manage notification preferences"
on public.notification_preferences for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage push tokens" on public.push_tokens;
create policy "Members can manage push tokens"
on public.push_tokens for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can manage calendar sync accounts" on public.calendar_sync_accounts;
create policy "Members can manage calendar sync accounts"
on public.calendar_sync_accounts for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can create deletion requests" on public.account_deletion_requests;
create policy "Members can create deletion requests"
on public.account_deletion_requests for insert
to authenticated
with check (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can read deletion requests" on public.account_deletion_requests;
create policy "Members can read deletion requests"
on public.account_deletion_requests for select
to authenticated
using (app_private.is_workspace_member(workspace_id));

drop function if exists public.is_workspace_member(uuid);
drop function if exists public.workspace_has_no_members(uuid);

create table if not exists app_private.payment_counters (
  workspace_id uuid primary key references public.workspaces(id) on delete cascade,
  next_number bigint not null default 1 check (next_number > 0)
);

revoke all on app_private.payment_counters from public;
grant select, insert, update on app_private.payment_counters to service_role;

with duplicate_rows as (
  select
    id,
    workspace_id,
    row_number() over (
      partition by workspace_id, invoice_number
      order by created_at, id
    ) as duplicate_index
  from public.invoices
  where invoice_number is not null
),
rows_to_fix as (
  select
    id,
    workspace_id,
    row_number() over (
      partition by workspace_id
      order by id
    ) as fix_index
  from duplicate_rows
  where duplicate_index > 1
),
max_numbers as (
  select
    workspace_id,
    coalesce(
      max((regexp_match(invoice_number, '^PAY-([0-9]+)$'))[1]::bigint),
      0
    ) as max_number
  from public.invoices
  where invoice_number ~ '^PAY-[0-9]+$'
  group by workspace_id
)
update public.invoices invoice
set invoice_number = 'PAY-' || lpad(
  (coalesce(max_numbers.max_number, 0) + rows_to_fix.fix_index)::text,
  3,
  '0'
)
from rows_to_fix
left join max_numbers
  on max_numbers.workspace_id = rows_to_fix.workspace_id
where invoice.id = rows_to_fix.id;

create unique index if not exists invoices_workspace_invoice_number_unique_idx
  on public.invoices(workspace_id, invoice_number)
  where invoice_number is not null;

insert into app_private.payment_counters(workspace_id, next_number)
select
  workspace_id,
  coalesce(
    max((regexp_match(invoice_number, '^PAY-([0-9]+)$'))[1]::bigint),
    0
  ) + 1
from public.invoices
where invoice_number ~ '^PAY-[0-9]+$'
group by workspace_id
on conflict (workspace_id) do update
set next_number = greatest(
  app_private.payment_counters.next_number,
  excluded.next_number
);

create or replace function app_private.next_payment_number(
  target_workspace_id uuid
)
returns text
language plpgsql
security definer
set search_path = public, app_private
as $$
declare
  allocated_number bigint;
  jwt_role text := coalesce((select auth.jwt() ->> 'role'), '');
begin
  if not (
    app_private.is_workspace_member(target_workspace_id)
    or jwt_role = 'service_role'
  ) then
    raise exception 'workspace access denied'
      using errcode = '42501';
  end if;

  insert into app_private.payment_counters(workspace_id, next_number)
  values (
    target_workspace_id,
    (
      select coalesce(
        max((regexp_match(invoice_number, '^PAY-([0-9]+)$'))[1]::bigint),
        0
      ) + 2
      from public.invoices
      where workspace_id = target_workspace_id
        and invoice_number ~ '^PAY-[0-9]+$'
    )
  )
  on conflict (workspace_id) do update
  set next_number = app_private.payment_counters.next_number + 1
  returning next_number - 1 into allocated_number;

  return 'PAY-' || lpad(allocated_number::text, 3, '0');
end;
$$;

revoke execute on function app_private.next_payment_number(uuid) from public;
revoke execute on function app_private.next_payment_number(uuid) from anon;
grant execute on function app_private.next_payment_number(uuid) to authenticated;
grant execute on function app_private.next_payment_number(uuid) to service_role;

create or replace function app_private.assign_invoice_number()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if new.invoice_number is null or btrim(new.invoice_number) = '' then
    new.invoice_number := app_private.next_payment_number(new.workspace_id);
  end if;
  return new;
end;
$$;

revoke execute on function app_private.assign_invoice_number() from public;
revoke execute on function app_private.assign_invoice_number() from anon;
grant execute on function app_private.assign_invoice_number() to authenticated;
grant execute on function app_private.assign_invoice_number() to service_role;

drop trigger if exists assign_invoice_number_before_insert on public.invoices;
create trigger assign_invoice_number_before_insert
before insert on public.invoices
for each row
execute function app_private.assign_invoice_number();
