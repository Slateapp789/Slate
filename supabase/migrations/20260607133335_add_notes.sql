create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  task_id uuid references public.tasks(id) on delete set null,
  title text not null,
  body text not null default '',
  category text not null default 'general'
    check (category in ('general', 'client', 'booking', 'money', 'idea')),
  tags text[] not null default '{}',
  pinned boolean not null default false,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists notes_workspace_updated_idx
  on public.notes(workspace_id, archived, pinned desc, updated_at desc);
create index if not exists notes_workspace_category_idx
  on public.notes(workspace_id, category, updated_at desc);
create index if not exists notes_contact_id_idx
  on public.notes(contact_id);
create index if not exists notes_appointment_id_idx
  on public.notes(appointment_id);
create index if not exists notes_task_id_idx
  on public.notes(task_id);
create index if not exists notes_tags_idx
  on public.notes using gin(tags);

alter table public.notes enable row level security;

drop policy if exists "Members can manage notes" on public.notes;
create policy "Members can manage notes"
on public.notes for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));
