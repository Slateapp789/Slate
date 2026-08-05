-- Stripe Connect payment collection for Workloop Money.
--
-- Connected businesses are the merchant of record and own direct charges.
-- Provider writes are restricted to server-side service-role workflows; signed-in
-- workspace members receive read-only status through RLS. Existing manual Money
-- records remain supported, while stripe_amount_paid tracks the provider-managed
-- portion so webhook retries and refunds can be reconciled without double-counting.

alter table public.invoices
  add column if not exists stripe_amount_paid numeric not null default 0;

alter table public.invoices
  drop constraint if exists invoices_stripe_amount_paid_bounds;
alter table public.invoices
  add constraint invoices_stripe_amount_paid_bounds check (
    stripe_amount_paid >= 0
    and amount_paid >= stripe_amount_paid
    and (stripe_amount_paid = 0 or total >= stripe_amount_paid)
  );

create table if not exists public.workspace_payment_accounts (
  workspace_id uuid primary key
    references public.workspaces(id) on delete cascade,
  provider text not null default 'stripe'
    check (provider = 'stripe'),
  stripe_account_id text not null unique
    check (stripe_account_id ~ '^acct_[A-Za-z0-9]+$'),
  mode text not null default 'test'
    check (mode in ('test', 'live')),
  country text not null default 'GB'
    check (country = upper(country) and char_length(country) = 2),
  currency text not null default 'gbp'
    check (currency = lower(currency) and char_length(currency) = 3),
  onboarding_status text not null default 'pending'
    check (onboarding_status in ('pending', 'restricted', 'ready', 'disabled')),
  details_submitted boolean not null default false,
  charges_enabled boolean not null default false,
  payouts_enabled boolean not null default false,
  terminal_location_id text,
  requirements_due text[] not null default '{}',
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  invoice_id uuid not null,
  stripe_account_id text not null,
  stripe_payment_intent_id text,
  stripe_checkout_session_id text,
  stripe_charge_id text,
  collection_method text not null
    check (collection_method in ('tap_to_pay', 'payment_link')),
  status text not null default 'pending'
    check (status in (
      'pending', 'requires_payment_method', 'processing', 'succeeded',
      'partially_refunded', 'refunded', 'failed', 'cancelled', 'disputed'
    )),
  currency text not null default 'gbp'
    check (currency = lower(currency) and char_length(currency) = 3),
  amount_minor bigint not null check (amount_minor > 0),
  amount_refunded_minor bigint not null default 0
    check (amount_refunded_minor >= 0 and amount_refunded_minor <= amount_minor),
  platform_fee_minor bigint not null default 0
    check (platform_fee_minor >= 0 and platform_fee_minor <= amount_minor),
  receipt_url text,
  failure_code text,
  failure_message text,
  created_by_user_id uuid references auth.users(id) on delete set null,
  idempotency_key text not null check (char_length(idempotency_key) between 16 and 128),
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    stripe_payment_intent_id is not null
    or stripe_checkout_session_id is not null
  ),
  unique (stripe_account_id, stripe_payment_intent_id),
  unique (stripe_account_id, stripe_checkout_session_id),
  unique (workspace_id, idempotency_key),
  unique (id, workspace_id),
  foreign key (workspace_id, invoice_id)
    references public.invoices(workspace_id, id) on delete restrict
);

create table if not exists public.payment_refunds (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  transaction_id uuid not null,
  stripe_refund_id text not null,
  amount_minor bigint not null check (amount_minor > 0),
  status text not null
    check (status in ('pending', 'succeeded', 'failed', 'cancelled')),
  reason text,
  failure_reason text,
  created_by_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (stripe_refund_id),
  foreign key (transaction_id, workspace_id)
    references public.payment_transactions(id, workspace_id) on delete cascade
);

