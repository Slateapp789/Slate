alter table public.account_deletion_requests
  add column if not exists requested_by_user_id uuid,
  add column if not exists processing_started_at timestamptz,
  add column if not exists completed_by text,
  add column if not exists completion_mode text;

update public.account_deletion_requests
set requested_by_user_id = coalesce(requested_by_user_id, user_id)
where requested_by_user_id is null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'account_deletion_requests_status_check'
      and conrelid = 'public.account_deletion_requests'::regclass
  ) then
    alter table public.account_deletion_requests
      add constraint account_deletion_requests_status_check
      check (status in ('requested', 'processing', 'completed', 'rejected', 'canceled'))
      not valid;
  end if;
end $$;

create unique index if not exists account_deletion_requests_open_user_idx
  on public.account_deletion_requests(workspace_id, requested_by_user_id)
  where status in ('requested', 'processing')
    and requested_by_user_id is not null;

create table if not exists public.account_deletion_audit (
  id uuid primary key default gen_random_uuid(),
  request_id uuid,
  workspace_id uuid,
  user_id uuid,
  email_hash text,
  requested_at timestamptz,
  completed_at timestamptz not null default now(),
  completed_by text not null,
  completion_mode text not null,
  workspace_deleted boolean not null default false,
  auth_user_deleted boolean not null default false,
  notes text
);

alter table public.account_deletion_audit enable row level security;
