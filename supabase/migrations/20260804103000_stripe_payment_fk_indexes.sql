create index if not exists payment_transactions_workspace_invoice_idx
  on public.payment_transactions (workspace_id, invoice_id);

create index if not exists payment_transactions_created_by_idx
  on public.payment_transactions (created_by_user_id)
  where created_by_user_id is not null;

create index if not exists payment_refunds_transaction_workspace_idx
  on public.payment_refunds (transaction_id, workspace_id);

create index if not exists payment_refunds_workspace_created_idx
  on public.payment_refunds (workspace_id, created_at desc);

create index if not exists payment_refunds_created_by_idx
  on public.payment_refunds (created_by_user_id)
  where created_by_user_id is not null;
