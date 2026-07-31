import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/finance_provider.dart';

void main() {
  test('paid income is grouped by receipt date, not invoice issue date', () {
    final payment = Payment.fromMap({
      'id': 'payment-1',
      'workspace_id': 'workspace-1',
      'invoice_number': 'PAY-001',
      'status': 'paid',
      'issue_date': '2026-06-10',
      'income_recorded_at': '2026-07-12T10:00:00Z',
      'total': 240,
      'amount_paid': 240,
    });

    final summary = FinanceSummary.from(
      payments: [payment],
      expenses: const [],
      monthlyTarget: 0,
      now: DateTime(2026, 7, 20),
    );

    expect(payment.receivedDate, DateTime.utc(2026, 7, 12, 10).toLocal());
    expect(summary.thisMonthPaid, 240);
    expect(summary.lastMonthPaid, 0);
    expect(payment.toMap()['income_recorded_at'], '2026-07-12T10:00:00.000Z');
  });

  test('paid edit screens use the recorded receipt date', () {
    final payment = Payment.fromMap({
      'id': 'payment-edited',
      'workspace_id': 'workspace-1',
      'status': 'paid',
      'issue_date': '2026-06-10',
      'income_recorded_at': '2026-07-12T10:00:00Z',
      'total': 240,
      'amount_paid': 240,
    });

    expect(payment.receivedDate, DateTime.utc(2026, 7, 12, 10).toLocal());
    expect(payment.issueDate, DateTime(2026, 6, 10));
  });

  test('legacy paid records fall back safely to issue date', () {
    final payment = Payment.fromMap({
      'id': 'payment-legacy',
      'workspace_id': 'workspace-1',
      'status': 'paid',
      'issue_date': '2026-07-02',
      'total': 80,
      'amount_paid': 0,
    });

    expect(payment.receivedDate, DateTime(2026, 7, 2));
    expect(receivedAmountFor(payment), 80);
    expect(outstandingAmountFor(payment), 0);
  });

  test('overdue is derived from due date without persisted status changes', () {
    final payment = Payment.fromMap({
      'id': 'payment-overdue',
      'workspace_id': 'workspace-1',
      'status': 'sent',
      'issue_date': '2026-07-01',
      'due_date': '2026-07-10',
      'total': 120,
    });

    expect(
      moneyStatusFor(payment, now: DateTime(2026, 7, 11)),
      MoneyStatus.overdue,
    );
    expect(payment.status, 'sent');
  });
}
