drop policy if exists "No client access to account deletion audit" on public.account_deletion_audit;
create policy "No client access to account deletion audit"
on public.account_deletion_audit for all
to anon, authenticated
using (false)
with check (false);
