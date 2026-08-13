-- Keep workspace deletion and booking-request joins bounded as the private
-- confirmation outbox grows. Postgres does not create indexes automatically
-- for the referencing side of foreign keys.
create index if not exists transactional_email_outbox_workspace_id_idx
  on app_private.transactional_email_outbox(workspace_id);

create index if not exists transactional_email_outbox_booking_request_id_idx
  on app_private.transactional_email_outbox(booking_request_id);
