-- Keep task completion history correct across every trusted client path.
create or replace function public.set_task_completion_timestamp()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.status = 'done' and (tg_op = 'INSERT' or old.status is distinct from 'done') then
    new.completed_at := coalesce(new.completed_at, now());
  elsif new.status is distinct from 'done' then
    new.completed_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists set_task_completion_timestamp on public.tasks;
create trigger set_task_completion_timestamp
before insert or update of status on public.tasks
for each row execute function public.set_task_completion_timestamp();

update public.tasks
set completed_at = coalesce(updated_at, created_at, now())
where status = 'done'
  and completed_at is null;

update public.tasks
set completed_at = null
where status is distinct from 'done'
  and completed_at is not null;
