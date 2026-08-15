-- Workloop V1 schema contract
-- This file documents the database shape the Flutter app expects.
-- Treat it as the source for future Supabase migrations before adding V1 features.

-- Existing core tables used by the current app:
-- workspaces(id, name, industry, created_at)
-- workspace_members(id, workspace_id, user_id, created_at)
-- V1 owner invariant: destructive account deletion requires exactly one
-- workspace_members row and it must belong to the requesting user.
-- workspace_settings(workspace_id, working_hours jsonb, revenue_target numeric)
-- contacts(id, workspace_id, name, phone, email, address, notes, important_notes, status, preferred_contact_method, source, birthday, tags, last_activity_at, created_at)
-- services(id, workspace_id, name, duration_mins, price, description, show_on_profile, active, created_at)
-- appointments(id, workspace_id, contact_id, service_id, title, start_time, end_time, price, status, notes, created_at)
-- invoices(id, workspace_id, contact_id, invoice_number, type, status, issue_date, due_date, subtotal, tax_rate, tax_amount, discount_value, total, amount_paid, notes, created_at)
-- expenses(id, workspace_id, amount, category, expense_date, notes, created_at, updated_at)
-- tasks(id, workspace_id, contact_id, appointment_id, title, priority, due_date, status, reminder_timing, completed_at, created_at, updated_at)
-- notes(id, workspace_id, contact_id, appointment_id, task_id, title, body, category, tags, pinned, archived, created_at, updated_at)
-- business_profiles(id, workspace_id, handle, created_at)

-- V1 extension fields.
create index if not exists workspace_members_user_id_idx
  on workspace_members(user_id);

alter table if exists business_profiles
  add column if not exists bio text,
  add column if not exists cover_photo_url text,
  add column if not exists gallery_image_urls jsonb not null default '[]'::jsonb,
  add column if not exists review_quotes jsonb not null default '[]'::jsonb,
  add column if not exists reviews_enabled boolean not null default false,
  add column if not exists gallery_enabled boolean not null default false,
  add column if not exists pay_now_enabled boolean not null default false,
  add column if not exists booking_mode text not null default 'manual',
  add column if not exists notice_text text,
  add column if not exists notice_start timestamptz,
  add column if not exists notice_end timestamptz;

alter table if exists services
  add column if not exists description text,
  add column if not exists show_on_profile boolean not null default true,
  add column if not exists active boolean not null default true;

alter table if exists contacts
  add column if not exists address text,
  add column if not exists tags text[],
  add column if not exists last_activity_at timestamptz,
  add column if not exists preferred_contact_method text not null default 'phone',
  add column if not exists source text,
  add column if not exists birthday date,
  add column if not exists important_notes text;

create index if not exists contacts_workspace_status_idx
  on contacts(workspace_id, status);
create index if not exists contacts_workspace_last_activity_idx
  on contacts(workspace_id, last_activity_at desc);
create index if not exists services_workspace_id_idx
  on services(workspace_id);

alter table if exists appointments
  add column if not exists location text,
  add column if not exists recurrence_rule text,
  add column if not exists recurrence_parent_id uuid;

create index if not exists appointments_workspace_id_idx
  on appointments(workspace_id);
create index if not exists appointments_contact_id_idx
  on appointments(contact_id);
create index if not exists appointments_service_id_idx
  on appointments(service_id);

alter table if exists workspace_settings
  add column if not exists min_booking_notice_hours integer not null default 2,
  add column if not exists max_booking_window_weeks integer not null default 12,
  add column if not exists calendar_sync_enabled boolean not null default false;

alter table if exists tasks
  add column if not exists reminder_timing text not null default 'none',
  add column if not exists appointment_id uuid references appointments(id) on delete set null,
  add column if not exists completed_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

create index if not exists tasks_workspace_id_idx
  on tasks(workspace_id);
create index if not exists tasks_contact_id_idx
  on tasks(contact_id);
create index if not exists tasks_appointment_id_idx
  on tasks(appointment_id);

create index if not exists invoices_workspace_id_idx
  on invoices(workspace_id);
