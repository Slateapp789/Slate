import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Test-only in-memory backend for SharedPreferencesAsync.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/onboarding/screens/ob_handle.dart';
import 'package:workloop/features/settings/widgets/settings_account_tab.dart';
import 'package:workloop/shared/providers/workspace_provider.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';
import 'package:workloop/shared/repositories/privacy_repository.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';

SupabaseClient _testClient() {
  return SupabaseClient(
    'https://example.supabase.co',
    'test-anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

class _SignedInAuthRepository extends AuthRepository {
  _SignedInAuthRepository() : super(_testClient());
  @override
  String? get currentUserId => 'owner-a';
  @override
  String get currentEmail => 'owner@example.com';
  @override
  Future<void> signOutLocal({String? expectedUserId}) async {}
}

class _RetryingPrivacyRepository extends PrivacyRepository {
  _RetryingPrivacyRepository({this.failFirstRequest = false})
    : super(_testClient());

  final bool failFirstRequest;
  final requestedWorkspaceIds = <String>[];

  @override
  Future<void> requestAccountDeletion({required String workspaceId}) async {
    requestedWorkspaceIds.add(workspaceId);
    if (failFirstRequest && requestedWorkspaceIds.length == 1) {
      throw StateError('offline');
    }
  }
}

class _RetryingProfileRepository extends ProfileRepository {
  _RetryingProfileRepository() : super(_testClient());

  final checkedHandles = <String>[];

  @override
  Future<bool> isHandleAvailable(String handle) async {
    checkedHandles.add(handle);
    if (checkedHandles.length == 1) {
      throw StateError('offline');
    }
    return true;
  }
}

void main() {
  Finder requestDeletionButton() {
    return find.widgetWithText(ElevatedButton, 'Request deletion');
  }

  Future<void> openDeletionSheet(
    WidgetTester tester, {
    required String? workspaceId,
    required PrivacyRepository repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedInAuthRepository()),
          workspaceIdProvider.overrideWith((ref) async => workspaceId),
          privacyRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: SettingsAccountTab(showDataOnly: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete account'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'DELETE');
    await tester.pump();

    expect(requestDeletionButton(), findsOneWidget);
  }

  testWidgets(
    'missing workspace explains the problem and restores deletion retry',
    (tester) async {
      final repository = _RetryingPrivacyRepository();
      await openDeletionSheet(
        tester,
        workspaceId: null,
        repository: repository,
      );

      await tester.tap(requestDeletionButton());
      await tester.pumpAndSettle();

      expect(repository.requestedWorkspaceIds, isEmpty);
      expect(
        find.text(
          'We couldn’t find your workspace. Reload Workloop and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Request account deletion'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<ElevatedButton>(requestDeletionButton()).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('failed deletion request can be retried from the same sheet', (
    tester,
  ) async {
    final repository = _RetryingPrivacyRepository(failFirstRequest: true);
    await openDeletionSheet(
      tester,
      workspaceId: 'workspace-1',
      repository: repository,
    );

    await tester.tap(requestDeletionButton());
    await tester.pumpAndSettle();

    expect(repository.requestedWorkspaceIds, ['workspace-1']);
    expect(
      find.text(
        'Your deletion request could not be confirmed. Please try again or contact support.',
      ),
      findsOneWidget,
    );
    expect(find.text('Request account deletion'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(requestDeletionButton()).onPressed,
      isNotNull,
    );

    await tester.tap(requestDeletionButton());
    await tester.pumpAndSettle();

    expect(repository.requestedWorkspaceIds, ['workspace-1', 'workspace-1']);
    expect(find.text('Request account deletion'), findsNothing);
  });

  testWidgets(
    'handle availability transient failure retries the unchanged handle',
    (tester) async {
      final semantics = tester.ensureSemantics();
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
      final repository = _RetryingProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: ObHandle(onNext: () {}, onBack: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'launch-studio');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      expect(repository.checkedHandles, ['launch-studio']);
      expect(
        find.text(
          'We couldn’t check that booking link. Check your connection and try again.',
        ),
        findsOneWidget,
      );

      final retryButton = find.byKey(const ValueKey('onboarding-handle-retry'));
      final retrySemantics = find.semantics.byLabel('Try again');
      expect(retryButton, findsOneWidget);
      expect(tester.getSize(retryButton).height, greaterThanOrEqualTo(44));
      expect(retrySemantics, findsOne);
      expect(
        retrySemantics.evaluate().single.getSemanticsData().hasAction(
          SemanticsAction.tap,
        ),
        isTrue,
      );

      tester.semantics.tap(retrySemantics);
      await tester.pump();
      await tester.pump();

      expect(repository.checkedHandles, ['launch-studio', 'launch-studio']);
      expect(find.text('Available'), findsOneWidget);
      expect(retryButton, findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Looks good'),
            )
            .onPressed,
        isNotNull,
      );
      semantics.dispose();
    },
  );
}
