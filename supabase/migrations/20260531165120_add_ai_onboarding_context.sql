alter table public.workspace_settings
  add column if not exists ai_context jsonb not null default '{}'::jsonb,
  add column if not exists ai_context_updated_at timestamptz;

comment on column public.workspace_settings.ai_context is 'User-provided business context for Slate AI guidance. Stores stage, current challenges, support style, and focus notes.';
comment on column public.workspace_settings.ai_context_updated_at is 'Timestamp for the latest AI context update.';
