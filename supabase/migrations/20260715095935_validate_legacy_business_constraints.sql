-- Live preflight checks found zero violations for these legacy NOT VALID
-- constraints. Validate them so future query planning and schema inspection
-- can rely on the declared business rules.

alter table public.account_deletion_requests
  validate constraint account_deletion_requests_status_check;

alter table public.booking_requests
  validate constraint booking_requests_public_text_bounds_check;

alter table public.booking_requests
  validate constraint booking_requests_status_check;

alter table public.business_profiles
  validate constraint business_profiles_booking_mode_check;

alter table public.business_profiles
  validate constraint business_profiles_handle_format_check;
