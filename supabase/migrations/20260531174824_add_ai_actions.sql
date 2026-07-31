create table if not exists public.ai_actions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  title text not null,
  detail text,
  source text not null default 'local',
  status text not null default 'pinned' check (status in ('suggested', 'pinned', 'done', 'skipped')),
  route text,
  action_payload jsonb not null default '{}'::jsonb,
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ai_actions_workspace_status_idx
  on public.ai_actions(workspace_id, status, created_at desc);

alter table public.ai_actions enable row level security;

drop policy if exists "Members can manage ai actions" on public.ai_actions;
create policy "Members can manage ai actions"
on public.ai_actions for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

comment on table public.ai_actions is 'Pinned or dismissed Slate Support actions created from local signals or AI guidance.';
