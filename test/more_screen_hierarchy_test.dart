import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/more/more_screen.dart';

void main() {
  testWidgets('core workspaces lead the page and remain directly actionable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var moneyOpens = 0;
    var taskOpens = 0;
    var noteOpens = 0;

    await _pumpMoreScreen(
      tester,
      onOpenMoney: () => moneyOpens++,
      onOpenTasks: () => taskOpens++,
      onOpenNotes: () => noteOpens++,
    );

    expect(find.text('Business tools'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    final moneySemantics = find.semantics.byLabel('Open Money workspace');
    final tasksSemantics = find.semantics.byLabel('Open Tasks workspace');
    final notesSemantics = find.semantics.byLabel('Open Notes workspace');

    expect(moneySemantics, findsOne);
    expect(tasksSemantics, findsOne);
    expect(notesSemantics, findsOne);
    expect(
      moneySemantics.evaluate().single.getSemanticsData().hasAction(
        SemanticsAction.tap,
      ),
      isTrue,
    );
    expect(
      tasksSemantics.evaluate().single.getSemanticsData().hasAction(
        SemanticsAction.tap,
      ),
      isTrue,
    );
    expect(
      notesSemantics.evaluate().single.getSemanticsData().hasAction(
        SemanticsAction.tap,
      ),
      isTrue,
    );

    final moneyRect = tester.getRect(
      find.byKey(const ValueKey('more-workspace-money')),
    );
    final tasksRect = tester.getRect(
      find.byKey(const ValueKey('more-workspace-tasks')),
    );
    final notesRect = tester.getRect(
      find.byKey(const ValueKey('more-workspace-notes')),
    );

    expect(moneyRect.top, lessThan(tasksRect.top));
    expect(tasksRect.bottom, lessThanOrEqualTo(notesRect.top));
    expect(moneyRect.height, greaterThanOrEqualTo(44));
    expect(moneyRect.width, tasksRect.width);
    expect(tasksRect.width, notesRect.width);

    tester.semantics.tap(moneySemantics);
    tester.semantics.tap(tasksSemantics);
    tester.semantics.tap(notesSemantics);
    await tester.pump();

    expect(moneyOpens, 1);
    expect(taskOpens, 1);
    expect(noteOpens, 1);

    semantics.dispose();
  });

  testWidgets('workspace tray remains usable on a small phone at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMoreScreen(
      tester,
      textScaler: const TextScaler.linear(2),
      onOpenMoney: () {},
      onOpenTasks: () {},
      onOpenNotes: () {},
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('more-workspace-money'))).height,
      greaterThanOrEqualTo(44),
    );
  });
}

Future<void> _pumpMoreScreen(
  WidgetTester tester, {
  required VoidCallback onOpenMoney,
  required VoidCallback onOpenTasks,
  required VoidCallback onOpenNotes,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize / tester.view.devicePixelRatio,
          devicePixelRatio: tester.view.devicePixelRatio,
          textScaler: textScaler,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: MoreScreen(
          onOpenMoney: onOpenMoney,
          onOpenTasks: onOpenTasks,
          onOpenNotes: onOpenNotes,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
