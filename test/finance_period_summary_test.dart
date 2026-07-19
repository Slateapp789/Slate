import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/finance_provider.dart';

void main() {
  group('PeriodMoneySummary', () {
    test('summarises paid unpaid expenses profit and categories in range', () {
      final range = MoneyPeriodRange(
        start: DateTime(2026, 5, 25),
        end: DateTime(2026, 6, 1),
        label: 'This week',
      );
      final summary = PeriodMoneySummary.from(
        range: range,
        payments: [
          Payment.fromMap({
            'id': 'pay-1',
            'workspace_id': 'workspace-1',
            'invoice_number': 'PAY-001',
            'status': 'paid',
            'issue_date': '2026-05-26',
            'total': 120,
          }),
          Payment.fromMap({
            'id': 'pay-2',
            'workspace_id': 'workspace-1',
            'invoice_number': 'PAY-002',
            'status': 'overdue',
            'issue_date': '2026-05-20',
            'due_date': '2026-05-27',
            'total': 80,
          }),
          Payment.fromMap({
            'id': 'pay-3',
            'workspace_id': 'workspace-1',
            'invoice_number': 'PAY-003',
            'status': 'paid',
            'issue_date': '2026-06-02',
            'total': 60,
          }),
        ],
        expenses: [
          Expense.fromMap({
            'id': 'expense-1',
            'workspace_id': 'workspace-1',
            'amount': 30,
            'category': 'Materials',
            'expense_date': '2026-05-27',
          }),
          Expense.fromMap({
            'id': 'expense-2',
            'workspace_id': 'workspace-1',
            'amount': 15,
            'category': 'Travel',
            'expense_date': '2026-05-28',
          }),
          Expense.fromMap({
            'id': 'expense-3',
            'workspace_id': 'workspace-1',
            'amount': 99,
            'category': 'Rent',
            'expense_date': '2026-06-03',
          }),
        ],
        now: DateTime(2026, 5, 29),
      );

      expect(summary.paid, 120);
      expect(summary.unpaid, 0);
      expect(summary.overdue, 80);
      expect(summary.expenses, 45);
      expect(summary.profit, 75);
      expect(summary.categoryTotals, {'Materials': 30, 'Travel': 15});
    });

    test('derives overdue from due date instead of trusting manual status', () {
      final range = MoneyPeriodRange(
        start: DateTime(2026, 5, 25),
        end: DateTime(2026, 6, 1),
        label: 'This week',
      );
      final summary = PeriodMoneySummary.from(
        range: range,
        now: DateTime(2026, 5, 30),
        payments: [
          Payment.fromMap({
            'id': 'pay-1',
            'workspace_id': 'workspace-1',
            'invoice_number': 'PAY-001',
            'status': 'sent',
            'issue_date': '2026-05-26',
            'due_date': '2026-05-29',
            'total': 90,
          }),
          Payment.fromMap({
            'id': 'pay-2',
            'workspace_id': 'workspace-1',
            'invoice_number': 'PAY-002',
            'status': 'sent',
            'issue_date': '2026-05-26',
            'due_date': '2026-05-31',
            'total': 40,
          }),
        ],
        expenses: const [],
      );

      expect(summary.unpaid, 40);
      expect(summary.overdue, 90);
      expect(summary.toCollect, 130);
    });
  });
}
