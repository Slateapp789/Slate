-- Use one clock value for every timestamp written by a delivery completion.
-- Separate clock_timestamp() calls can make next_attempt_at microscopically
-- earlier than updated_at + the promised backoff on a hosted database.

create or replace function public.finish_booking_confirmation_email(
  p_outbox_id uuid,
  p_lease_token uuid,
  p_sent boolean,
  p_provider_message_id text default null,
  p_error text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email app_private.transactional_email_outbox%rowtype;
  v_status text;
  v_backoff_minutes integer;
  v_now timestamptz;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  select email.* into v_email
    from app_private.transactional_email_outbox email
   where email.id = p_outbox_id
     and email.status = 'processing'
     and email.lease_token = p_lease_token
   for update;
  if not found then
    raise exception 'email delivery lease was not found'
      using errcode = 'P0002';
  end if;

  v_now := clock_timestamp();

  if p_sent then
    v_status := 'sent';
    update app_private.transactional_email_outbox
       set status = 'sent',
           provider_message_id = left(nullif(btrim(p_provider_message_id), ''), 200),
           last_error = null,
           sent_at = v_now,
           lease_token = null,
           lease_expires_at = null,
           updated_at = v_now
     where id = p_outbox_id;
  elsif v_email.attempt_count >= 8
        or v_email.delivery_expires_at <= v_now then
    v_status := 'failed';
    update app_private.transactional_email_outbox
       set status = 'failed',
           last_error = left(coalesce(nullif(btrim(p_error), ''), 'Provider delivery failed'), 500),
           lease_token = null,
           lease_expires_at = null,
           updated_at = v_now
     where id = p_outbox_id;
  else
    v_status := 'pending';
    v_backoff_minutes := least(
      60,
      power(2::numeric, greatest(v_email.attempt_count - 1, 0))::integer
    );
    update app_private.transactional_email_outbox
       set status = 'pending',
           next_attempt_at = v_now
             + make_interval(mins => v_backoff_minutes),
           last_error = left(coalesce(nullif(btrim(p_error), ''), 'Provider delivery failed'), 500),
           lease_token = null,
           lease_expires_at = null,
           updated_at = v_now
     where id = p_outbox_id;
  end if;

  return v_status;
end;
$$;

comment on function public.finish_booking_confirmation_email(
  uuid, uuid, boolean, text, text
) is
  'Service-role-only outbox acknowledgement using one timestamp for exact capped retry backoff.';
