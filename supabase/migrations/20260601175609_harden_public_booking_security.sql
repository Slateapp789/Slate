alter table public.services
  add column if not exists active boolean not null default true;

alter table public.booking_requests
  add column if not exists source_hash text;

create index if not exists booking_requests_source_hash_created_idx
  on public.booking_requests(workspace_id, source_hash, created_at desc);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'booking_requests_status_check'
      and conrelid = 'public.booking_requests'::regclass
  ) then
    alter table public.booking_requests
      add constraint booking_requests_status_check
      check (status in ('pending', 'contacted', 'confirmed', 'declined'))
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'booking_requests_public_text_bounds_check'
      and conrelid = 'public.booking_requests'::regclass
  ) then
    alter table public.booking_requests
      add constraint booking_requests_public_text_bounds_check
      check (
        char_length(btrim(name)) between 1 and 80
        and char_length(btrim(phone)) between 7 and 32
        and (
          preferred_time_text is null
          or char_length(preferred_time_text) <= 160
        )
        and (message is null or char_length(message) <= 1000)
      )
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'business_profiles_handle_format_check'
      and conrelid = 'public.business_profiles'::regclass
  ) then
    alter table public.business_profiles
      add constraint business_profiles_handle_format_check
      check (
        handle is null
        or handle = ''
        or handle ~ '^[a-z0-9][a-z0-9-]{1,78}[a-z0-9]$'
      )
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'business_profiles_booking_mode_check'
      and conrelid = 'public.business_profiles'::regclass
  ) then
    alter table public.business_profiles
      add constraint business_profiles_booking_mode_check
      check (booking_mode in ('manual', 'closed'))
      not valid;
  end if;
end $$;

create unique index if not exists business_profiles_handle_unique_idx
  on public.business_profiles(lower(handle))
  where handle is not null and handle <> '';

drop view if exists public.public_profile_services;
drop view if exists public.public_profile_cards;

create view public.public_profile_cards as
select
  bp.id,
  bp.handle,
  bp.bio,
  bp.cover_photo_url,
  bp.gallery_image_urls,
  bp.review_quotes,
  bp.reviews_enabled,
  bp.gallery_enabled,
  bp.pay_now_enabled,
  bp.booking_mode,
  bp.notice_text,
  bp.notice_start,
  bp.notice_end,
  w.name as business_name,
  w.industry,
  coalesce(ws.working_hours, '{}'::jsonb) as working_hours
from public.business_profiles bp
join public.workspaces w on w.id = bp.workspace_id
left join public.workspace_settings ws on ws.workspace_id = bp.workspace_id
where bp.handle is not null
  and bp.handle <> '';

create view public.public_profile_services as
select
  bp.handle,
  s.id,
  s.name,
  s.duration_mins,
  s.price,
  s.description,
  s.show_on_profile
from public.business_profiles bp
join public.services s on s.workspace_id = bp.workspace_id
where bp.handle is not null
  and bp.handle <> ''
  and s.show_on_profile = true
  and coalesce(s.active, true) = true;

revoke all on public.public_profile_cards from public;
revoke all on public.public_profile_services from public;
grant select on public.public_profile_cards to anon, authenticated;
grant select on public.public_profile_services to anon, authenticated;

drop policy if exists "Public can read visible services" on public.services;
drop policy if exists "Public can read business profiles" on public.business_profiles;
drop policy if exists "Public can create booking requests" on public.booking_requests;
