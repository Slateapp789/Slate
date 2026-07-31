alter table public.support_chats
  add column if not exists chat_type text not null default 'chat',
  add column if not exists pinned boolean not null default false,
  add column if not exists deleted_at timestamptz;

alter table public.support_chats
  drop constraint if exists support_chats_chat_type_check;

alter table public.support_chats
  add constraint support_chats_chat_type_check
  check (chat_type in ('general', 'chat', 'project'));

update public.support_chats
set chat_type = 'chat'
where chat_type is null;

drop index if exists public.support_chats_workspace_mode_updated_idx;
create index if not exists support_chats_workspace_mode_updated_idx
  on public.support_chats(workspace_id, mode, pinned desc, updated_at desc)
  where deleted_at is null;
