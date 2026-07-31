import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/shared/utils/currency_format.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  test('currency display and edit values preserve pence', () {
    expect(currencyInputValue(49), '49');
    expect(currencyInputValue(49.5), '49.50');
    expect(currencyInputValue(49.99), '49.99');
    expect(formatPounds(49.99), '£49.99');
  });

  testWidgets('picker exposes its label, value, options, and clear action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => WorkloopPickerField<String>(
              value: selected,
              title: 'Choose service',
              hint: 'Select a service',
              searchable: true,
              options: List.generate(
                10,
                (index) => WorkloopPickerOption(
                  value: 'service-$index',
                  label: index == 0 ? 'Haircut' : 'Service $index',
                ),
              ),
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    final field = find.bySemanticsLabel('Choose service');
    expect(field, findsOneWidget);
    expect(tester.getSize(field).height, greaterThanOrEqualTo(44));

    await tester.tap(field);
    await tester.pumpAndSettle();

    final option = find.bySemanticsLabel('Haircut');
    expect(option, findsOneWidget);
    expect(tester.getSize(option).height, greaterThanOrEqualTo(44));

    await tester.enterText(find.byType(TextField), 'Hair');
    await tester.pump();
    final clear = find.byTooltip('Clear search');
    expect(clear, findsOneWidget);
    expect(tester.getSize(clear).height, greaterThanOrEqualTo(44));

    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(selected, 'service-0');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Choose service')).value,
      'Haircut',
    );

    semantics.dispose();
  });

  testWidgets('section actions and error recovery remain thumb sized', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var actionCount = 0;
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Column(
            children: [
              SlateSectionHeader(
                label: 'Bookings',
                actionLabel: 'See all',
                onAction: () => actionCount++,
              ),
              SlateErrorState(
                message: 'Could not load bookings.',
                onRetry: () => retryCount++,
              ),
            ],
          ),
        ),
      ),
    );

    final action = find.widgetWithText(TextButton, 'See all');
    final retry = find.widgetWithText(TextButton, 'Try again');
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));

    final errorSemantics = tester
        .getSemantics(find.bySemanticsLabel('Could not load bookings.'))
        .getSemanticsData();
    expect(errorSemantics.flagsCollection.isLiveRegion, isTrue);

    await tester.tap(action);
    await tester.tap(retry);
    expect(actionCount, 1);
    expect(retryCount, 1);

    semantics.dispose();
  });

  testWidgets('root action is labelled, primary, and thumb sized', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: WorkloopTopAction(label: 'New booking', onTap: () => taps++),
          ),
        ),
      ),
    );

    final action = find.bySemanticsLabel('New booking');
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, 48);
    expect(tester.getSize(action).width, greaterThan(48));

    await tester.tap(action);
    expect(taps, 1);
    semantics.dispose();
  });
}
