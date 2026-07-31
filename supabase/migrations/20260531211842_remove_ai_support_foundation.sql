drop table if exists public.support_messages cascade;
drop table if exists public.support_chats cascade;

alter table if exists public.workspace_settings
  drop column if exists ai_context,
  drop column if exists ai_context_updated_at;
