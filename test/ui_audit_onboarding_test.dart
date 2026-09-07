import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Test-only in-memory backend for SharedPreferencesAsync.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/onboarding/screens/ob_first_booking.dart';
import 'package:workloop/features/onboarding/screens/ob_hours.dart';
import 'package:workloop/features/onboarding/screens/ob_revenue_target.dart';
import 'package:workloop/features/onboarding/screens/ob_services.dart';
import 'package:workloop/features/onboarding/screens/ob_welcome.dart';

Future<void> _pumpOnboardingScreen(WidgetTester tester, Widget screen) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'welcome explains the operating loop on a compact large-text phone',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpOnboardingScreen(tester, ObWelcome(onNext: () {}));

      expect(
        find.bySemanticsLabel(
          'Workloop operating loop: client, booking, work, payment, repeat.',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('Get started'), 160);
      expect(find.text('Get started'), findsOneWidget);
      expect(tester.takeException(), isNull);

      semantics.dispose();
    },
  );

  testWidgets('working hours remain usable on a small phone at large text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboardingScreen(tester, ObHours(onNext: () {}, onBack: () {}));

    expect(tester.takeException(), isNull);
    final openingTime = find.bySemanticsLabel('Monday opening time');
    final closingTime = find.bySemanticsLabel('Monday closing time');
    expect(openingTime, findsOneWidget);
    expect(closingTime, findsOneWidget);
    expect(tester.getSize(openingTime).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(closingTime).height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel('Sunday working day'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('service removal and skip controls expose full-size targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboardingScreen(
      tester,
      ObServices(onNext: () {}, onBack: () {}),
    );

    expect(tester.takeException(), isNull);
    final remove = find.bySemanticsLabel('Remove Consultation');
    expect(remove, findsOneWidget);
    expect(tester.getSize(remove).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));

    await tester.scrollUntilVisible(
      find.text('Skip — add services later'),
      120,
    );
    final skip = find.widgetWithText(TextButton, 'Skip — add services later');
    expect(tester.getSize(skip).height, greaterThanOrEqualTo(44));

    semantics.dispose();
  });

  testWidgets('service editor scrolls and stacks fields on a compact phone', (
    tester,
  ) async {
    await _pumpOnboardingScreen(
      tester,
      ObServices(onNext: () {}, onBack: () {}),
    );

    final add = find.widgetWithText(OutlinedButton, 'Add a service');
    await tester.scrollUntilVisible(add, 140);
    await tester.tap(add);
    await tester.pumpAndSettle();

    expect(find.text('Add your service'), findsOneWidget);
    final hours = find.widgetWithText(TextField, 'Hours');
    final minutes = find.widgetWithText(TextField, 'Minutes');
    expect(hours, findsOneWidget);
    expect(minutes, findsOneWidget);
    expect(
      tester.getTopLeft(hours).dx,
      closeTo(tester.getTopLeft(minutes).dx, 1),
    );
    await tester.ensureVisible(find.widgetWithText(TextField, 'Price'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-booking date and time fields are labelled and resilient', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboardingScreen(
      tester,
      ObFirstBooking(onNext: () {}, onBack: () {}),
    );

    expect(tester.takeException(), isNull);
    final date = find.bySemanticsLabel('Booking date');
    final time = find.bySemanticsLabel('Booking time');
    expect(date, findsOneWidget);
    expect(time, findsOneWidget);
    expect(tester.getSize(date).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(time).height, greaterThanOrEqualTo(44));
    expect(find.text('Add your first booking to get started.'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('revenue shortcuts remain full-size at large text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboardingScreen(
      tester,
      ObRevenueTarget(onNext: () {}, onBack: () {}),
    );

    expect(tester.takeException(), isNull);
    final target = find.bySemanticsLabel('£1000');
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(44));

    semantics.dispose();
  });
}
