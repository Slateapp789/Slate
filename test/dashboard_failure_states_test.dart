import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/dashboard/dashboard_screen.dart';
import 'package:workloop/shared/models/business_feed_item.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/appointments_provider.dart';
import 'package:workloop/shared/providers/business_feed_provider.dart';
import 'package:workloop/shared/providers/clients_provider.dart';
import 'package:workloop/shared/providers/dashboard_provider.dart';
import 'package:workloop/shared/providers/finance_provider.dart';
import 'package:workloop/shared/providers/notes_provider.dart';
import 'package:workloop/shared/providers/notifications_provider.dart';
import 'package:workloop/shared/providers/setup_checklist_provider.dart';
import 'package:workloop/shared/providers/tasks_provider.dart';
import 'package:workloop/shared/providers/workspace_provider.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  testWidgets('dashboard summaries expose honest retryable failures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sourceError = StateError('offline');
    final authRepository = AuthRepository(
      SupabaseClient(
        'https://example.supabase.co',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          workspaceProvider.overrideWith(
            (ref) async => const {'id': 'workspace-1'},
          ),
          setupChecklistDismissedProvider.overrideWith((ref) async => true),
          dashboardClockProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 8, 5, 9)),
          ),
          appointmentsProvider.overrideWith((ref) async => throw sourceError),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          invoicesProvider.overrideWith((ref) async => const <Payment>[]),
          financeSummaryProvider.overrideWith((ref) async => throw sourceError),
          dashboardAttentionProvider.overrideWith(
            (ref) async => const <DashboardAttentionItem>[],
          ),
          allTasksProvider.overrideWith((ref) async => const <SlateTask>[]),
          allNotesProvider.overrideWith((ref) async => const <SlateNote>[]),
          businessFeedProvider.overrideWith((ref) async => throw sourceError),
          unreadNotificationsProvider.overrideWith((ref) async => 0),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DashboardScreen(
            onNavigate: (_) {},
            onOpenMoneyFollowUps: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your Money summary.'), findsOneWidget);
    expect(find.text('Could not load upcoming bookings'), findsOneWidget);
    expect(find.text('Could not load recent activity'), findsOneWidget);
    expect(find.text('Try again'), findsNWidgets(3));
    expect(find.text('Open Money'), findsNothing);
  });

  testWidgets('dashboard notification action announces unread count', (
    tester,
  ) async {
    final authRepository = AuthRepository(
      SupabaseClient(
        'https://example.supabase.co',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    );
    final summary = FinanceSummary.from(
      payments: const [],
      expenses: const [],
      monthlyTarget: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          workspaceProvider.overrideWith(
            (ref) async => const {'id': 'workspace-1'},
          ),
          setupChecklistDismissedProvider.overrideWith((ref) async => true),
          dashboardClockProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 8, 5, 9)),
          ),
          appointmentsProvider.overrideWith(
            (ref) async => const <Map<String, dynamic>>[],
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          invoicesProvider.overrideWith((ref) async => const <Payment>[]),
          financeSummaryProvider.overrideWith((ref) async => summary),
          dashboardAttentionProvider.overrideWith(
            (ref) async => const <DashboardAttentionItem>[],
          ),
          allTasksProvider.overrideWith((ref) async => const <SlateTask>[]),
          allNotesProvider.overrideWith((ref) async => const <SlateNote>[]),
          businessFeedProvider.overrideWith(
            (ref) async => const <BusinessFeedItem>[],
          ),
          unreadNotificationsProvider.overrideWith((ref) async => 3),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DashboardScreen(
            onNavigate: (_) {},
            onOpenMoneyFollowUps: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final notificationButton = tester.widget<WorkloopIconButton>(
      find.byType(WorkloopIconButton).first,
    );
    expect(notificationButton.semanticLabel, 'Open notifications, 3 unread');
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('today bookings can be browsed horizontally', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 8, 5, 8);
    final authRepository = AuthRepository(
      SupabaseClient(
        'https://example.supabase.co',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    );
    final summary = FinanceSummary.from(
      payments: const [],
      expenses: const [],
      monthlyTarget: 0,
      now: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          workspaceProvider.overrideWith(
            (ref) async => const {'id': 'workspace-1'},
          ),
          setupChecklistDismissedProvider.overrideWith((ref) async => true),
          dashboardClockProvider.overrideWith((ref) => Stream.value(now)),
          appointmentsProvider.overrideWith(
            (ref) async => [
              {
                'id': 'booking-1',
                'start_time': DateTime(2026, 8, 5, 9).toIso8601String(),
                'end_time': DateTime(2026, 8, 5, 9, 45).toIso8601String(),
                'status': 'scheduled',
                'contacts': {'name': 'Amina Cole'},
                'services': {'name': 'Studio clean'},
              },
              {
                'id': 'booking-2',
                'start_time': DateTime(2026, 8, 5, 10).toIso8601String(),
                'end_time': DateTime(2026, 8, 5, 10, 45).toIso8601String(),
                'status': 'scheduled',
                'contacts': {'name': 'Bruno Silva'},
                'services': {'name': 'Follow-up visit'},
              },
            ],
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          invoicesProvider.overrideWith((ref) async => const <Payment>[]),
          financeSummaryProvider.overrideWith((ref) async => summary),
          dashboardAttentionProvider.overrideWith(
            (ref) async => const <DashboardAttentionItem>[],
          ),
          allTasksProvider.overrideWith((ref) async => const <SlateTask>[]),
          allNotesProvider.overrideWith((ref) async => const <SlateNote>[]),
          businessFeedProvider.overrideWith(
            (ref) async => const <BusinessFeedItem>[],
          ),
          unreadNotificationsProvider.overrideWith((ref) async => 0),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DashboardScreen(
            onNavigate: (_) {},
            onOpenMoneyFollowUps: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final carousel = find.byKey(const ValueKey('today-booking-carousel'));
    expect(carousel, findsOneWidget);
    expect(find.text('Amina Cole').hitTestable(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('active-job-marker-0')).hitTestable(),
      findsOneWidget,
    );

    await tester.drag(carousel, const Offset(-280, 0));
    await tester.pumpAndSettle();

    expect(find.text('Bruno Silva').hitTestable(), findsOneWidget);
    expect(find.textContaining('2 OF 2').hitTestable(), findsOneWidget);
    expect(
      find.byKey(const ValueKey('active-job-marker-1')).hitTestable(),
      findsOneWidget,
    );
  });
}
