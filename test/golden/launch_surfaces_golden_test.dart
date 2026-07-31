import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/appointments/appointments_screen.dart';
import 'package:workloop/features/auth/auth_screen.dart';
import 'package:workloop/features/business_feed/business_feed_screen.dart';
import 'package:workloop/features/clients/add_client_screen.dart';
import 'package:workloop/features/clients/clients_screen.dart';
import 'package:workloop/features/dashboard/dashboard_screen.dart';
import 'package:workloop/features/finance/finance_screen.dart';
import 'package:workloop/features/more/more_screen.dart';
import 'package:workloop/features/notes/notes_screen.dart';
import 'package:workloop/features/public_profile/booking_requests_screen.dart';
import 'package:workloop/features/public_profile/public_profile_screen.dart';
import 'package:workloop/features/settings/settings_screen.dart';
import 'package:workloop/features/tasks/tasks_screen.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/appointments_provider.dart';
import 'package:workloop/shared/providers/business_feed_provider.dart';
import 'package:workloop/shared/providers/clients_provider.dart';
import 'package:workloop/shared/providers/dashboard_provider.dart';
import 'package:workloop/shared/providers/finance_provider.dart';
import 'package:workloop/shared/providers/notes_provider.dart';
import 'package:workloop/shared/providers/setup_checklist_provider.dart';
import 'package:workloop/shared/providers/tasks_provider.dart';
import 'package:workloop/shared/providers/workspace_provider.dart';
import 'package:workloop/shared/providers/workspace_settings_provider.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';