create index if not exists invoices_contact_id_idx
  on invoices(contact_id);
create index if not exists invoices_appointment_id_idx
  on invoices(appointment_id);
create index if not exists invoice_line_items_invoice_id_idx
  on invoice_line_items(invoice_id);
create index if not exists invoice_line_items_workspace_id_idx
  on invoice_line_items(workspace_id);

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

create table if not exists task_checklist_items (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  task_id uuid not null references tasks(id) on delete cascade,
  title text not null,
  completed boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists task_checklist_items_workspace_id_idx
  on task_checklist_items(workspace_id);
create index if not exists task_checklist_items_task_id_position_idx
  on task_checklist_items(task_id, position);

create table if not exists notes (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  contact_id uuid references contacts(id) on delete set null,
  appointment_id uuid references appointments(id) on delete set null,
  task_id uuid references tasks(id) on delete set null,
  title text not null default 'Untitled note',
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
  on notes(workspace_id, archived, pinned desc, updated_at desc);
create index if not exists notes_workspace_category_idx
  on notes(workspace_id, category, updated_at desc);
create index if not exists notes_contact_id_idx
  on notes(contact_id);
create index if not exists notes_appointment_id_idx
  on notes(appointment_id);
create index if not exists notes_task_id_idx
  on notes(task_id);
create index if not exists notes_tags_idx
  on notes using gin(tags);

create table if not exists booking_requests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  name text not null,
  phone text not null,
  email text,
  phone_normalized text
    generated always as (regexp_replace(phone, '[^0-9]', '', 'g')) stored,
  service_id uuid references services(id) on delete set null,
  preferred_time_text text,
  message text,
  status text not null default 'pending',
  source_hash text,
  request_token uuid,
  created_at timestamptz not null default now()
);

alter table if exists booking_requests
  add column if not exists preferred_time_text text,
  add column if not exists email text,
  add column if not exists phone_normalized text
    generated always as (regexp_replace(phone, '[^0-9]', '', 'g')) stored,
  add column if not exists source_hash text,
  add column if not exists request_token uuid;

-- Email is nullable only for legacy requests. New public submissions use the
-- service-role-only v2 RPC, which requires and normalizes it.

create table if not exists app_private.transactional_email_outbox (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  booking_request_id uuid not null references booking_requests(id) on delete cascade,
  event text not null,
  recipient_email text not null,
  payload jsonb not null,
  status text not null default 'pending',
  attempt_count integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  lease_token uuid,
  lease_expires_at timestamptz,
  delivery_expires_at timestamptz not null default (now() + interval '24 hours'),
  provider_message_id text,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sent_at timestamptz,
  unique(event, booking_request_id)
);
create index if not exists booking_requests_workspace_id_idx
  on booking_requests(workspace_id);
create index if not exists booking_requests_service_id_idx
  on booking_requests(service_id);
create unique index if not exists
  booking_requests_workspace_request_token_idx
  on booking_requests(workspace_id, request_token)
  where request_token is not null;

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  deep_link text,
  dedupe_key text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);
alter table if exists notifications
  add column if not exists dedupe_key text;
create index if not exists notifications_workspace_id_idx
  on notifications(workspace_id);
create unique index if not exists notifications_workspace_dedupe_uidx
  on notifications(workspace_id, dedupe_key);

