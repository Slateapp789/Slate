import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/public_profile/booking_requests_screen.dart';
import 'package:workloop/features/public_profile/public_profile_screen.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';

const _profile = PublicProfile(
  profile: BusinessProfile(
    id: 'profile-1',
    workspaceId: 'workspace-1',
    handle: 'bright-studio',
  ),
  businessName: 'Bright Studio',
  workingHours: {
    'Sun': {'enabled': false},
    'Tue': {'enabled': true, 'open': '10:00', 'close': '18:00'},
    'Mon': {'enabled': true, 'open': '09:00', 'close': '17:00'},
  },
  services: [
    Service(
      id: 'service-1',
      workspaceId: 'workspace-1',
      name: 'Launch consultation',
      durationMins: 60,
      price: 49.99,
    ),
  ],
);

void main() {
  testWidgets(
    'public profile keeps exact prices and shows only published opening days',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PublicProfileScreen(
              handle: 'bright-studio',
              previewProfile: _profile,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('£49.99'), findsOneWidget);
      expect(find.text('£50'), findsNothing);

      expect(find.text('Wednesday'), findsNothing);
      expect(find.text('Closed on other days'), findsOneWidget);
      final dayPositions = [
        for (final day in const ['Monday', 'Tuesday'])
          tester.getTopLeft(find.text(day)).dy,
      ];
      expect(dayPositions, orderedEquals([...dayPositions]..sort()));
    },
  );

  testWidgets(
    'public booking shortcuts are labelled, thumb sized, and enter their value',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PublicProfileScreen(
              handle: 'bright-studio',
              previewProfile: _profile,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('This week'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final shortcut = find.bySemanticsLabel('This week');
      expect(shortcut, findsOneWidget);
      expect(tester.getSize(shortcut).height, greaterThanOrEqualTo(44));

      await tester.tap(shortcut);
      await tester.pump();
      final preferredField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Preferred day or time',
      );
      expect(
        tester.widget<TextField>(preferredField).controller!.text,
        'This week',
      );

      semantics.dispose();
    },
  );

  testWidgets('public request form uses persistent labels and inline errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PublicProfileScreen(
            handle: 'bright-studio',
            previewProfile: _profile,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Send request'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final name = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'Name',
    );
    final phone = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Phone',
    );
    expect(name, findsOneWidget);
    expect(phone, findsOneWidget);

    await tester.tap(find.text('Send request'));
    await tester.pump();

    expect(find.text('Add your name'), findsOneWidget);
    expect(find.text('Add a phone number'), findsOneWidget);
  });

  testWidgets('empty service copy describes the current state honestly', (
    tester,
  ) async {
    const emptyProfile = PublicProfile(
      profile: BusinessProfile(
        id: 'profile-2',
        workspaceId: 'workspace-1',
        handle: 'empty-studio',
      ),
      businessName: 'Empty Studio',
      workingHours: {},
      services: [],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PublicProfileScreen(
            handle: 'empty-studio',
            previewProfile: emptyProfile,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No services are currently listed.'), findsOneWidget);
    expect(find.text('Services will appear here soon.'), findsNothing);
  });

  testWidgets('booking request Call action is labelled and 44 points tall', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const request = BookingRequest(
      id: 'request-1',
      workspaceId: 'workspace-1',
      name: 'Alex Smith',
      phone: '07123 456789',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingRequestsProvider.overrideWith((ref) async => const [request]),
        ],
        child: const MaterialApp(home: BookingRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alex Smith'));
    await tester.pumpAndSettle();

    final call = find.bySemanticsLabel('Call Alex Smith');
    expect(call, findsOneWidget);
    expect(tester.getSize(call).height, greaterThanOrEqualTo(44));

    semantics.dispose();
  });
}
