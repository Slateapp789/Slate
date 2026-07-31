-- Onboarding is intentionally exposed to signed-in users. RLS already permits
-- creating a workspace, its first self-membership, and then member-owned rows,
-- so the RPC must execute with caller privileges rather than bypassing RLS.
alter function public.complete_onboarding(
  text, text, text, jsonb, jsonb, numeric, jsonb
) security invoker;
