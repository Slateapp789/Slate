import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/appointments/appointments_screen.dart';
import 'package:workloop/features/public_profile/booking_requests_screen.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/appointments_provider.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  testWidgets('booking header controls fit a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith((ref) async => const []),
          bookingRequestsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: AppointmentsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Booking requests'), findsOneWidget);
    expect(find.bySemanticsLabel('Calendar'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
  });

  testWidgets('Bookings prioritises the schedule without a workload chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith((ref) async => const []),
          bookingRequestsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AppointmentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget is WorkloopNavigationControl),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is WorkloopSegmentedControl),
      findsNothing,
    );
    expect(find.text('List'), findsNothing);
    expect(find.bySemanticsLabel('Today'), findsOneWidget);
    expect(find.bySemanticsLabel('Booking requests'), findsOneWidget);
    expect(find.bySemanticsLabel('Calendar'), findsOneWidget);
    expect(find.text('Next 7 days'), findsNothing);
    expect(find.text('Schedule view'), findsNothing);
    expect(find.byKey(const ValueKey('booking-load-strip')), findsNothing);
    expect(find.text('Next booking'), findsNothing);
    expect(find.text('Nothing scheduled today'), findsOneWidget);
  });

  testWidgets('the counted request inbox opens the dedicated workspace', (
    tester,
  ) async {
    const request = BookingRequest(
      id: 'request-1',
      workspaceId: 'workspace-1',
      name: 'Alex Smith',
      phone: '07123 456789',
      serviceName: 'Window clean',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith((ref) async => const []),
          bookingRequestsProvider.overrideWith((ref) async => const [request]),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AppointmentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Booking requests, 1 active'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingRequestsScreen), findsOneWidget);
    expect(find.text('Booking requests'), findsOneWidget);
    expect(find.text('Alex Smith'), findsOneWidget);

    await tester.tap(find.text('Alex Smith'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingRequestDetailScreen), findsOneWidget);
    expect(find.text('Booking request'), findsOneWidget);
    expect(find.text('Alex Smith'), findsOneWidget);
  });

  testWidgets('calendar is month-led and opens the selected day agenda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final start = DateTime(2026, 8, 8, 10);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith(
            (ref) async => [
              {
                'id': 'booking-1',
                'title': 'Signature consultation',
                'start_time': start.toIso8601String(),
                'end_time': start
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
                'status': 'scheduled',
                'price': 120,
                'contacts': {'name': 'Maya Johnson'},
                'services': {'name': 'Signature consultation'},
              },
            ],
          ),
          bookingRequestsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: AppointmentsScreen(
            initialCalendarDate: DateTime(2026, 8, 8),
            calendarReferenceDate: DateTime(2026, 8, 8),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('August'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Next booking'), findsNothing);

    await tester.fling(find.byType(GridView), const Offset(-280, 0), 900);
    await tester.pumpAndSettle();

    expect(find.text('September'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('August'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('Maya Johnson'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(find.text('Add booking'), findsOneWidget);
  });

  testWidgets('Bookings initial load failure retries in place', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentsProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) throw StateError('offline');
            return const [];
          }),
          bookingRequestsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AppointmentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load bookings'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Nothing scheduled today'), findsOneWidget);
  });
}
