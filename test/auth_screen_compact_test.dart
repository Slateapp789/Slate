import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/auth/auth_screen.dart';

void main() {
  testWidgets('standard iPhone sign-in fits before the keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            devicePixelRatio: 1,
            padding: EdgeInsets.only(top: 47, bottom: 34),
            disableAnimations: true,
          ),
          child: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final authScroll = find.byKey(const ValueKey('auth-scroll'));
    final scrollable = find.descendant(
      of: authScroll,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    expect(position.maxScrollExtent, 0);
    expect(
      tester.getRect(find.widgetWithText(TextField, 'Email address')).top,
      lessThanOrEqualTo(240),
    );
    expect(find.byKey(const ValueKey('auth-apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-google')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-brand-icon')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('auth-brand-panel'))).height,
      lessThanOrEqualTo(128),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('auth-google'))).bottom,
      lessThanOrEqualTo(844),
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('small phone starts the sign-in form near the top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(375, 667),
            padding: EdgeInsets.only(top: 20, bottom: 0),
            disableAnimations: true,
          ),
          child: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.widgetWithText(TextField, 'Email address')).top,
      lessThanOrEqualTo(240),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in remains scrollable when the keyboard reduces height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            devicePixelRatio: 1,
            viewInsets: EdgeInsets.only(bottom: 320),
            disableAnimations: true,
          ),
          child: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-scroll')), findsOneWidget);
    await tester.ensureVisible(find.text('Forgot password?'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in remains scrollable at large accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            devicePixelRatio: 1,
            padding: EdgeInsets.only(top: 47, bottom: 34),
            textScaler: TextScaler.linear(1.8),
            disableAnimations: true,
          ),
          child: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('auth-scroll')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.ensureVisible(find.byKey(const ValueKey('auth-google')));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
