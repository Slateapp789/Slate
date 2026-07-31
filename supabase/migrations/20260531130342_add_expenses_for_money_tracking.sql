create table if not exists expenses (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  amount numeric not null check (amount >= 0),
  category text not null default 'Other',
  expense_date date not null default current_date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists expenses_workspace_date_idx
  on expenses(workspace_id, expense_date desc);

alter table expenses enable row level security;

drop policy if exists "Members can manage expenses" on expenses;
create policy "Members can manage expenses"
on expenses for all
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));
