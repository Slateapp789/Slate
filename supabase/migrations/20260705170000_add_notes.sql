create table if not exists notes (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  contact_id uuid references contacts(id) on delete set null,
  appointment_id uuid references appointments(id) on delete set null,
  title text not null default 'Untitled note',
  body text not null default '',
  pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists notes_workspace_updated_idx
  on notes(workspace_id, pinned desc, updated_at desc);
create index if not exists notes_contact_id_idx
  on notes(contact_id);
create index if not exists notes_appointment_id_idx
  on notes(appointment_id);

alter table notes enable row level security;

drop policy if exists "Members can manage notes" on notes;
create policy "Members can manage notes"
on notes for all
to authenticated
using (app_private.is_workspace_member(workspace_id))
with check (app_private.is_workspace_member(workspace_id));