create table if not exists app_private.stripe_webhook_events (
  stripe_event_id text primary key,
  stripe_account_id text,
  event_type text not null,
  livemode boolean not null,
  payload jsonb not null,
  status text not null default 'processing'
    check (status in ('processing', 'processed', 'ignored', 'failed')),
  error_message text,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

revoke all on table app_private.stripe_webhook_events
  from public, anon, authenticated;
grant select, insert, update on table app_private.stripe_webhook_events
  to service_role;

create index if not exists payment_transactions_workspace_created_idx
  on public.payment_transactions (workspace_id, created_at desc);
create index if not exists payment_transactions_invoice_created_idx
  on public.payment_transactions (invoice_id, created_at desc);
create index if not exists payment_transactions_status_idx
  on public.payment_transactions (status)
  where status in ('pending', 'processing', 'disputed');
create index if not exists payment_refunds_transaction_created_idx
  on public.payment_refunds (transaction_id, created_at desc);
create index if not exists stripe_webhook_events_received_idx
  on app_private.stripe_webhook_events (received_at desc);

alter table public.workspace_payment_accounts enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.payment_refunds enable row level security;

drop policy if exists "Members can read payment account status"
  on public.workspace_payment_accounts;
create policy "Members can read payment account status"
  on public.workspace_payment_accounts for select
  to authenticated
  using (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can read provider payment transactions"
  on public.payment_transactions;
create policy "Members can read provider payment transactions"
  on public.payment_transactions for select
  to authenticated
  using (app_private.is_workspace_member(workspace_id));

drop policy if exists "Members can read provider payment refunds"
  on public.payment_refunds;
create policy "Members can read provider payment refunds"
  on public.payment_refunds for select
  to authenticated
  using (app_private.is_workspace_member(workspace_id));

revoke all on table public.workspace_payment_accounts,
  public.payment_transactions, public.payment_refunds
  from public, anon, authenticated;
grant select on table public.workspace_payment_accounts,
  public.payment_transactions, public.payment_refunds
  to authenticated;
grant all on table public.workspace_payment_accounts,
  public.payment_transactions, public.payment_refunds
  to service_role;

create or replace function public.claim_stripe_webhook_event(
  p_event_id text,
  p_account_id text,
  p_event_type text,
  p_livemode boolean,
  p_payload jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into app_private.stripe_webhook_events(
    stripe_event_id,
    stripe_account_id,
    event_type,
    livemode,
    payload
  ) values (
    p_event_id,
    p_account_id,
    p_event_type,
    p_livemode,
    p_payload
  )
  on conflict (stripe_event_id) do nothing;
  return found;
end;
$$;

revoke execute on function public.claim_stripe_webhook_event(
  text, text, text, boolean, jsonb
) from public, anon, authenticated;
grant execute on function public.claim_stripe_webhook_event(
  text, text, text, boolean, jsonb
) to service_role;

create or replace function public.finish_stripe_webhook_event(
  p_event_id text,
  p_status text,
  p_error_message text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_status not in ('processed', 'ignored', 'failed') then
    raise exception 'Invalid webhook completion status' using errcode = '22023';
  end if;
  update app_private.stripe_webhook_events
     set status = p_status,
         error_message = left(p_error_message, 1000),
         processed_at = now()
   where stripe_event_id = p_event_id;
end;
$$;

revoke execute on function public.finish_stripe_webhook_event(
  text, text, text
) from public, anon, authenticated;
grant execute on function public.finish_stripe_webhook_event(
  text, text, text
) to service_role;

create or replace function app_private.sync_invoice_stripe_amount()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_invoice_id uuid := coalesce(new.invoice_id, old.invoice_id);
  v_stripe_amount numeric;
begin
  select coalesce(sum(
    case
      when transaction.status in (
        'succeeded', 'partially_refunded', 'refunded'
      ) then (
        transaction.amount_minor - transaction.amount_refunded_minor
      )::numeric / 100
      else 0
    end
  ), 0)
  into v_stripe_amount
  from public.payment_transactions transaction
  where transaction.invoice_id = v_invoice_id;

  update public.invoices invoice
     set amount_paid = greatest(
           0,
           invoice.amount_paid - invoice.stripe_amount_paid + v_stripe_amount
         ),
         stripe_amount_paid = v_stripe_amount,
         status = case
           when greatest(
             0,
             invoice.amount_paid - invoice.stripe_amount_paid + v_stripe_amount
           ) >= invoice.total and invoice.total > 0 then 'paid'
           when invoice.status = 'paid' then 'sent'
           else invoice.status
         end,
         income_recorded_at = case
           when v_stripe_amount > 0 then coalesce(invoice.income_recorded_at, now())
           when greatest(
             0,
             invoice.amount_paid - invoice.stripe_amount_paid + v_stripe_amount
           ) = 0 then null
           else invoice.income_recorded_at
         end
   where invoice.id = v_invoice_id;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke execute on function app_private.sync_invoice_stripe_amount()
  from public, anon, authenticated;

drop trigger if exists sync_invoice_after_stripe_transaction
  on public.payment_transactions;
create trigger sync_invoice_after_stripe_transaction
after insert or update of status, amount_minor, amount_refunded_minor
or delete on public.payment_transactions
for each row execute function app_private.sync_invoice_stripe_amount();

-- Retain the pre-existing compatibility field while making the dedicated
-- payment-account record authoritative for provider state.
create or replace function app_private.sync_workspace_stripe_account_id()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.workspace_settings
     set stripe_account_id = new.stripe_account_id
   where workspace_id = new.workspace_id;
  return new;
end;
$$;

revoke execute on function app_private.sync_workspace_stripe_account_id()
  from public, anon, authenticated;

drop trigger if exists sync_workspace_stripe_account_id
  on public.workspace_payment_accounts;
create trigger sync_workspace_stripe_account_id
after insert or update of stripe_account_id
on public.workspace_payment_accounts
for each row execute function app_private.sync_workspace_stripe_account_id();
