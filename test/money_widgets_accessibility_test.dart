import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/finance/widgets/money_summary_widgets.dart';
import 'package:workloop/features/finance/widgets/payment_cards.dart';
import 'package:workloop/shared/models/slate_models.dart';

void main() {
  testWidgets('Money mode choices are semantic thumb-sized controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var selected = 'monthly';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ModePills(
              selected: selected,
              options: const {'monthly': 'Monthly', 'weekly': 'Weekly'},
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    final monthly = find.semantics.byLabel('Monthly');
    final weekly = find.semantics.byLabel('Weekly');
    expect(monthly, findsOne);
    expect(weekly, findsOne);
    expect(
      tester.getSize(find.byType(ModePills)).height,
      greaterThanOrEqualTo(AppSpacing.minTouch),
    );
    expect(
      monthly.evaluate().single.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );

    tester.semantics.tap(weekly);
    await tester.pumpAndSettle();

    expect(selected, 'weekly');
    expect(
      weekly.evaluate().single.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('date picker tile has a labelled semantic tap target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: DatePickTile(
            label: 'Start date',
            value: '5 Aug 2026',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    final tile = find.semantics.byLabel('Start date, 5 Aug 2026');
    expect(tile, findsOne);
    expect(
      tester.getSize(find.byType(DatePickTile)).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tile.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );

    tester.semantics.tap(tile);
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets(
    'payment card exposes primary and delete actions without long press',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var opens = 0;
      var deletes = 0;
      final payment = Payment(
        id: 'payment-1',
        workspaceId: 'workspace-1',
        number: 'PAY-001',
        status: 'paid',
        issueDate: DateTime(2026, 8, 5),
        incomeRecordedAt: DateTime(2026, 8, 5),
        total: 125,
        amountPaid: 125,
        clientName: 'Launch Client',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: PaymentCard(
              payment: payment,
              onTap: () => opens++,
              onDelete: () => deletes++,
            ),
          ),
        ),
      );

      final paymentAction = find.semantics.byLabel(
        'Launch Client payment, £125, Paid',
      );
      expect(paymentAction, findsOne);
      tester.semantics.tap(paymentAction);
      expect(opens, 1);

      final more = find.byTooltip('More payment actions');
      expect(more, findsOneWidget);
      expect(tester.getSize(more).height, greaterThanOrEqualTo(44));
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text('Delete income'), findsOneWidget);

      await tester.tap(find.text('Delete income'));
      await tester.pumpAndSettle();
      expect(deletes, 1);
      semantics.dispose();
    },
  );
}
