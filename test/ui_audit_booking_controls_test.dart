import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/appointments/add_appointment_screen.dart';
import 'package:workloop/shared/providers/appointments_provider.dart';
import 'package:workloop/shared/providers/clients_provider.dart';
import 'package:workloop/shared/providers/workspace_settings_provider.dart';

void main() {
  testWidgets(
    'new-booking controls remain labelled and thumb sized on a small phone',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) async => const []),
            servicesProvider.overrideWith(
              (ref) async => const [
                {
                  'id': 'service-1',
                  'name': 'Consultation',
                  'duration_mins': 60,
                  'price': 49.99,
                },
              ],
            ),
            workspaceSettingsProvider.overrideWith((ref) async => null),
            appointmentsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const AddAppointmentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Booking date'),
        220,
        scrollable: scrollable,
      );
      await tester.pump();

      final date = find.bySemanticsLabel('Booking date');
      expect(date, findsOneWidget);
      expect(tester.getSize(date).height, greaterThanOrEqualTo(44));

      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Booking start time'),
        180,
        scrollable: scrollable,
      );
      await tester.pump();

      final time = find.bySemanticsLabel('Booking start time');
      final duration = find.bySemanticsLabel('30m');
      expect(tester.getSize(time).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(duration).height, greaterThanOrEqualTo(44));

      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Business'),
        180,
        scrollable: scrollable,
      );
      await tester.pump();
      expect(
        tester.getSize(find.bySemanticsLabel('Business')).height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);

      semantics.dispose();
    },
  );

  testWidgets('new-booking client load failure can recover in place', (
    tester,
  ) async {
    var clientLoads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientsProvider.overrideWith((ref) async {
            clientLoads += 1;
            if (clientLoads == 1) throw StateError('offline');
            return const [];
          }),
          servicesProvider.overrideWith((ref) async => const []),
          workspaceSettingsProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AddAppointmentScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load clients'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(clientLoads, 2);
    expect(find.text('Could not load clients'), findsNothing);
  });

  testWidgets('new client contact fields stack at large text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientsProvider.overrideWith((ref) async => const []),
          servicesProvider.overrideWith((ref) async => const []),
          workspaceSettingsProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(2),
            ),
            child: AddAppointmentScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add new client'));
    await tester.pumpAndSettle();

    final phone = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Phone',
    );
    final email = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Email',
    );
    expect(phone, findsOneWidget);
    expect(email, findsOneWidget);
    expect(
      tester.getTopLeft(email).dy,
      greaterThan(tester.getBottomLeft(phone).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
