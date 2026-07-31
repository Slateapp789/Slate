-- Preserve customer-facing booking notes when a booking is cancelled.
-- Cancellation metadata is separate so status changes remain reversible and
-- historical notes are never overwritten by a selected cancellation reason.

alter table public.appointments
  add column if not exists cancellation_reason text,
  add column if not exists cancelled_at timestamptz;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conname = 'appointments_cancellation_reason_length_check'
       and conrelid = 'public.appointments'::regclass
  ) then
    alter table public.appointments
      add constraint appointments_cancellation_reason_length_check
      check (
        cancellation_reason is null
        or char_length(cancellation_reason) <= 500
      ) not valid;
  end if;
end $$;

alter table public.appointments
  validate constraint appointments_cancellation_reason_length_check;
