-- Keep PostgREST's exposed roles limited to the operations the Workloop mobile
-- client actually performs. Row-level security remains the tenant boundary;
-- these grants remove unnecessary TRUNCATE, TRIGGER, REFERENCES, and anonymous
-- table access before RLS is even evaluated.
revoke all privileges on all tables in schema public from public;
revoke all privileges on all tables in schema public from anon;
revoke all privileges on all tables in schema public from authenticated;

-- New public tables must opt in to Data API access in the migration that
-- creates them. Edge Functions use service_role and are not affected.
alter default privileges for role postgres in schema public
  revoke all privileges on tables from public;
alter default privileges for role postgres in schema public
  revoke all privileges on tables from anon;
alter default privileges for role postgres in schema public
  revoke all privileges on tables from authenticated;

grant select, insert, update, delete on table
  public.workspaces,
  public.workspace_members,
  public.workspace_settings,
  public.business_profiles,
  public.contacts,
  public.services,
  public.appointments,
  public.booking_requests,
  public.invoices,
  public.invoice_line_items,
  public.expenses,
  public.tasks,
  public.task_checklist_items,
  public.notes,
  public.notifications,
  public.notification_preferences,
  public.calendar_sync_accounts,
  public.push_tokens
to authenticated;

-- account_deletion_requests and account_deletion_audit intentionally receive no
-- client grants. The request/completion Edge Functions own those workflows.
