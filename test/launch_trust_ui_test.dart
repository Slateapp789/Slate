import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/appointments/appointments_screen.dart';
import 'package:workloop/features/clients/providers/client_detail_providers.dart';
import 'package:workloop/features/clients/widgets/client_overview_tab.dart';
import 'package:workloop/features/profile/working_hours_editor.dart';
import 'package:workloop/features/public_profile/booking_requests_screen.dart';
import 'package:workloop/features/public_profile/public_profile_screen.dart';
import 'package:workloop/features/settings/providers/settings_providers.dart';
import 'package:workloop/features/tasks/tasks_screen.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/appointments_provider.dart';
import 'package:workloop/shared/providers/clients_provider.dart';
import 'package:workloop/shared/providers/tasks_provider.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';

void main() {
  testWidgets(
    'client overview reports provider failure instead of trustworthy-looking zeroes',
    (tester) async {
      final sourceError = StateError('offline');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientAppointmentsProvider.overrideWith(
              (ref, clientId) async => throw sourceError,
            ),
            clientPaymentsProvider.overrideWith(
              (ref, clientId) async => throw sourceError,
            ),
            clientTasksProvider.overrideWith(
              (ref, clientId) async => throw sourceError,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClientOverviewTab(
                clientId: 'client-1',
                client: const {'name': 'Launch Client'},
                onEdit: () {},
                onOpenBookings: () {},
                onOpenPayments: () {},
                onOpenTasks: () {},
                onOpenAddress: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Some client activity could not be loaded. Try again before relying on this overview.',
        ),
        findsOneWidget,
      );
      expect(find.text('Nothing booked yet'), findsNothing);
      expect(find.text('Jobs completed'), findsNothing);
      expect(find.text('Recent activity'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    },
  );

  testWidgets('calendar month navigation is labelled and thumb sized', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith((ref) async => const []),
          bookingRequestsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: AppointmentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Show calendar'));
    await tester.pumpAndSettle();

    final previous = find.byTooltip('Previous month');
    final next = find.byTooltip('Next month');
    expect(previous, findsOneWidget);
    expect(next, findsOneWidget);
    expect(find.bySemanticsLabel('Previous month'), findsOneWidget);
    expect(find.bySemanticsLabel('Next month'), findsOneWidget);
    expect(tester.getSize(previous).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(previous).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(next).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(next).height, greaterThanOrEqualTo(44));
  });

  testWidgets('checklist removal is labelled and thumb sized', (tester) async {
    const task = SlateTask(
      id: 'task-1',
      workspaceId: 'workspace-1',
      title: 'Launch checklist',
    );
    const item = TaskChecklistItem(
      id: 'item-1',
      workspaceId: 'workspace-1',
      taskId: 'task-1',
      title: 'Test iOS',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allTasksProvider.overrideWith((ref) async => const [task]),
          clientsProvider.overrideWith((ref) async => const []),
          taskChecklistProvider.overrideWith(
            (ref, taskId) async => const [item],
          ),
        ],
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Launch checklist'));
    await tester.pumpAndSettle();

    final remove = find.byTooltip('Remove Test iOS from checklist');
    expect(remove, findsOneWidget);
    expect(
      find.bySemanticsLabel('Remove Test iOS from checklist'),
      findsOneWidget,
    );
    expect(tester.getSize(remove).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));
  });

  testWidgets('working-hours block removal is labelled and thumb sized', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsWorkspaceSettingsProvider.overrideWith(
            (ref) async => const {
              'working_hours': {
                'Monday': {
                  'enabled': true,
                  'blocks': [
                    {'start': '09:00', 'end': '12:00'},
                    {'start': '13:00', 'end': '17:00'},
                  ],
                },
              },
            },
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkingHoursEditor())),
      ),
    );
    await tester.pumpAndSettle();

    final remove = find.byTooltip('Remove Monday time block 1');
    expect(remove, findsOneWidget);
    expect(find.bySemanticsLabel('Remove Monday time block 1'), findsOneWidget);
    expect(tester.getSize(remove).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));
  });

  testWidgets('legacy pay-now flag is never advertised publicly', (
    tester,
  ) async {
    const preview = PublicProfile(
      profile: BusinessProfile(
        id: 'profile-1',
        workspaceId: 'workspace-1',
        handle: 'launch-studio',
        payNowEnabled: true,
      ),
      businessName: 'Launch Studio',
      workingHours: {},
      services: [],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PublicProfileScreen(
            handle: 'launch-studio',
            previewProfile: preview,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Launch Studio'), findsOneWidget);
    expect(find.text('Pay now available'), findsNothing);
  });

  test('legacy pay-now value round-trips without enabling the feature', () {
    const profile = BusinessProfile(
      id: 'profile-1',
      workspaceId: 'workspace-1',
      handle: 'launch-studio',
      payNowEnabled: true,
    );

    expect(profile.payNowEnabled, isFalse);
    expect(profile.toMap()['pay_now_enabled'], isTrue);
  });
}
