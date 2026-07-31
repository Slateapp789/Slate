import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/finance_provider.dart';

void main() {
  group('core audit business date boundaries', () {
    test('week start follows the local business date of an instant', () {
      final instant = DateTime.utc(2026, 7, 26, 23, 30);
      final local = instant.toLocal();
      final expected = DateTime(
        local.year,
        local.month,
        local.day - (local.weekday - 1),
      );

      expect(startOfWeek(instant), expected);
    });

    test('calendar-day offsets always land at local midnight', () {
      final start = DateTime(2026, 3, 23);
      final nextWeek = addBusinessCalendarDays(start, 7);

      expect(nextWeek, DateTime(2026, 3, 30));
      expect(nextWeek.hour, 0);
      if (start.timeZoneOffset != nextWeek.timeZoneOffset) {
        expect(nextWeek.difference(start), isNot(const Duration(days: 7)));
      }
    });

    test('money ranges include their start and exclude their end', () {
      final range = MoneyPeriodRange(
        start: DateTime(2026, 7),
        end: DateTime(2026, 8),
        label: 'July',
      );
      final summary = PeriodMoneySummary.from(
        range: range,
        now: DateTime(2026, 7, 31, 12),
        payments: [
          _paid('start', DateTime(2026, 7), 10),
          _paid('last', DateTime(2026, 7, 31, 23, 59), 20),
          _paid('end', DateTime(2026, 8), 40),
        ],
        expenses: [
          Expense(
            id: 'start-expense',
            workspaceId: 'workspace-1',
            amount: 3,
            category: 'Travel',
            expenseDate: DateTime(2026, 7),
          ),
          Expense(
            id: 'end-expense',
            workspaceId: 'workspace-1',
            amount: 7,
            category: 'Travel',
            expenseDate: DateTime(2026, 8),
          ),
        ],
      );

      expect(summary.paid, 30);
      expect(summary.expenses, 3);
    });
  });
}

Payment _paid(String id, DateTime receivedAt, double amount) {
  return Payment(
    id: id,
    workspaceId: 'workspace-1',
    number: id,
    status: 'paid',
    issueDate: receivedAt,
    incomeRecordedAt: receivedAt,
    total: amount,
    amountPaid: amount,
  );
}
