-- Keep the Edge-only rate-limit ledger explicitly closed to client roles even
-- if table privileges change in a future migration. The service role bypasses
-- RLS and remains the only writer used by the Edge Functions.

drop policy if exists edge_rate_limit_events_deny_clients
  on app_private.edge_rate_limit_events;

create policy edge_rate_limit_events_deny_clients
  on app_private.edge_rate_limit_events
  for all
  to anon, authenticated
  using (false)
  with check (false);
