import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/dashboard_provider.dart';
import 'package:workloop/shared/providers/finance_provider.dart';

void main() {
  test('dashboard revenue reuses receipt-date finance truth', () {
    final summary = FinanceSummary.from(
      payments: [
        Payment.fromMap({
          'id': 'paid-now',
          'workspace_id': 'workspace-1',
          'status': 'paid',
          'issue_date': '2026-06-10',
          'income_recorded_at': '2026-07-14T10:00:00Z',
          'total': 200,
          'amount_paid': 200,
        }),
      ],
      expenses: [
        Expense.fromMap({
          'id': 'expense-1',
          'workspace_id': 'workspace-1',
          'amount': 25,
          'category': 'Supplies',
          'expense_date': '2026-07-15',
        }),
      ],
      monthlyTarget: 1000,
      now: DateTime(2026, 7, 15),
    );

    final revenue = dashboardRevenueFromFinance(summary);

    expect(revenue.monthTotal, 200);
    expect(revenue.monthExpenses, 25);
    expect(revenue.revenueTarget, 1000);
  });

  test('dashboard focus derives overdue from due date', () {
    final focus = dashboardFocusFrom(
      nextAppointment: null,
      pendingBookingRequests: 0,
      now: DateTime(2026, 7, 20),
      payments: [
        Payment.fromMap({
          'id': 'past-due',
          'workspace_id': 'workspace-1',
          'status': 'sent',
          'issue_date': '2026-07-01',
          'due_date': '2026-07-10',
          'total': 120,
          'amount_paid': 20,
        }),
        Payment.fromMap({
          'id': 'not-due',
          'workspace_id': 'workspace-1',
          'status': 'sent',
          'issue_date': '2026-07-18',
          'due_date': '2026-07-25',
          'total': 70,
        }),
      ],
    );

    expect(focus.overduePayments, 1);
    expect(focus.overdueTotal, 100);
    expect(focus.hasAttention, isTrue);
  });
}
