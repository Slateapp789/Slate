import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/finance/finance_screen.dart';
import 'package:workloop/features/finance/widgets/money_editor_widgets.dart';
import 'package:workloop/features/finance/widgets/money_summary_widgets.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  testWidgets('Money navigation exposes three clear sections', (tester) async {
    MoneySection selected = MoneySection.income;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: WorkloopNavigationControl<MoneySection>(
              selected: selected,
              segments: const [
                WorkloopSegment(value: MoneySection.income, label: 'Income'),
                WorkloopSegment(
                  value: MoneySection.outgoing,
                  label: 'Outgoing',
                ),
                WorkloopSegment(
                  value: MoneySection.outstanding,
                  label: 'Outstanding',
                ),
              ],
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Outgoing'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);

    await tester.tap(find.text('Outstanding'));
    await tester.pumpAndSettle();
    expect(selected, MoneySection.outstanding);
  });

  testWidgets('Money period selector uses the shared segmented interaction', (
    tester,
  ) async {
    FinancePeriod selected = FinancePeriod.week;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: MoneyPeriodSwitcher(
              selected: selected,
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(selected, FinancePeriod.month);
  });

  testWidgets('Money amount field uses one stable mobile input', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MoneyAmountField(controller: controller)),
      ),
    );

    await tester.enterText(find.byType(TextField), '48.50');
    expect(controller.text, '48.50');
    expect(find.text('£ '), findsOneWidget);
  });
}
