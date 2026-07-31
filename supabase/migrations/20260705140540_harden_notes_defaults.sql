alter table if exists notes
  alter column title set default 'Untitled note',
  alter column body set default '',
  alter column pinned set default false,
  alter column created_at set default now(),
  alter column updated_at set default now();
