-- Account-deletion creation and completion remain Edge-only. Authenticated
-- workspace members may read their own request history so a privacy export can
-- be complete. The existing SELECT RLS policy remains the tenant boundary.
grant select on table public.account_deletion_requests to authenticated;