void main() {
  setUpAll(_loadDeterministicFonts);

  testWidgets('authentication login surface', (tester) async {
    await _pumpSurface(tester, const AuthScreen());

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/auth-login.png'),
    );
  });

  testWidgets('authentication registration surface', (tester) async {
    await _pumpSurface(tester, const AuthScreen());
    await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/auth-register.png'),
    );
  });

  testWidgets('populated client list surface', (tester) async {
    const client = Client(
      id: 'client-1',
      workspaceId: 'workspace-1',
      name: 'A very long customer name used to verify wrapping',
      phone: '+44 7700 900123',
      email: 'quality.fixture.with.a.long.address@example.invalid',
      tags: ['Regular', 'Priority'],
    );
    const record = ClientCrmRecord(
      client: client,
      bookingCount: 8,
      completedBookingCount: 6,
      nextBooking: null,
      lastBooking: null,
      lifetimeValue: 1249.99,
      outstandingBalance: 49.99,
      openTaskCount: 2,
      overdueTaskCount: 1,
    );
    await _pumpSurface(
      tester,
      const ClientsScreen(),
      overrides: [
        clientCrmRecordsProvider.overrideWith((ref) async => const [record]),
      ],
    );

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/clients-populated.png'),
    );
  });

  testWidgets('dashboard daily focus surface', (tester) async {
    final now = DateTime(2026, 7, 30, 9);
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
      monthlyTarget: 5000,
      now: now,
    );

    await _pumpSurface(
      tester,
      DashboardScreen(onNavigate: (_) {}, onOpenMoneyFollowUps: () {}),
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        dashboardClockProvider.overrideWith((ref) => Stream.value(now)),
        workspaceProvider.overrideWith(
          (ref) async => const {'id': 'workspace-1'},
        ),
        setupChecklistDismissedProvider.overrideWith((ref) async => true),
        clientsProvider.overrideWith((ref) async => const []),
        appointmentsProvider.overrideWith(
          (ref) async => [
            {
              'id': 'appointment-focus',
              'workspace_id': 'workspace-1',
              'start_time': DateTime(2026, 7, 30, 10).toIso8601String(),
              'end_time': DateTime(2026, 7, 30, 11).toIso8601String(),
              'status': 'scheduled',
              'contacts': {'name': 'Maya Johnson'},
              'services': {'name': 'Signature appointment'},
            },
          ],
        ),
        invoicesProvider.overrideWith((ref) async => const []),
        financeSummaryProvider.overrideWith((ref) async => summary),
        dashboardAttentionProvider.overrideWith((ref) async => const []),
        allTasksProvider.overrideWith((ref) async => const []),
        allNotesProvider.overrideWith((ref) async => const []),
        businessFeedProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(find.semantics.byLabel('Open profile'), findsOneWidget);
    expect(find.semantics.byLabel('Open settings'), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/dashboard-focus.png'),
    );
  });

  testWidgets('populated booking schedule surface', (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 10);
    await _pumpSurface(
      tester,
      const AppointmentsScreen(),
      overrides: [
        appointmentsProvider.overrideWith(
          (ref) async => [
            {
              'id': 'appointment-1',
              'workspace_id': 'workspace-1',
              'contact_id': 'client-1',
              'service_id': 'service-1',
              'title': 'Signature consultation',
              'start_time': start.toIso8601String(),
              'end_time': start
                  .add(const Duration(minutes: 75))
                  .toIso8601String(),
              'status': 'scheduled',
              'price': 149.99,
              'contacts': {'name': 'Samira Khan'},
              'services': {'name': 'Signature consultation'},
            },
          ],
        ),
        bookingRequestsProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(find.textContaining('£149.99'), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/bookings-populated.png'),
    );
  });

  testWidgets('empty money surface', (tester) async {
    final summary = FinanceSummary.from(
      payments: const [],
      expenses: const [],
      monthlyTarget: 5000,
      now: DateTime(2026, 7, 26),
    );
    await _pumpSurface(
      tester,
      const FinanceScreen(),
      overrides: [
        invoicesProvider.overrideWith((ref) async => const []),
        expensesProvider.overrideWith((ref) async => const []),
        financeSummaryProvider.overrideWith((ref) async => summary),
        workspaceSettingsProvider.overrideWith(
          (ref) async => const {'revenue_target': 5000},
        ),
      ],
    );

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/money-empty.png'),
    );
  });

  testWidgets('Tools workspace hierarchy surface', (tester) async {
    await _pumpSurface(
      tester,
      MoreScreen(onOpenMoney: () {}, onOpenTasks: () {}, onOpenNotes: () {}),
    );

    expect(find.text('Business tools'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/more-workspaces.png'),
    );
  });

  testWidgets('empty work surfaces', (tester) async {
    final cases = <String, Widget>{
      'tasks-empty': const TasksScreen(),
      'notes-empty': const NotesScreen(showBackButton: false),
      'feed-empty': const BusinessFeedScreen(),
    };
    for (final entry in cases.entries) {
      await _pumpSurface(
        tester,
        entry.value,
        overrides: [
          allTasksProvider.overrideWith((ref) async => const []),
          allNotesProvider.overrideWith((ref) async => const []),
          businessFeedProvider.overrideWith((ref) async => const []),
        ],
      );

      await expectLater(
        find.byKey(const ValueKey('golden-surface')),
        matchesGoldenFile('files/${entry.key}.png'),
      );
    }
  });

  testWidgets('booking request inbox empty surface', (tester) async {
    await _pumpSurface(
      tester,
      const BookingRequestsScreen(),
      overrides: [
        bookingRequestsProvider.overrideWith((ref) async => const []),
      ],
    );

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/booking-requests-empty.png'),
    );
  });

  testWidgets('settings dark-only surface', (tester) async {
    final authRepository = AuthRepository(
      SupabaseClient(
        'https://example.supabase.co',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    );
    await _pumpSurface(
      tester,
      const SettingsScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/settings-dark-only.png'),
    );
  });

  testWidgets('new client form surface', (tester) async {
    await _pumpSurface(tester, const AddClientScreen());

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/client-form.png'),
    );
  });

  testWidgets('public booking profile surface', (tester) async {
    const preview = PublicProfile(
      profile: BusinessProfile(
        id: 'profile-1',
        workspaceId: 'workspace-1',
        handle: 'quality-studio',
        bio: 'Calm, expert help for your next project.',
        bookingMode: 'manual',
      ),
      businessName: 'Quality Studio',
      workingHours: {
        'Monday': {
          'enabled': true,
          'blocks': [
            {'start': '09:00', 'end': '17:00'},
          ],
        },
      },
      services: [
        Service(
          id: 'service-1',
          workspaceId: 'workspace-1',
          name: 'Signature consultation',
          durationMins: 60,
          price: 49.99,
          description: 'A focused session with a clear next-step plan.',
        ),
      ],
    );
    await _pumpSurface(
      tester,
      const PublicProfileScreen(
        handle: 'quality-studio',
        previewProfile: preview,
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('golden-surface')),
      matchesGoldenFile('files/public-booking-profile.png'),
    );
  });
}

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  ThemeData? theme,
}) async {
  final resolvedTheme = theme ?? AppTheme.dark;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: resolvedTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            devicePixelRatio: 1,
            padding: EdgeInsets.only(top: 47, bottom: 34),
            disableAnimations: true,
          ),
          child: RepaintBoundary(
            key: const ValueKey('golden-surface'),
            child: screen,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _loadDeterministicFonts() async {
  final instrumentSans = FontLoader('Instrument Sans')
    ..addFont(rootBundle.load('assets/fonts/InstrumentSans-Variable.ttf'));
  // Flutter's test binding uses the block-glyph Ahem font for any style that
  // relies on a platform fallback. Map that fallback to Workloop's bundled
  // typeface so golden images represent the shipped UI rather than test boxes.
  final platformFallback = FontLoader('Ahem')
    ..addFont(rootBundle.load('assets/fonts/InstrumentSans-Variable.ttf'));
  final lucide = FontLoader('packages/lucide_flutter/LucideIcons')
    ..addFont(rootBundle.load('packages/lucide_flutter/assets/lucide.ttf'));
  await Future.wait([
    instrumentSans.load(),
    platformFallback.load(),
    lucide.load(),
  ]);
}
