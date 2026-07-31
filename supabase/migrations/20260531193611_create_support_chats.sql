create table if not exists public.support_chats (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  mode text not null check (mode in ('marketing', 'money', 'clients', 'wellbeing')),
  title text not null default 'Support chat',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists support_chats_workspace_mode_updated_idx
  on public.support_chats(workspace_id, mode, updated_at desc);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  chat_id uuid not null references public.support_chats(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  text text not null,
  suggested_reply text,
  actions jsonb not null default '[]'::jsonb,
  watch_out text,
  created_at timestamptz not null default now()
);

create index if not exists support_messages_chat_created_idx
  on public.support_messages(chat_id, created_at);
create index if not exists support_messages_workspace_id_idx
  on public.support_messages(workspace_id);

alter table public.support_chats enable row level security;
alter table public.support_messages enable row level security;

drop policy if exists "Members can manage support chats" on public.support_chats;
create policy "Members can manage support chats"
on public.support_chats for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (public.is_workspace_member(workspace_id));

drop policy if exists "Members can manage support messages" on public.support_messages;
create policy "Members can manage support messages"
on public.support_messages for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (
  public.is_workspace_member(workspace_id)
  and exists (
    select 1
    from public.support_chats
    where support_chats.id = support_messages.chat_id
      and support_chats.workspace_id = support_messages.workspace_id
  )
);
