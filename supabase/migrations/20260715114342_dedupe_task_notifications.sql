alter table public.notifications
  add column if not exists dedupe_key text;

create unique index if not exists notifications_workspace_dedupe_uidx
  on public.notifications (workspace_id, dedupe_key);

create or replace function public.clear_inactive_task_notification()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.status = 'done'
     or new.due_date is null
     or new.reminder_timing = 'none' then
    delete from public.notifications
    where workspace_id = new.workspace_id
      and dedupe_key = 'task_due:' || new.id::text;
  end if;
  return new;
end;
$$;

drop trigger if exists clear_inactive_task_notification on public.tasks;
create trigger clear_inactive_task_notification
after insert or update of status, due_date, reminder_timing on public.tasks
for each row execute function public.clear_inactive_task_notification();