create table if not exists notification_preferences (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null unique references workspaces(id) on delete cascade,
  all_notifications boolean not null default true,
  payment_received boolean not null default true,
  new_booking boolean not null default true,
  booking_request boolean not null default true,
  no_show boolean not null default true,
  invoice_overdue boolean not null default true,
  lead_followup boolean not null default true,
  appointment_reminder_15 boolean not null default false,
  task_due_morning boolean not null default false,
  morning_digest boolean not null default true,
  weekly_summary boolean not null default true,
  quiet_hours_enabled boolean not null default true,
  quiet_sundays boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists push_tokens (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  user_id uuid not null,
  token text not null,
  platform text not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique(user_id, token)
);
create index if not exists push_tokens_workspace_id_idx
  on push_tokens(workspace_id);

create table if not exists calendar_sync_accounts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  provider text not null,
  provider_account_id text not null,
  sync_enabled boolean not null default true,
  last_synced_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists calendar_sync_accounts_workspace_id_idx
  on calendar_sync_accounts(workspace_id);

create table if not exists account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references workspaces(id) on delete set null,
  user_id uuid,
  email text not null,
  status text not null default 'requested',
  requested_at timestamptz not null default now(),
  requested_by_user_id uuid,
  processing_started_at timestamptz,
  completed_at timestamptz,
  completed_by text,
  completion_mode text,
  notes text
);
create index if not exists account_deletion_requests_workspace_id_idx
  on account_deletion_requests(workspace_id);

-- RLS expectation:
-- Every workspace-owned table must enforce access through workspace_members.
-- Membership helper functions live in app_private, not public, so they are not
-- exposed as REST/RPC endpoints.
-- Public profile reads should go through a trusted Edge Function.
-- Public booking-request writes should go through a trusted Edge Function.
-- Account deletion should be completed by a trusted server/edge-function path with service-role permissions.
-- See supabase/rls_policies.sql for the concrete V1 policy contract.

alter table if exists account_deletion_requests
  add column if not exists requested_by_user_id uuid,
  add column if not exists processing_started_at timestamptz,
  add column if not exists completed_by text,
  add column if not exists completion_mode text;

create unique index if not exists account_deletion_requests_open_user_idx
  on account_deletion_requests(workspace_id, requested_by_user_id)
  where status in ('requested', 'processing')
    and requested_by_user_id is not null;

create table if not exists account_deletion_audit (
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
alter table if exists account_deletion_audit enable row level security;

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

create index if not exists booking_requests_source_hash_created_idx
  on booking_requests(workspace_id, source_hash, created_at desc);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'booking_requests_normalized_phone_check'
      and conrelid = 'public.booking_requests'::regclass
  ) then
    alter table public.booking_requests
      add constraint booking_requests_normalized_phone_check
      check (char_length(phone_normalized) between 7 and 32)
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'booking_requests_status_check'
      and conrelid = 'public.booking_requests'::regclass
  ) then
    alter table public.booking_requests
      add constraint booking_requests_status_check
      check (status in ('pending', 'contacted', 'confirmed', 'declined'))
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'booking_requests_public_text_bounds_check'
      and conrelid = 'public.booking_requests'::regclass
  ) then
    alter table public.booking_requests
      add constraint booking_requests_public_text_bounds_check
      check (
        char_length(btrim(name)) between 1 and 80
        and char_length(btrim(phone)) between 7 and 32
        and (preferred_time_text is null or char_length(preferred_time_text) <= 160)
        and (message is null or char_length(message) <= 1000)
      )
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'business_profiles_handle_format_check'
      and conrelid = 'public.business_profiles'::regclass
  ) then
    alter table public.business_profiles
      add constraint business_profiles_handle_format_check
      check (
        handle is null
        or handle = ''
        or handle ~ '^[a-z0-9][a-z0-9-]{1,78}[a-z0-9]$'
      )
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'business_profiles_booking_mode_check'
      and conrelid = 'public.business_profiles'::regclass
  ) then
    alter table public.business_profiles
      add constraint business_profiles_booking_mode_check
      check (booking_mode in ('manual', 'closed'))
      not valid;
  end if;
end $$;

create unique index if not exists business_profiles_handle_unique_idx
  on public.business_profiles(lower(handle))
  where handle is not null and handle <> '';

create schema if not exists app_private;

create table if not exists app_private.edge_rate_limit_events (
  id bigint generated always as identity primary key,
  scope text not null check (
    scope in (
      'booking_source',
      'booking_phone',
      'places_autocomplete',
      'places_details',
      'waitlist_email'
    )
  ),
  resource_key text not null default '',
  subject_key text not null,
  created_at timestamptz not null default clock_timestamp()
);

