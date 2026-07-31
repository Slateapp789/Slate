-- Cover every composite tenant foreign key on the child side. PostgreSQL does
-- not create these indexes automatically; they support tenant-scoped joins and
-- keep parent updates/deletes from scanning entire child tables.

create index if not exists appointments_workspace_contact_idx
  on public.appointments (workspace_id, contact_id);
create index if not exists appointments_workspace_service_idx
  on public.appointments (workspace_id, service_id);

create index if not exists booking_requests_workspace_service_idx
  on public.booking_requests (workspace_id, service_id);

create index if not exists invoice_line_items_workspace_invoice_idx
  on public.invoice_line_items (workspace_id, invoice_id);

create index if not exists invoices_workspace_contact_idx
  on public.invoices (workspace_id, contact_id);
create index if not exists invoices_workspace_appointment_idx
  on public.invoices (workspace_id, appointment_id);

create index if not exists notes_workspace_contact_idx
  on public.notes (workspace_id, contact_id);
create index if not exists notes_workspace_appointment_idx
  on public.notes (workspace_id, appointment_id);
create index if not exists notes_workspace_task_idx
  on public.notes (workspace_id, task_id);

create index if not exists task_checklist_workspace_task_idx
  on public.task_checklist_items (workspace_id, task_id);

create index if not exists tasks_workspace_contact_idx
  on public.tasks (workspace_id, contact_id);
create index if not exists tasks_workspace_appointment_idx
  on public.tasks (workspace_id, appointment_id);
