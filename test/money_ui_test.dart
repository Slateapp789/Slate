import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/finance/widgets/money_editor_widgets.dart';
import 'package:workloop/features/finance/widgets/money_summary_widgets.dart';
import 'package:workloop/shared/providers/finance_provider.dart';

void main() {
  testWidgets('Money overview keeps received as the single primary figure', (
    tester,
  ) async {
    const summary = PeriodMoneySummary(
      label: 'This month',
      paid: 120,
      unpaid: 40,
      overdue: 10,
      expenses: 35,
      categoryTotals: {'Materials': 35},
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: MoneySnapshot(summary: summary),
          ),
        ),
      ),
    );

    expect(find.text('Received'), findsOneWidget);
    expect(find.text('£120'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('£35'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('£85'), findsOneWidget);
    expect(find.text('To collect'), findsNothing);
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
