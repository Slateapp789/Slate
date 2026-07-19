import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('draft confirmation returns save and protects invalid drafts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WorkloopDraftDecision? decision;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                decision = await showWorkloopDraftConfirmation(
                  context,
                  title: 'Save booking changes?',
                  message: 'Save before leaving?',
                  canSave: false,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final disabledSave = tester.widget<SlateButton>(
      find.widgetWithText(SlateButton, 'Save changes'),
    );
    expect(disabledSave.onPressed, isNull);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(decision, WorkloopDraftDecision.stay);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(decision, WorkloopDraftDecision.discard);
  });

  testWidgets('outside-hours confirmation allows an intentional booking', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                confirmed = await showWorkloopOutsideHoursConfirmation(
                  context,
                  detail: 'This starts before your saved opening time.',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Outside working hours'), findsOneWidget);
    expect(
      find.textContaining('You can still create this booking.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Book anyway'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
