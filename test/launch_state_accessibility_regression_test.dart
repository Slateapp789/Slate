import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/auth/auth_screen.dart';
import 'package:workloop/features/business_feed/business_feed_screen.dart';
import 'package:workloop/features/finance/widgets/money_editor_widgets.dart';
import 'package:workloop/features/notes/notes_screen.dart';
import 'package:workloop/features/tasks/tasks_screen.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/business_feed_provider.dart';
import 'package:workloop/shared/providers/notes_provider.dart';
import 'package:workloop/shared/providers/tasks_provider.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';

class _PasswordResetAuthRepository extends AuthRepository {
  _PasswordResetAuthRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int resetCalls = 0;

  @override
  Future<void> sendPasswordReset(String email) async {
    resetCalls += 1;
  }
}

void main() {
  testWidgets('Tasks initial load failure offers a working retry', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allTasksProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) throw StateError('offline');
            return const <SlateTask>[];
          }),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load tasks'), findsOneWidget);
    final retry = find.widgetWithText(TextButton, 'Try again');
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Could not load tasks'), findsNothing);
  });

  testWidgets('Business Feed initial load failure offers a working retry', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessFeedProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) throw StateError('offline');
            return const [];
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const BusinessFeedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load feed'), findsOneWidget);
    final retry = find.widgetWithText(TextButton, 'Try again');
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Could not load feed'), findsNothing);
  });

  testWidgets('Money amount focus border uses the theme accent ink', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: MoneyAmountField(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    final focusedBorder =
        field.decoration!.focusedBorder! as OutlineInputBorder;
    expect(focusedBorder.borderSide.color, WorkloopThemeTokens.dark.accentInk);
  });

  testWidgets('Note checklist marker is semantic, tappable and thumb sized', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const note = SlateNote(
      id: 'note-1',
      workspaceId: 'workspace-1',
      title: 'Release checklist',
      body: '○  Confirm app review',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allNotesProvider.overrideWith((ref) async => const [note]),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const NotesScreen(showBackButton: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Release checklist').first);
    await tester.pumpAndSettle();

    final marker = find.bySemanticsLabel('Mark checklist item complete');
    expect(marker, findsOneWidget);
    expect(tester.getSize(marker).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(marker).height, greaterThanOrEqualTo(44));

    await tester.tap(marker);
    await tester.pump();

    final editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.controller!.text, contains('✓  Confirm app review'));
    semantics.dispose();
  });

  testWidgets('Auth success feedback is announced as a live region', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = _PasswordResetAuthRepository();
    const message = 'Password reset email sent. Check your inbox.';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.dark, home: const AuthScreen()),
      ),
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'owner@example.com');
    await tester.tap(find.text('Send reset email'));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, 1);
    final success = find.bySemanticsLabel(message);
    expect(success, findsOneWidget);
    expect(tester.getSemantics(success).flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });
}
