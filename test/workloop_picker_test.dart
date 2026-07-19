import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  testWidgets('Workloop picker opens a searchable sheet and selects a row', (
    tester,
  ) async {
    String? selected;
    final options = List.generate(
      10,
      (index) => WorkloopPickerOption(
        value: 'client-$index',
        label: index == 8 ? 'Maya Lewis' : 'Client $index',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkloopPickerField<String>(
            value: selected,
            title: 'Choose a client',
            hint: 'Select client',
            options: options,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Select client'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a client'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Maya');
    await tester.pumpAndSettle();

    expect(find.text('Maya Lewis'), findsOneWidget);
    expect(find.text('Client 1'), findsNothing);

    await tester.tap(find.text('Maya Lewis'));
    await tester.pumpAndSettle();

    expect(selected, 'client-8');
    expect(find.text('Choose a client'), findsNothing);
  });

  testWidgets('short picker lists omit search and show selection state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkloopPickerField<String>(
            value: 'weekly',
            title: 'Repeat booking',
            hint: 'Choose repeat schedule',
            options: const [
              WorkloopPickerOption(value: 'none', label: "Doesn't repeat"),
              WorkloopPickerOption(value: 'weekly', label: 'Weekly'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
  });
}
