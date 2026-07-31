-- The composite workspace-aware foreign keys preserve the same delete actions
-- while enforcing tenant ownership. Removing their weaker single-column
-- duplicates also leaves one unambiguous relationship for PostgREST embeds.
alter table public.appointments
  drop constraint if exists appointments_contact_id_fkey,
  drop constraint if exists appointments_service_id_fkey;

alter table public.invoices
  drop constraint if exists invoices_contact_id_fkey,
  drop constraint if exists invoices_appointment_id_fkey;

alter table public.tasks
  drop constraint if exists tasks_contact_id_fkey,
  drop constraint if exists tasks_appointment_id_fkey;

alter table public.notes
  drop constraint if exists notes_contact_id_fkey,
  drop constraint if exists notes_appointment_id_fkey,
  drop constraint if exists notes_task_id_fkey;

alter table public.task_checklist_items
  drop constraint if exists task_checklist_items_task_id_fkey;

alter table public.booking_requests
  drop constraint if exists booking_requests_service_id_fkey;

alter table public.invoice_line_items
  drop constraint if exists invoice_line_items_invoice_id_fkey;