create index if not exists edge_rate_limit_subject_window_idx
  on app_private.edge_rate_limit_events(
    scope,
    resource_key,
    subject_key,
    created_at desc
  );
create index if not exists edge_rate_limit_created_at_idx
  on app_private.edge_rate_limit_events(created_at);

alter table app_private.edge_rate_limit_events enable row level security;
revoke all on table app_private.edge_rate_limit_events
  from public, anon, authenticated;
grant select, insert, delete on table app_private.edge_rate_limit_events
  to service_role;
drop policy if exists edge_rate_limit_events_deny_clients
  on app_private.edge_rate_limit_events;
create policy edge_rate_limit_events_deny_clients
  on app_private.edge_rate_limit_events
  for all
  to anon, authenticated
  using (false)
  with check (false);
revoke all on sequence app_private.edge_rate_limit_events_id_seq
  from public, anon, authenticated;
grant usage, select on sequence app_private.edge_rate_limit_events_id_seq
  to service_role;

create table if not exists app_private.launch_waitlist (
  id bigint generated always as identity primary key,
  email text not null unique,
  source text not null default 'website',
  status text not null default 'active'
    check (status in ('active', 'invited', 'unsubscribed')),
  consent_at timestamptz not null default clock_timestamp(),
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  constraint launch_waitlist_email_check check (
    email = lower(btrim(email))
    and char_length(email) between 3 and 254
    and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
  ),
  constraint launch_waitlist_source_check check (
    source ~ '^[a-z0-9_-]{1,40}$'
  )
);

create index if not exists launch_waitlist_status_created_idx
  on app_private.launch_waitlist(status, created_at desc);

alter table app_private.launch_waitlist enable row level security;
revoke all on table app_private.launch_waitlist
  from public, anon, authenticated;
grant select, insert, update on table app_private.launch_waitlist
  to service_role;
revoke all on sequence app_private.launch_waitlist_id_seq
  from public, anon, authenticated;
grant usage, select on sequence app_private.launch_waitlist_id_seq
  to service_role;

create table if not exists app_private.payment_counters (
  workspace_id uuid primary key references public.workspaces(id) on delete cascade,
  next_number bigint not null default 1 check (next_number > 0)
);

create table if not exists app_private.workflow_idempotency (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null,
  operation text not null,
  idempotency_key text not null,
  result jsonb,
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id, operation, idempotency_key)
);

revoke all on table app_private.workflow_idempotency
  from public, anon, authenticated;
create index if not exists workflow_idempotency_created_at_idx
  on app_private.workflow_idempotency(created_at);

-- RPC contracts expected by the launch clients:
--
-- Edge-only public booking intake:
-- public.create_public_booking_request(
--   uuid, text, text, uuid, text, text, text, uuid
-- ) returns table (booking_request_id uuid, outcome text)
-- SECURITY DEFINER with an explicit search_path. EXECUTE is revoked from
-- PUBLIC, anon, and authenticated, then granted only to service_role. It
-- validates the workspace/service, serializes rate checks, preserves request
-- token idempotency, and inserts the request/counters atomically. The
-- allow_booking_request_notification trigger suppresses its notification when
-- all_notifications or booking_request preferences are disabled.
--
-- Authenticated transactional workflows:
-- public.create_task_workflow(jsonb) returns jsonb
-- public.create_booking_workflow(jsonb) returns jsonb
-- public.complete_booking_workflow(jsonb) returns jsonb
-- These public wrappers are SECURITY INVOKER, revoked from PUBLIC/anon, and
-- granted to authenticated. Private implementations validate auth.uid(),
-- workspace membership, linked-record ownership, conflicts, payload bounds,
-- and stable idempotency keys. Booking creation reuses an existing contact
-- when workspace-scoped digit-normalized phone values match; no country-code
-- inference is performed.

create unique index if not exists invoices_workspace_invoice_number_unique_idx
  on public.invoices(workspace_id, invoice_number)
  where invoice_number is not null;

-- A private before-insert trigger assigns PAY-### numbers when invoice_number
-- is omitted. Flutter should not generate payment numbers by counting rows.
