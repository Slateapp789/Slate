alter table if exists public.tasks
  add column if not exists reminder_timing text not null default 'none',
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.task_checklist_items (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  task_id uuid not null references public.tasks(id) on delete cascade,
  title text not null,
  completed boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists task_checklist_items_workspace_id_idx
  on public.task_checklist_items(workspace_id);
create index if not exists task_checklist_items_task_id_position_idx
  on public.task_checklist_items(task_id, position);

alter table if exists public.task_checklist_items enable row level security;

drop policy if exists "Members can manage task checklist items" on public.task_checklist_items;
create policy "Members can manage task checklist items"
on public.task_checklist_items for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));
