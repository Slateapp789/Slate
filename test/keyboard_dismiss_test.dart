import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  testWidgets('tap outside an editable field dismisses its focus', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: WorkloopKeyboardDismissRegion(
          child: Scaffold(
            body: Column(
              children: [
                TextField(key: const Key('field'), focusNode: focusNode),
                Container(
                  key: const Key('outside'),
                  height: 80,
                  width: 160,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('tap inside the active field keeps its focus', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: WorkloopKeyboardDismissRegion(
          child: Scaffold(
            body: TextField(key: const Key('field'), focusNode: focusNode),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
  });
}
