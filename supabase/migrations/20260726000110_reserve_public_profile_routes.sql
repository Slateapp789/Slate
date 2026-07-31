-- Vanity profile handles share the workloop.app path namespace with app,
-- support, and legal routes. Keep those routes unclaimable at the database
-- boundary as well as in Flutter validation.
alter table public.business_profiles
  drop constraint if exists business_profiles_handle_format_check;

alter table public.business_profiles
  add constraint business_profiles_handle_format_check
  check (
    handle is null
    or handle = ''
    or handle ~ '^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$'
  );

alter table public.business_profiles
  drop constraint if exists business_profiles_reserved_handle_check;

alter table public.business_profiles
  add constraint business_profiles_reserved_handle_check
  check (
    lower(handle) <> all (
      array[
        'auth',
        'reset-password',
        'onboarding',
        'home',
        'business-feed',
        'clients',
        'tasks',
        'work',
        'bookings',
        'payments',
        'money',
        'finance',
        'notifications',
        'notes',
        'booking-requests',
        'calendar-sync',
        'calendar',
        'import-data',
        'profile',
        'settings',
        'p',
        'app',
        'api',
        'admin',
        'login',
        'logout',
        'signup',
        'register',
        'account',
        'privacy',
        'terms',
        'support',
        'help',
        'legal',
        'about',
        'delete-account',
        'robots',
        'sitemap',
        'www'
      ]::text[]
    )
  );

comment on constraint business_profiles_reserved_handle_check
  on public.business_profiles is
  'Protects application, legal, support, and system paths from vanity handles.';
