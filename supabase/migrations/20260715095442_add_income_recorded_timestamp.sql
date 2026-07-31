-- Track when the currently collected invoice amount entered the business.
-- Issue date remains the invoice/business date; financial period summaries use
-- this timestamp so paying an older invoice counts in the collection period.

alter table public.invoices
  add column if not exists income_recorded_at timestamptz;

update public.invoices
   set income_recorded_at = coalesce(
     created_at,
     issue_date::timestamp at time zone 'UTC'
   )
 where income_recorded_at is null
   and (
     coalesce(amount_paid, 0) <> 0
     or status = 'paid'
   );

create index if not exists invoices_workspace_income_recorded_idx
  on public.invoices (workspace_id, income_recorded_at desc)
  where income_recorded_at is not null;
