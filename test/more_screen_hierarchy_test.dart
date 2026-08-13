import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/more/more_screen.dart';
import 'package:workloop/shared/providers/finance_provider.dart';
import 'package:workloop/shared/providers/notes_provider.dart';
import 'package:workloop/shared/providers/tasks_provider.dart';

void main() {
  testWidgets('core workspaces lead the page and remain directly actionable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var moneyOpens = 0;
    var taskOpens = 0;
    var noteOpens = 0;
    var moneyCreates = 0;
    var taskCreates = 0;
    var noteCreates = 0;
    var bookingPageOpens = 0;
    var profileOpens = 0;
    var settingsOpens = 0;

    await _pumpMoreScreen(
      tester,
      onOpenMoney: () => moneyOpens++,
      onOpenTasks: () => taskOpens++,
      onOpenNotes: () => noteOpens++,
      onCreateMoney: () => moneyCreates++,
      onCreateTask: () => taskCreates++,
      onCreateNote: () => noteCreates++,
      onOpenBookingPage: () => bookingPageOpens++,
      onOpenProfile: () => profileOpens++,
      onOpenSettings: () => settingsOpens++,
    );

    expect(find.text('Quick capture'), findsOneWidget);
    expect(find.text('Business tools'), findsOneWidget);
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

    final quickMoney = find.byKey(const ValueKey('tools-quick-money'));
    final quickTask = find.byKey(const ValueKey('tools-quick-task'));
    final quickNote = find.byKey(const ValueKey('tools-quick-note'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(quickMoney);
    await tester.tap(quickTask);
    await tester.tap(quickNote);
    await tester.pump();

    expect(moneyCreates, 1);
    expect(taskCreates, 1);
    expect(noteCreates, 1);

    await tester.scrollUntilVisible(find.text('Business setup'), 220);
    expect(find.text('Business setup'), findsOneWidget);
    expect(find.text('Booking page'), findsOneWidget);
    expect(find.text('Business profile'), findsOneWidget);
    await tester.tap(find.text('Booking page'));
    await tester.tap(find.text('Business profile'));
    await tester.scrollUntilVisible(find.text('Settings'), 220);
    await tester.ensureVisible(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Account & app'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(bookingPageOpens, 1);
    expect(profileOpens, 1);
    expect(settingsOpens, 1);

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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('more-workspace-money')),
      120,
    );
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
  VoidCallback? onCreateMoney,
  VoidCallback? onCreateTask,
  VoidCallback? onCreateNote,
  VoidCallback? onOpenBookingPage,
  VoidCallback? onOpenProfile,
  VoidCallback? onOpenSettings,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        invoicesProvider.overrideWith((ref) async => const []),
        allTasksProvider.overrideWith((ref) async => const []),
        allNotesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
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
            onCreateMoney: onCreateMoney,
            onCreateTask: onCreateTask,
            onCreateNote: onCreateNote,
            onOpenBookingPage: onOpenBookingPage,
            onOpenProfile: onOpenProfile,
            onOpenSettings: onOpenSettings,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
