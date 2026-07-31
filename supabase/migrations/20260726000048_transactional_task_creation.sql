-- Create a task and its initial checklist as one authenticated, retry-safe
-- transaction. The private implementation validates tenant relationships and
-- the public wrapper exposes only the bounded JSON workflow to app clients.

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

create or replace function app_private.create_task_workflow(
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
  v_appointment_id uuid;
  v_idempotency_key text;
  v_existing_result jsonb;
  v_checklist jsonb;
  v_checklist_item jsonb;
  v_checklist_title text;
  v_title text;
  v_priority text;
  v_reminder_timing text;
  v_due_date date;
  v_task_id uuid;
  v_position integer := 0;
begin
  if v_caller_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Task payload must be an object' using errcode = '22023';
  end if;

  begin
    v_workspace_id := (p_payload ->> 'workspace_id')::uuid;
    v_contact_id := nullif(p_payload ->> 'contact_id', '')::uuid;
    v_appointment_id := nullif(p_payload ->> 'appointment_id', '')::uuid;
    v_due_date := nullif(p_payload ->> 'due_date', '')::date;
  exception
    when invalid_text_representation or datetime_field_overflow then
      raise exception 'A task record identifier or date is invalid'
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
    'create_task',
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
       and request.user_id = v_caller_id
       and request.operation = 'create_task'
       and request.idempotency_key = v_idempotency_key;
    if v_existing_result is null then
      raise exception 'Task workflow is already in progress'
        using errcode = '40001';
    end if;
    return v_existing_result;
  end if;

  v_title := btrim(coalesce(p_payload ->> 'title', ''));
  v_priority := btrim(coalesce(p_payload ->> 'priority', 'medium'));
  v_reminder_timing := btrim(
    coalesce(p_payload ->> 'reminder_timing', 'none')
  );
  v_checklist := coalesce(p_payload -> 'checklist_titles', '[]'::jsonb);

  if char_length(v_title) not between 1 and 500
     or v_priority not in ('high', 'medium', 'low')
     or v_reminder_timing not in (
       'none',
       'today',
       'day_before',
       'week_before'
     )
     or (v_reminder_timing <> 'none' and v_due_date is null)
     or (
       v_due_date is not null
       and v_due_date not between current_date - 3650 and current_date + 3650
     )
     or jsonb_typeof(v_checklist) <> 'array'
     or jsonb_array_length(v_checklist) > 50 then
    raise exception 'Task details are outside allowed bounds'
      using errcode = '22023';
  end if;

  if v_contact_id is not null and not exists (
    select 1
      from public.contacts contact
     where contact.id = v_contact_id
       and contact.workspace_id = v_workspace_id
  ) then
    raise exception 'Client does not belong to this workspace'
      using errcode = '23503';
  end if;

  if v_appointment_id is not null and not exists (
    select 1
      from public.appointments appointment
     where appointment.id = v_appointment_id
       and appointment.workspace_id = v_workspace_id
  ) then
    raise exception 'Booking does not belong to this workspace'
      using errcode = '23503';
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
    v_appointment_id,
    v_title,
    v_priority,
    v_due_date,
    'open',
    v_reminder_timing
  )
  returning id into v_task_id;

  for v_checklist_item in
    select value from jsonb_array_elements(v_checklist)
  loop
    if jsonb_typeof(v_checklist_item) <> 'string' then
      raise exception 'Checklist items must be text' using errcode = '22023';
    end if;
    v_checklist_title := btrim(v_checklist_item #>> '{}');
    if char_length(v_checklist_title) not between 1 and 500 then
      raise exception 'A checklist item is outside allowed bounds'
        using errcode = '22023';
    end if;

    insert into public.task_checklist_items(
      workspace_id,
      task_id,
      title,
      position
    ) values (
      v_workspace_id,
      v_task_id,
      v_checklist_title,
      v_position
    );
    v_position := v_position + 1;
  end loop;

  v_existing_result := jsonb_build_object(
    'task_id',
    v_task_id,
    'checklist_count',
    v_position
  );

  update app_private.workflow_idempotency request
     set result = v_existing_result
   where request.workspace_id = v_workspace_id
     and request.user_id = v_caller_id
     and request.operation = 'create_task'
     and request.idempotency_key = v_idempotency_key;

  return v_existing_result;
end;
$$;

revoke execute on function app_private.create_task_workflow(jsonb)
  from public, anon;
grant execute on function app_private.create_task_workflow(jsonb)
  to authenticated;

create or replace function public.create_task_workflow(
  p_payload jsonb
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app_private.create_task_workflow(p_payload);
$$;

revoke execute on function public.create_task_workflow(jsonb)
  from public, anon;
grant execute on function public.create_task_workflow(jsonb)
  to authenticated;

comment on function public.create_task_workflow(jsonb) is
  'Authenticated atomic task and checklist creation with tenant validation and idempotency.';
