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
  testWidgets('Bookings reserves peer navigation for Schedule and Requests', (
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
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Show calendar'), findsOneWidget);
    expect(find.text('Next booking'), findsNothing);
    expect(find.text('Nothing scheduled today'), findsOneWidget);
  });

  testWidgets('a request row opens that request directly', (tester) async {
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

    await tester.tap(find.bySemanticsLabel('Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex Smith'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingRequestDetailScreen), findsOneWidget);
    expect(find.text('Booking request'), findsOneWidget);
    expect(find.text('Alex Smith'), findsOneWidget);
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
