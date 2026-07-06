import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/models/business_feed_item.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/business_feed_provider.dart';
import 'package:workloop/shared/providers/finance_provider.dart';

void main() {
  group('business feed composer', () {
    test('generates cross-module feed items from existing data', () {
      final now = DateTime(2026, 7, 6, 9);
      final payments = [
        Payment.fromMap({
          'id': 'payment-overdue',
          'workspace_id': 'workspace-1',
          'invoice_number': 'PAY-001',
          'status': 'sent',
          'issue_date': '2026-07-01',
          'due_date': '2026-07-03',
          'total': 120,
          'contacts': {'name': 'Ahmed'},
        }),
        Payment.fromMap({
          'id': 'payment-paid',
          'workspace_id': 'workspace-1',
          'invoice_number': 'PAY-002',
          'status': 'paid',
          'issue_date': '2026-07-06',
          'total': 240,
          'contacts': {'name': 'James'},
        }),
      ];
      final expenses = [
        Expense.fromMap({
          'id': 'expense-1',
          'workspace_id': 'workspace-1',
          'amount': 35,
          'category': 'Materials',
          'expense_date': '2026-07-05',
        }),
      ];
      final items = buildBusinessFeedItems(
        now: now,
        appointments: [
          {
            'id': 'booking-1',
            'workspace_id': 'workspace-1',
            'start_time': '2026-07-06T10:00:00',
            'end_time': '2026-07-06T11:00:00',
            'status': 'scheduled',
            'price': 80,
            'contacts': {'name': 'Sarah'},
            'services': {'name': 'Cut'},
          },
        ],
        payments: payments,
        expenses: expenses,
        tasks: [
          SlateTask.fromMap({
            'id': 'task-1',
            'workspace_id': 'workspace-1',
            'title': 'Send prep message',
            'status': 'open',
            'due_date': '2026-07-06',
          }),
          SlateTask.fromMap({
            'id': 'task-overdue',
            'workspace_id': 'workspace-1',
            'title': 'Follow up estimate',
            'status': 'open',
            'due_date': '2026-07-05',
          }),
        ],
        notes: [
          SlateNote.fromMap({
            'id': 'note-1',
            'workspace_id': 'workspace-1',
            'title': 'Colour formula',
            'body': 'Use 7N',
            'updated_at': '2026-07-06T08:30:00',
            'pinned': true,
            'contacts': {'name': 'Maya'},
          }),
        ],
        clients: [
          Client.fromMap({
            'id': 'client-1',
            'workspace_id': 'workspace-1',
            'name': 'Emma',
            'status': 'lead',
            'created_at': '2026-06-20T08:00:00',
          }),
        ],
        bookingRequests: [
          BookingRequest.fromMap({
            'id': 'request-1',
            'workspace_id': 'workspace-1',
            'name': 'Nadia',
            'phone': '07123',
            'preferred_time_text': 'Tuesday at 10:00',
            'status': 'pending',
            'created_at': '2026-07-06T08:00:00',
          }),
        ],
        finance: FinanceSummary.from(
          payments: payments,
          expenses: expenses,
          monthlyTarget: 1200,
          now: now,
        ),
      );

      expect(
        items.map((item) => item.type),
        containsAll([
          BusinessFeedItemType.dailySummary,
          BusinessFeedItemType.bookingToday,
          BusinessFeedItemType.paymentReceived,
          BusinessFeedItemType.invoiceOverdue,
          BusinessFeedItemType.expenseRecorded,
          BusinessFeedItemType.taskDue,
          BusinessFeedItemType.taskOverdue,
          BusinessFeedItemType.noteCreated,
          BusinessFeedItemType.clientFollowUp,
          BusinessFeedItemType.bookingRequestNew,
          BusinessFeedItemType.quietDayDetected,
          BusinessFeedItemType.weeklyTargetProgress,
        ]),
      );
      expect(items.first.priority, BusinessFeedPriority.attention);
      expect(items.first.routeTarget, isNotNull);
    });

    test('filters money items without leaking other source types', () {
      final now = DateTime(2026, 7, 6, 9);
      final payments = [
        Payment.fromMap({
          'id': 'payment-paid',
          'workspace_id': 'workspace-1',
          'invoice_number': 'PAY-002',
          'status': 'paid',
          'issue_date': '2026-07-06',
          'total': 240,
        }),
      ];
      final expenses = [
        Expense.fromMap({
          'id': 'expense-1',
          'workspace_id': 'workspace-1',
          'amount': 35,
          'category': 'Materials',
          'expense_date': '2026-07-05',
        }),
      ];
      final items = buildBusinessFeedItems(
        now: now,
        appointments: const [],
        payments: payments,
        expenses: expenses,
        tasks: const [],
        notes: const [],
        clients: const [],
        bookingRequests: const [],
        finance: FinanceSummary.from(
          payments: payments,
          expenses: expenses,
          monthlyTarget: 0,
          now: now,
        ),
      );

      final moneyItems = filteredBusinessFeedItems(
        items,
        BusinessFeedFilter.money,
      );

      expect(moneyItems, isNotEmpty);
      expect(
        moneyItems.every(
          (item) =>
              item.sourceType == BusinessFeedSourceType.payment ||
              item.sourceType == BusinessFeedSourceType.expense,
        ),
        isTrue,
      );
    });
  });
}
