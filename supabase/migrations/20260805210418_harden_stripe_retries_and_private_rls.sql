-- Make Stripe delivery retries recoverable and add defence-in-depth RLS to
-- private operational state. Client roles retain no direct table access.

alter table app_private.payment_counters enable row level security;
alter table app_private.workflow_idempotency enable row level security;
alter table app_private.stripe_webhook_events enable row level security;

revoke all on table app_private.payment_counters,
  app_private.workflow_idempotency,
  app_private.stripe_webhook_events
  from public, anon, authenticated;

grant select, insert, update on table app_private.payment_counters
  to service_role;
grant select, insert, update on table app_private.stripe_webhook_events
  to service_role;

alter table app_private.stripe_webhook_events
  add column if not exists attempt_count integer not null default 1
    check (attempt_count > 0),
  add column if not exists last_attempted_at timestamptz not null default now();

alter table public.payment_refunds
  add column if not exists idempotency_key text
    check (
      idempotency_key is null
      or char_length(idempotency_key) between 16 and 128
    );

create unique index if not exists payment_refunds_workspace_idempotency_idx
  on public.payment_refunds (workspace_id, idempotency_key)
  where idempotency_key is not null;

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
declare
  v_claimed boolean;
begin
  insert into app_private.stripe_webhook_events(
    stripe_event_id,
    stripe_account_id,
    event_type,
    livemode,
    payload,
    status,
    attempt_count,
    last_attempted_at
  ) values (
    p_event_id,
    p_account_id,
    p_event_type,
    p_livemode,
    p_payload,
    'processing',
    1,
    now()
  )
  on conflict (stripe_event_id) do update
    set stripe_account_id = excluded.stripe_account_id,
        event_type = excluded.event_type,
        livemode = excluded.livemode,
        payload = excluded.payload,
        status = 'processing',
        error_message = null,
        processed_at = null,
        attempt_count =
          app_private.stripe_webhook_events.attempt_count + 1,
        last_attempted_at = now()
  where app_private.stripe_webhook_events.status = 'failed'
     or (
       app_private.stripe_webhook_events.status = 'processing'
       and app_private.stripe_webhook_events.last_attempted_at
         < now() - interval '5 minutes'
     )
  returning true into v_claimed;

  return coalesce(v_claimed, false);
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
   where stripe_event_id = p_event_id
     and status = 'processing';

  if not found then
    raise exception 'Stripe webhook event is not actively processing'
      using errcode = '55000';
  end if;
end;
$$;

revoke execute on function public.finish_stripe_webhook_event(
  text, text, text
) from public, anon, authenticated;
grant execute on function public.finish_stripe_webhook_event(
  text, text, text
) to service_role;
