-- Reconstruct the core Workloop schema that predates the repository's first
-- extension migration. This is intentionally idempotent for existing projects
-- and enables clean local/staging migration replay from an empty Supabase
-- project. The shape was reconciled read-only against production metadata on
-- 2026-07-26; later migrations remain responsible for all later extensions,
-- tenant-aware foreign keys, RLS policies, grants, and workflow functions.

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  industry text,
  logo_url text,
  created_at timestamptz default now()
);

create table if not exists public.workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique (workspace_id, user_id)
);

create table if not exists public.workspace_settings (
  workspace_id uuid primary key
    references public.workspaces(id) on delete cascade,
  timezone text default 'Europe/London',
  business_address text,
  working_hours jsonb default '{
    "mon": {"open": "09:00", "close": "18:00"},
    "tue": {"open": "09:00", "close": "18:00"},
    "wed": {"open": "09:00", "close": "18:00"},
    "thu": {"open": "09:00", "close": "18:00"},
    "fri": {"open": "09:00", "close": "17:00"},
    "sat": {"open": "09:00", "close": "14:00"},
    "sun": null
  }'::jsonb,
  buffer_mins integer default 0,
  reminder_24hr boolean default true,
  reminder_2hr boolean default true,
  invoice_overdue_reminder boolean default true,
  online_booking_enabled boolean default true,
  invoice_prefix text default 'INV',
  default_payment_terms_days integer default 7,
  default_tax_rate numeric default 0,
  stripe_account_id text,
  revenue_target numeric default 0
);

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete cascade,
  name text not null,
  email text,
  phone text,
  address text,
  notes text,
  status text default 'active'
    constraint contacts_status_check
    check (status in ('active', 'lead', 'inactive')),
  tags text[],
  last_activity_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete cascade,
  name text not null,
  duration_mins integer not null,
  price numeric not null,
  created_at timestamptz default now()
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  service_id uuid references public.services(id) on delete set null,
  title text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  status text default 'scheduled'
    constraint appointments_status_check
    check (status in ('scheduled', 'completed', 'cancelled', 'no_show')),
  price numeric,
  notes text,
  created_at timestamptz default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  invoice_number text not null,
  type text default 'invoice'
    constraint invoices_type_check
    check (type in ('invoice', 'quote')),
  status text default 'draft'
    constraint invoices_status_check
    check (
      status in (
        'draft',
        'sent',
        'paid',
        'overdue',
        'cancelled',
        'accepted',
        'declined'
      )
    ),
  issue_date date not null,
  due_date date,
  subtotal numeric not null default 0,
  tax_rate numeric default 0,
  tax_amount numeric default 0,
  discount_value numeric default 0,
  total numeric not null default 0,
  amount_paid numeric default 0,
  notes text,
  created_at timestamptz default now()
);

create table if not exists public.invoice_line_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid references public.invoices(id) on delete cascade,
  workspace_id uuid references public.workspaces(id) on delete cascade,
  description text not null,
  quantity numeric not null default 1,
  unit_price numeric not null,
  line_total numeric not null,
  position integer default 0
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references public.workspaces(id) on delete cascade,
  title text not null,
  status text default 'open'
    constraint tasks_status_check
    check (status in ('open', 'done')),
  priority text default 'medium'
    constraint tasks_priority_check
    check (priority in ('high', 'medium', 'low')),
  due_date date,
  notes text,
  contact_id uuid references public.contacts(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  completed_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.business_profiles (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid unique
    references public.workspaces(id) on delete cascade,
  handle text not null unique,
  social_instagram text,
  social_tiktok text,
  social_facebook text,
  created_at timestamptz default now()
);
