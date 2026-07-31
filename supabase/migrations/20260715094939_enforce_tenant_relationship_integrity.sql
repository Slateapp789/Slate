-- Enforce the Workloop tenant invariant at the database boundary:
-- every linked row must belong to the same workspace as its parent.
-- Existing single-column foreign keys remain in place to preserve their
-- historical delete actions; these composite keys add workspace ownership.

create unique index if not exists contacts_workspace_id_id_uidx
  on public.contacts (workspace_id, id);
create unique index if not exists services_workspace_id_id_uidx
  on public.services (workspace_id, id);
create unique index if not exists appointments_workspace_id_id_uidx
  on public.appointments (workspace_id, id);
create unique index if not exists tasks_workspace_id_id_uidx
  on public.tasks (workspace_id, id);
create unique index if not exists invoices_workspace_id_id_uidx
  on public.invoices (workspace_id, id);

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'appointments_workspace_contact_fk'
       and conrelid = 'public.appointments'::regclass
  ) then
    alter table public.appointments
      add constraint appointments_workspace_contact_fk
      foreign key (workspace_id, contact_id)
      references public.contacts (workspace_id, id)
      on delete set null (contact_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'appointments_workspace_service_fk'
       and conrelid = 'public.appointments'::regclass
  ) then
    alter table public.appointments
      add constraint appointments_workspace_service_fk
      foreign key (workspace_id, service_id)
      references public.services (workspace_id, id)
      on delete set null (service_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'invoices_workspace_contact_fk'
       and conrelid = 'public.invoices'::regclass
  ) then
    alter table public.invoices
      add constraint invoices_workspace_contact_fk
      foreign key (workspace_id, contact_id)
      references public.contacts (workspace_id, id)
      on delete set null (contact_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'invoices_workspace_appointment_fk'
       and conrelid = 'public.invoices'::regclass
  ) then
    alter table public.invoices
      add constraint invoices_workspace_appointment_fk
      foreign key (workspace_id, appointment_id)
      references public.appointments (workspace_id, id)
      on delete set null (appointment_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'tasks_workspace_contact_fk'
       and conrelid = 'public.tasks'::regclass
  ) then
    alter table public.tasks
      add constraint tasks_workspace_contact_fk
      foreign key (workspace_id, contact_id)
      references public.contacts (workspace_id, id)
      on delete set null (contact_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'tasks_workspace_appointment_fk'
       and conrelid = 'public.tasks'::regclass
  ) then
    alter table public.tasks
      add constraint tasks_workspace_appointment_fk
      foreign key (workspace_id, appointment_id)
      references public.appointments (workspace_id, id)
      on delete set null (appointment_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'notes_workspace_contact_fk'
       and conrelid = 'public.notes'::regclass
  ) then
    alter table public.notes
      add constraint notes_workspace_contact_fk
      foreign key (workspace_id, contact_id)
      references public.contacts (workspace_id, id)
      on delete set null (contact_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'notes_workspace_appointment_fk'
       and conrelid = 'public.notes'::regclass
  ) then
    alter table public.notes
      add constraint notes_workspace_appointment_fk
      foreign key (workspace_id, appointment_id)
      references public.appointments (workspace_id, id)
      on delete set null (appointment_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'notes_workspace_task_fk'
       and conrelid = 'public.notes'::regclass
  ) then
    alter table public.notes
      add constraint notes_workspace_task_fk
      foreign key (workspace_id, task_id)
      references public.tasks (workspace_id, id)
      on delete set null (task_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'checklist_workspace_task_fk'
       and conrelid = 'public.task_checklist_items'::regclass
  ) then
    alter table public.task_checklist_items
      add constraint checklist_workspace_task_fk
      foreign key (workspace_id, task_id)
      references public.tasks (workspace_id, id)
      on delete cascade
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'booking_requests_workspace_service_fk'
       and conrelid = 'public.booking_requests'::regclass
  ) then
    alter table public.booking_requests
      add constraint booking_requests_workspace_service_fk
      foreign key (workspace_id, service_id)
      references public.services (workspace_id, id)
      on delete set null (service_id)
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'invoice_line_items_workspace_invoice_fk'
       and conrelid = 'public.invoice_line_items'::regclass
  ) then
    alter table public.invoice_line_items
      add constraint invoice_line_items_workspace_invoice_fk
      foreign key (workspace_id, invoice_id)
      references public.invoices (workspace_id, id)
      on delete cascade
      not valid;
  end if;
end $$;

alter table public.appointments
  validate constraint appointments_workspace_contact_fk;
alter table public.appointments
  validate constraint appointments_workspace_service_fk;
alter table public.invoices
  validate constraint invoices_workspace_contact_fk;
alter table public.invoices
  validate constraint invoices_workspace_appointment_fk;
alter table public.tasks
  validate constraint tasks_workspace_contact_fk;
alter table public.tasks
  validate constraint tasks_workspace_appointment_fk;
alter table public.notes
  validate constraint notes_workspace_contact_fk;
alter table public.notes
  validate constraint notes_workspace_appointment_fk;
alter table public.notes
  validate constraint notes_workspace_task_fk;
alter table public.task_checklist_items
  validate constraint checklist_workspace_task_fk;
alter table public.booking_requests
  validate constraint booking_requests_workspace_service_fk;
alter table public.invoice_line_items
  validate constraint invoice_line_items_workspace_invoice_fk;

-- Deletion requests must be created by the authenticated Edge Function after
-- it verifies the caller and workspace membership, never by direct table writes.
drop policy if exists "Members can create deletion requests"
  on public.account_deletion_requests;
revoke insert on table public.account_deletion_requests from authenticated;
