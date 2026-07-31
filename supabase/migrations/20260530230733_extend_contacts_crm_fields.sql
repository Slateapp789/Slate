alter table if exists public.contacts
  add column if not exists preferred_contact_method text not null default 'phone',
  add column if not exists source text,
  add column if not exists birthday date,
  add column if not exists important_notes text;

create index if not exists contacts_workspace_status_idx
  on public.contacts(workspace_id, status);
create index if not exists contacts_workspace_last_activity_idx
  on public.contacts(workspace_id, last_activity_at desc);
