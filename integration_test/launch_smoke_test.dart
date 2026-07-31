import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workloop/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-out launch and auth navigation stay usable', (
    tester,
  ) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Sign in to your workspace.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Create your account.'), findsOneWidget);
    expect(
      find.text('Start running your business from one app.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password.'), findsOneWidget);
    expect(find.text('Send reset email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
