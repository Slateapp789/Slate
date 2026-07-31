-- Make booking creation and completion atomic and safely retryable.
-- Public RPC wrappers run with caller privileges. The implementations live in
-- the unexposed private schema, explicitly authenticate the caller, validate
-- every tenant relationship, and use narrowly scoped definer privileges.

create table if not exists app_private.workflow_idempotency (
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  user_id uuid not null,
  operation text not null,
  idempotency_key text not null,
  result jsonb,
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id, operation, idempotency_key)
);

revoke all on table app_private.workflow_idempotency from public, anon,
  authenticated;

create index if not exists workflow_idempotency_created_at_idx
  on app_private.workflow_idempotency (created_at);

create or replace function app_private.create_booking_workflow(
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_id uuid := auth.uid();
  v_workspace_id uuid;
  v_contact_id uuid;
  v_service_id uuid;
  v_request_id uuid;
  v_idempotency_key text;
  v_existing_result jsonb;
  v_appointments jsonb;
  v_occurrence jsonb;
  v_new_contact jsonb;
  v_task_title text;
  v_task_due_date date;
  v_title text;
  v_notes text;
  v_location text;
  v_recurrence_rule text;
  v_notification_title text;
  v_notification_body text;
  v_payment_note text;
  v_start timestamptz;
  v_end timestamptz;
  v_payment_date date;
  v_price numeric;
  v_appointment_id uuid;
  v_parent_id uuid;
  v_appointment_ids uuid[] := '{}'::uuid[];
  v_create_payment boolean;
  v_reuse_contact boolean;
  v_notification_allowed boolean := true;
  v_request_status text;
begin
  if v_caller_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Booking payload must be an object'
      using errcode = '22023';
  end if;

  begin
    v_workspace_id := (p_payload ->> 'workspace_id')::uuid;
  exception when invalid_text_representation then
    raise exception 'A valid workspace is required' using errcode = '22023';
  end;
  if not exists (
    select 1
      from public.workspace_members member
     where member.workspace_id = v_workspace_id
       and member.user_id = v_caller_id
  ) then
    raise exception 'Workspace access denied' using errcode = '42501';
  end if;

  v_idempotency_key := btrim(coalesce(p_payload ->> 'idempotency_key', ''));
  if char_length(v_idempotency_key) not between 16 and 128 then
    raise exception 'A valid idempotency key is required'
      using errcode = '22023';
  end if;

  insert into app_private.workflow_idempotency(
    workspace_id,
    user_id,
    operation,
    idempotency_key
  ) values (
    v_workspace_id,
    v_caller_id,
    'create_booking',
    v_idempotency_key
  )
  on conflict (
    workspace_id,
    user_id,
    operation,
    idempotency_key
  ) do nothing;

  if not found then
    select request.result
      into v_existing_result
      from app_private.workflow_idempotency request
     where request.workspace_id = v_workspace_id
       and request.operation = 'create_booking'
       and request.idempotency_key = v_idempotency_key
       and request.user_id = v_caller_id;
    if v_existing_result is null then
      raise exception 'Booking workflow is already in progress'
        using errcode = '40001';
    end if;
    return v_existing_result;
  end if;

  -- Serialize schedule writes for one workspace so conflict checks cannot race.
  perform pg_advisory_xact_lock(
    hashtextextended(v_workspace_id::text, 882001)
  );

  v_appointments := p_payload -> 'appointments';
  if v_appointments is null or jsonb_typeof(v_appointments) <> 'array' then
    raise exception 'Appointments must be an array' using errcode = '22023';
  end if;
  if jsonb_array_length(v_appointments) not between 1 and 24 then
    raise exception 'A workflow must contain between 1 and 24 appointments'
      using errcode = '22023';
  end if;

  begin
    v_contact_id := nullif(p_payload ->> 'contact_id', '')::uuid;
    v_service_id := nullif(p_payload ->> 'service_id', '')::uuid;
    v_request_id := nullif(p_payload ->> 'booking_request_id', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'A linked record identifier is invalid'
      using errcode = '22023';
  end;

  if v_request_id is not null then
    select request.status
      into v_request_status
      from public.booking_requests request
     where request.id = v_request_id
       and request.workspace_id = v_workspace_id
     for update;
    if not found then
      raise exception 'Booking request was not found' using errcode = 'P0002';
    end if;
    if v_request_status not in ('pending', 'contacted') then
      raise exception 'Booking request can no longer be confirmed'
        using errcode = '23505';
    end if;
  end if;

  if v_service_id is not null and not exists (
    select 1
      from public.services service
     where service.id = v_service_id
       and service.workspace_id = v_workspace_id
  ) then
    raise exception 'Service does not belong to this workspace'
      using errcode = '23503';
  end if;

  if v_contact_id is not null then
    if not exists (
      select 1
        from public.contacts contact
       where contact.id = v_contact_id
         and contact.workspace_id = v_workspace_id
    ) then
      raise exception 'Client does not belong to this workspace'
        using errcode = '23503';
    end if;
  else
    v_new_contact := p_payload -> 'new_contact';
    if v_new_contact is null or jsonb_typeof(v_new_contact) <> 'object' then
      raise exception 'A new client is required' using errcode = '22023';
    end if;
    if char_length(btrim(coalesce(v_new_contact ->> 'name', '')))
       not between 1 and 200
       or char_length(coalesce(v_new_contact ->> 'phone', '')) > 64
       or char_length(coalesce(v_new_contact ->> 'email', '')) > 320
       or char_length(coalesce(v_new_contact ->> 'address', '')) > 1000
       or char_length(coalesce(v_new_contact ->> 'notes', '')) > 10000 then
      raise exception 'New client details are invalid' using errcode = '22023';
    end if;

    v_reuse_contact := coalesce(
      (p_payload ->> 'reuse_contact_by_phone')::boolean,
      false
    );
    if v_reuse_contact
       and nullif(btrim(coalesce(v_new_contact ->> 'phone', '')), '') is not null
    then
      select contact.id
        into v_contact_id
        from public.contacts contact
       where contact.workspace_id = v_workspace_id
         and contact.phone = btrim(v_new_contact ->> 'phone')
       order by contact.created_at, contact.id
       limit 1;
    end if;

    if v_contact_id is null then
      insert into public.contacts(
        workspace_id,
        name,
        phone,
        email,
        address,
        notes,
        status,
        preferred_contact_method,
        last_activity_at
      ) values (
        v_workspace_id,
        btrim(v_new_contact ->> 'name'),
        nullif(btrim(coalesce(v_new_contact ->> 'phone', '')), ''),
        nullif(btrim(coalesce(v_new_contact ->> 'email', '')), ''),
        nullif(btrim(coalesce(v_new_contact ->> 'address', '')), ''),
        nullif(btrim(coalesce(v_new_contact ->> 'notes', '')), ''),
        'active',
        case
          when nullif(btrim(coalesce(v_new_contact ->> 'phone', '')), '')
            is not null then 'phone'
          when nullif(btrim(coalesce(v_new_contact ->> 'email', '')), '')
            is not null then 'email'
          else 'phone'
        end,
        now()
      )
      returning id into v_contact_id;
    end if;
  end if;

  v_title := btrim(coalesce(p_payload ->> 'title', 'Booking'));
  v_notes := nullif(btrim(coalesce(p_payload ->> 'notes', '')), '');
  v_location := nullif(btrim(coalesce(p_payload ->> 'location', '')), '');
  v_recurrence_rule := nullif(
    btrim(coalesce(p_payload ->> 'recurrence_rule', '')),
    ''
  );
  v_notification_title := btrim(
    coalesce(p_payload ->> 'notification_title', 'New booking created')
  );
  v_notification_body := btrim(
    coalesce(
      p_payload ->> 'notification_body',
      'A booking was added to your schedule.'
    )
  );
  v_payment_note := nullif(
    btrim(coalesce(p_payload ->> 'payment_note', '')),
    ''
  );
  v_create_payment := coalesce(
    (p_payload ->> 'create_payment_due')::boolean,
    false
  );

  begin
    v_price := (p_payload ->> 'price')::numeric;
    v_task_due_date := nullif(p_payload ->> 'task_due_date', '')::date;
  exception when invalid_text_representation or numeric_value_out_of_range then
    raise exception 'Booking amount or task date is invalid'
      using errcode = '22023';
  end;

  if char_length(v_title) not between 1 and 200
     or char_length(coalesce(v_notes, '')) > 10000
     or char_length(coalesce(v_location, '')) > 1000
     or char_length(v_notification_title) not between 1 and 200
     or char_length(v_notification_body) not between 1 and 1000
     or v_price is null
     or v_price::text = 'NaN'
     or v_price < 0
     or v_price > 1000000
     or (
       v_recurrence_rule is not null
       and v_recurrence_rule not in (
         'FREQ=WEEKLY;INTERVAL=1',
         'FREQ=WEEKLY;INTERVAL=2',
         'FREQ=MONTHLY;INTERVAL=1'
       )
     ) then
    raise exception 'Booking details are outside allowed bounds'
      using errcode = '22023';
  end if;

  for v_occurrence in
    select value from jsonb_array_elements(v_appointments)
  loop
    if jsonb_typeof(v_occurrence) <> 'object' then
      raise exception 'An appointment entry is invalid'
        using errcode = '22023';
    end if;
    begin
      v_start := (v_occurrence ->> 'start_time')::timestamptz;
      v_end := (v_occurrence ->> 'end_time')::timestamptz;
      v_payment_date := coalesce(
        nullif(v_occurrence ->> 'payment_date', '')::date,
        (v_start at time zone 'UTC')::date
      );
    exception when invalid_text_representation or datetime_field_overflow then
      raise exception 'An appointment date is invalid' using errcode = '22023';
    end;

    if v_start is null
       or v_end is null
       or v_end <= v_start
       or v_end - v_start > interval '24 hours'
       or v_start < now() - interval '5 years'
       or v_start > now() + interval '5 years' then
      raise exception 'Appointment timing is outside allowed bounds'
        using errcode = '22023';
    end if;

    if exists (
      select 1
        from public.appointments appointment
       where appointment.workspace_id = v_workspace_id
         and appointment.status not in ('cancelled', 'no_show')
         and appointment.start_time < v_end
         and appointment.end_time > v_start
    ) then
      raise exception 'Appointment overlaps an existing booking'
        using errcode = '23P01';
    end if;

    v_appointment_id := gen_random_uuid();
    insert into public.appointments(
      id,
      workspace_id,
      contact_id,
      service_id,
      title,
      start_time,
      end_time,
      price,
      status,
      notes,
      location,
      recurrence_rule,
      recurrence_parent_id
    ) values (
      v_appointment_id,
      v_workspace_id,
      v_contact_id,
      v_service_id,
      v_title,
      v_start,
      v_end,
      v_price,
      'scheduled',
      v_notes,
      v_location,
      v_recurrence_rule,
      v_parent_id
    );
    if v_parent_id is null and jsonb_array_length(v_appointments) > 1 then
      v_parent_id := v_appointment_id;
    end if;
    v_appointment_ids := array_append(
      v_appointment_ids,
      v_appointment_id
    );

    if v_create_payment and v_price > 0 then
      insert into public.invoices(
        workspace_id,
        contact_id,
        appointment_id,
        type,
        status,
        issue_date,
        due_date,
        subtotal,
        tax_rate,
        tax_amount,
        discount_value,
        total,
        amount_paid,
        income_recorded_at,
        notes
      ) values (
        v_workspace_id,
        v_contact_id,
        v_appointment_id,
        'invoice',
        'sent',
        v_payment_date,
        v_payment_date,
        v_price,
        0,
        0,
        0,
        v_price,
        0,
        null,
        v_payment_note
      );
    end if;
  end loop;

  if p_payload -> 'task_titles' is not null then
    if jsonb_typeof(p_payload -> 'task_titles') <> 'array'
       or jsonb_array_length(p_payload -> 'task_titles') > 20 then
      raise exception 'Task titles must be an array of at most 20 items'
        using errcode = '22023';
    end if;
    for v_task_title in
      select value
        from jsonb_array_elements_text(p_payload -> 'task_titles')
    loop
      v_task_title := btrim(v_task_title);
      if char_length(v_task_title) not between 1 and 500 then
        raise exception 'A task title is invalid' using errcode = '22023';
      end if;
      insert into public.tasks(
        workspace_id,
        contact_id,
        appointment_id,
        title,
        priority,
        due_date,
        status,
        reminder_timing
      ) values (
        v_workspace_id,
        v_contact_id,
        v_appointment_ids[1],
        v_task_title,
        'medium',
        v_task_due_date,
        'open',
        'none'
      );
    end loop;
  end if;

  if v_request_id is not null then
    update public.booking_requests
       set status = 'confirmed'
     where id = v_request_id
       and workspace_id = v_workspace_id;
  end if;

  select coalesce(
    preference.all_notifications and preference.new_booking,
    true
  )
    into v_notification_allowed
    from public.notification_preferences preference
   where preference.workspace_id = v_workspace_id;

  if coalesce(v_notification_allowed, true) then
    insert into public.notifications(
      workspace_id,
      type,
      title,
      body,
      deep_link,
      dedupe_key
    ) values (
      v_workspace_id,
      'new_booking',
      v_notification_title,
      v_notification_body,
      '/work',
      'workflow:create_booking:' || v_idempotency_key
    )
    on conflict (workspace_id, dedupe_key) do nothing;
  end if;

  v_existing_result := jsonb_build_object(
    'appointment_ids',
    to_jsonb(v_appointment_ids),
    'contact_id',
    v_contact_id
  );
  update app_private.workflow_idempotency request
     set result = v_existing_result
   where request.workspace_id = v_workspace_id
     and request.operation = 'create_booking'
     and request.idempotency_key = v_idempotency_key
     and request.user_id = v_caller_id;
  return v_existing_result;
end;
$$;

revoke execute on function app_private.create_booking_workflow(jsonb)
  from public, anon;
grant execute on function app_private.create_booking_workflow(jsonb)
  to authenticated;

create or replace function public.create_booking_workflow(
  p_payload jsonb
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app_private.create_booking_workflow(p_payload);
$$;

revoke execute on function public.create_booking_workflow(jsonb)
  from public, anon;
grant execute on function public.create_booking_workflow(jsonb)
  to authenticated;

create or replace function app_private.complete_booking_workflow(
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_id uuid := auth.uid();
  v_workspace_id uuid;
  v_appointment_id uuid;
  v_linked_payment_id uuid;
  v_invoice_id uuid;
  v_contact_id uuid;
  v_idempotency_key text;
  v_payment_mode text;
  v_payment_date date;
  v_existing_result jsonb;
  v_appointment_status text;
  v_service_name text;
  v_client_name text;
  v_price numeric;
  v_invoice_total numeric;
  v_start timestamptz;
  v_notification_allowed boolean := true;
begin
  if v_caller_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Completion payload must be an object'
      using errcode = '22023';
  end if;
  begin
    v_workspace_id := (p_payload ->> 'workspace_id')::uuid;
    v_appointment_id := (p_payload ->> 'appointment_id')::uuid;
    v_linked_payment_id := nullif(
      p_payload ->> 'linked_payment_id',
      ''
    )::uuid;
  exception when invalid_text_representation then
    raise exception 'A completion record identifier is invalid'
      using errcode = '22023';
  end;
  if not exists (
    select 1
      from public.workspace_members member
     where member.workspace_id = v_workspace_id
       and member.user_id = v_caller_id
  ) then
    raise exception 'Workspace access denied' using errcode = '42501';
  end if;

  v_idempotency_key := btrim(coalesce(p_payload ->> 'idempotency_key', ''));
  v_payment_mode := lower(btrim(coalesce(
    p_payload ->> 'payment_mode',
    'skip'
  )));
  if char_length(v_idempotency_key) not between 16 and 128
     or v_payment_mode not in (
       'skip',
       'paid',
       'unpaid',
       'linked_paid',
       'linked_unpaid'
     ) then
    raise exception 'Completion options are invalid' using errcode = '22023';
  end if;
  if v_payment_mode like 'linked_%' and v_linked_payment_id is null then
    raise exception 'A linked payment is required' using errcode = '22023';
  end if;

  insert into app_private.workflow_idempotency(
    workspace_id,
    user_id,
    operation,
    idempotency_key
  ) values (
    v_workspace_id,
    v_caller_id,
    'complete_booking',
    v_idempotency_key
  )
  on conflict (
    workspace_id,
    user_id,
    operation,
    idempotency_key
  ) do nothing;

  if not found then
    select request.result
      into v_existing_result
      from app_private.workflow_idempotency request
     where request.workspace_id = v_workspace_id
       and request.operation = 'complete_booking'
       and request.idempotency_key = v_idempotency_key
       and request.user_id = v_caller_id;
    if v_existing_result is null then
      raise exception 'Completion workflow is already in progress'
        using errcode = '40001';
    end if;
    return v_existing_result;
  end if;

  select
    appointment.contact_id,
    appointment.price,
    appointment.start_time,
    appointment.status,
    coalesce(service.name, appointment.title, 'Booking'),
    coalesce(contact.name, 'a client')
  into
    v_contact_id,
    v_price,
    v_start,
    v_appointment_status,
    v_service_name,
    v_client_name
  from public.appointments appointment
  left join public.services service
    on service.id = appointment.service_id
   and service.workspace_id = appointment.workspace_id
  left join public.contacts contact
    on contact.id = appointment.contact_id
   and contact.workspace_id = appointment.workspace_id
  where appointment.id = v_appointment_id
    and appointment.workspace_id = v_workspace_id
  for update of appointment;

  if not found then
    raise exception 'Booking was not found' using errcode = 'P0002';
  end if;
  if v_appointment_status in ('cancelled', 'no_show') then
    raise exception 'A cancelled booking cannot be completed'
      using errcode = '22023';
  end if;

  begin
    v_payment_date := coalesce(
      nullif(p_payload ->> 'payment_date', '')::date,
      (v_start at time zone 'UTC')::date
    );
  exception when invalid_text_representation or datetime_field_overflow then
    raise exception 'Payment date is invalid' using errcode = '22023';
  end;

  update public.appointments
     set status = 'completed'
   where id = v_appointment_id
     and workspace_id = v_workspace_id;

  if v_linked_payment_id is not null then
    select invoice.id, invoice.total
      into v_invoice_id, v_invoice_total
      from public.invoices invoice
     where invoice.id = v_linked_payment_id
       and invoice.workspace_id = v_workspace_id
       and invoice.appointment_id = v_appointment_id
     for update;
    if not found then
      raise exception 'Linked payment was not found' using errcode = 'P0002';
    end if;
    if v_payment_mode = 'linked_paid' then
      update public.invoices
         set status = 'paid',
             amount_paid = total,
             income_recorded_at = coalesce(income_recorded_at, now())
       where id = v_invoice_id
         and workspace_id = v_workspace_id;
    end if;
  elsif v_payment_mode in ('paid', 'unpaid') and v_price > 0 then
    select invoice.id, invoice.total
      into v_invoice_id, v_invoice_total
      from public.invoices invoice
     where invoice.workspace_id = v_workspace_id
       and invoice.appointment_id = v_appointment_id
     order by invoice.created_at, invoice.id
     limit 1
     for update;

    if v_invoice_id is null then
      insert into public.invoices(
        workspace_id,
        contact_id,
        appointment_id,
        type,
        status,
        issue_date,
        due_date,
        subtotal,
        tax_rate,
        tax_amount,
        discount_value,
        total,
        amount_paid,
        income_recorded_at,
        notes
      ) values (
        v_workspace_id,
        v_contact_id,
        v_appointment_id,
        'invoice',
        case when v_payment_mode = 'paid' then 'paid' else 'sent' end,
        v_payment_date,
        v_payment_date,
        v_price,
        0,
        0,
        0,
        v_price,
        case when v_payment_mode = 'paid' then v_price else 0 end,
        case when v_payment_mode = 'paid' then now() else null end,
        case
          when v_payment_mode = 'paid'
            then 'Payment received for ' || v_service_name
          else 'Payment due for ' || v_service_name
        end
      )
      returning id into v_invoice_id;
      v_invoice_total := v_price;
    elsif v_payment_mode = 'paid' then
      update public.invoices
         set status = 'paid',
             amount_paid = total,
             income_recorded_at = coalesce(income_recorded_at, now())
       where id = v_invoice_id
         and workspace_id = v_workspace_id;
    end if;
  end if;

  if v_payment_mode in ('paid', 'linked_paid') then
    select coalesce(
      preference.all_notifications and preference.payment_received,
      true
    )
      into v_notification_allowed
      from public.notification_preferences preference
     where preference.workspace_id = v_workspace_id;
    if coalesce(v_notification_allowed, true) then
      insert into public.notifications(
        workspace_id,
        type,
        title,
        body,
        deep_link,
        dedupe_key
      ) values (
        v_workspace_id,
        'payment_received',
        'Payment received',
        '£' || trim(to_char(
          coalesce(v_invoice_total, v_price),
          'FM999999990.00'
        )) ||
          ' from ' || v_client_name || ' is now paid.',
        '/payments',
        'workflow:complete_booking:' || v_idempotency_key
      )
      on conflict (workspace_id, dedupe_key) do nothing;
    end if;
  elsif v_payment_mode = 'unpaid' then
    select coalesce(
      preference.all_notifications and preference.invoice_overdue,
      true
    )
      into v_notification_allowed
      from public.notification_preferences preference
     where preference.workspace_id = v_workspace_id;
    if coalesce(v_notification_allowed, true) then
      insert into public.notifications(
        workspace_id,
        type,
        title,
        body,
        deep_link,
        dedupe_key
      ) values (
        v_workspace_id,
        'invoice_overdue',
        'Payment pending',
        '£' || trim(to_char(
          coalesce(v_invoice_total, v_price),
          'FM999999990.00'
        )) ||
          ' is outstanding for ' || v_service_name || '.',
        '/payments',
        'workflow:complete_booking:' || v_idempotency_key
      )
      on conflict (workspace_id, dedupe_key) do nothing;
    end if;
  end if;

  v_existing_result := jsonb_build_object(
    'appointment_id',
    v_appointment_id,
    'invoice_id',
    v_invoice_id,
    'status',
    'completed'
  );
  update app_private.workflow_idempotency request
     set result = v_existing_result
   where request.workspace_id = v_workspace_id
     and request.operation = 'complete_booking'
     and request.idempotency_key = v_idempotency_key
     and request.user_id = v_caller_id;
  return v_existing_result;
end;
$$;

revoke execute on function app_private.complete_booking_workflow(jsonb)
  from public, anon;
grant execute on function app_private.complete_booking_workflow(jsonb)
  to authenticated;

create or replace function public.complete_booking_workflow(
  p_payload jsonb
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app_private.complete_booking_workflow(p_payload);
$$;

revoke execute on function public.complete_booking_workflow(jsonb)
  from public, anon;
grant execute on function public.complete_booking_workflow(jsonb)
  to authenticated;

comment on function public.create_booking_workflow(jsonb) is
  'Authenticated atomic booking creation with tenant validation, conflict serialization, and idempotency.';
comment on function public.complete_booking_workflow(jsonb) is
  'Authenticated atomic booking completion and linked payment handling with idempotency.';
