-- These private ledgers are intentionally unavailable to client roles. The
-- explicit false policies document that boundary while service_role continues
-- to use its RLS-bypass capability for trusted RPC and Edge Function work.

create policy payment_counters_deny_client_access
on app_private.payment_counters
for all
to anon, authenticated
using (false)
with check (false);

create policy workflow_idempotency_deny_client_access
on app_private.workflow_idempotency
for all
to anon, authenticated
using (false)
with check (false);

create policy stripe_webhook_events_deny_client_access
on app_private.stripe_webhook_events
for all
to anon, authenticated
using (false)
with check (false);
