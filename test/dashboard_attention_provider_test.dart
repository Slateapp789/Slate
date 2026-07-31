import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/clients_provider.dart';
import 'package:workloop/shared/providers/dashboard_provider.dart';
import 'package:workloop/shared/providers/finance_provider.dart';
import 'package:workloop/shared/providers/tasks_provider.dart';

void main() {
  group('dashboard attention composer', () {
    test('builds and sorts attention items from existing app data', () {
      final now = DateTime(2026, 7, 6, 9);
      final items = buildDashboardAttentionItems(
        now: now,
        payments: [
          Payment.fromMap({
            'id': 'payment-overdue',
            'workspace_id': 'workspace-1',
            'invoice_number': 'PAY-001',
            'status': 'sent',
            'issue_date': '2026-06-28',
            'due_date': '2026-07-01',
            'total': 160,
            'contacts': {'name': 'Ahmed'},
          }),
          Payment.fromMap({
            'id': 'payment-recent',
            'workspace_id': 'workspace-1',
            'invoice_number': 'PAY-002',
            'status': 'sent',
            'issue_date': '2026-07-04',
            'due_date': '2026-07-04',
            'total': 80,
          }),
        ],
        tasks: [
          SlateTask.fromMap({
            'id': 'task-overdue',
            'workspace_id': 'workspace-1',
            'title': 'Send follow-up',
            'status': 'open',
            'due_date': '2026-07-05',
          }),
        ],
        appointments: [
          {
            'id': 'appointment-pending',
            'workspace_id': 'workspace-1',
            'start_time': '2026-07-06T18:00:00',
            'end_time': '2026-07-06T19:00:00',
            'status': 'pending',
            'contacts': {'name': 'Sarah'},
            'services': {'name': 'Consultation'},
          },
        ],
        clients: [
          Client.fromMap({
            'id': 'lead-stale',
            'workspace_id': 'workspace-1',
            'name': 'Maya',
            'status': 'lead',
            'created_at': '2026-06-20T09:00:00',
          }),
        ],
      );

      expect(
        items.map((item) => item.type),
        containsAll([
          DashboardAttentionType.unpaid,
          DashboardAttentionType.overdueTask,
          DashboardAttentionType.unconfirmedAppointment,
          DashboardAttentionType.uncontactedLead,
        ]),
      );
      expect(items.map((item) => item.title), isNot(contains('Collect £80')));
      expect(items.map((item) => item.type), [
        DashboardAttentionType.unconfirmedAppointment,
        DashboardAttentionType.overdueTask,
        DashboardAttentionType.unpaid,
        DashboardAttentionType.uncontactedLead,
      ]);
    });

    test('provider surfaces a source failure instead of hiding attention', () {
      final sourceError = StateError('tasks unavailable');
      final container = ProviderContainer(
        overrides: [
          invoicesProvider.overrideWith((ref) async => const <Payment>[]),
          allTasksProvider.overrideWith((ref) async => throw sourceError),
          todayAppointmentsProvider.overrideWith(
            (ref) async => const <Map<String, dynamic>>[],
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(dashboardAttentionProvider.future),
        throwsA(same(sourceError)),
      );
    });
  });
}
