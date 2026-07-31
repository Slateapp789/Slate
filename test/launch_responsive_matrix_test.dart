import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  testWidgets(
    'primary launch surfaces render across phone and text-scale matrix',
    (tester) async {
      final finance = FinanceSummary.from(
        payments: const [],
        expenses: const [],
        monthlyTarget: 5000,
        now: DateTime(2026, 7, 26),
      );
      final authRepository = AuthRepository(
        SupabaseClient(
          'https://example.supabase.co',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
      final devices = <_DeviceCase>[
        const _DeviceCase('small iPhone', Size(320, 568), TargetPlatform.iOS),
        const _DeviceCase(
          'standard iPhone',
          Size(390, 844),
          TargetPlatform.iOS,
        ),
        const _DeviceCase('large iPhone', Size(430, 932), TargetPlatform.iOS),
        const _DeviceCase(
          'small Android',
          Size(360, 640),
          TargetPlatform.android,
        ),
        const _DeviceCase(
          'standard Android',
          Size(412, 915),
          TargetPlatform.android,
        ),
        const _DeviceCase(
          'large Android',
          Size(480, 960),
          TargetPlatform.android,
        ),
      ];
      final surfaces = <_SurfaceCase>[
        _SurfaceCase('authentication', () => const AuthScreen()),
        _SurfaceCase(
          'dashboard',
          () =>
              DashboardScreen(onNavigate: (_) {}, onOpenMoneyFollowUps: () {}),
        ),
        _SurfaceCase('clients', () => const ClientsScreen()),
        _SurfaceCase('bookings', () => const AppointmentsScreen()),
        _SurfaceCase('money', () => const FinanceScreen()),
        _SurfaceCase(
          'more',
          () => MoreScreen(
            onOpenMoney: () {},
            onOpenTasks: () {},
            onOpenNotes: () {},
          ),
        ),
        _SurfaceCase('tasks', () => const TasksScreen()),
        _SurfaceCase('notes', () => const NotesScreen(showBackButton: false)),
        _SurfaceCase('business feed', () => const BusinessFeedScreen()),
        _SurfaceCase('booking requests', () => const BookingRequestsScreen()),
        _SurfaceCase('settings', () => const SettingsScreen()),
        _SurfaceCase(
          'public profile',
          () => const PublicProfileScreen(
            handle: 'quality-studio',
            previewProfile: _previewProfile,
          ),
        ),
      ];

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final device in devices) {
        tester.view.physicalSize = device.size;
        tester.view.devicePixelRatio = 1;
        for (final scale in const [1.0, 2.0]) {
          for (final surface in surfaces) {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  clientCrmRecordsProvider.overrideWith(
                    (ref) async => const [],
                  ),
                  workspaceProvider.overrideWith(
                    (ref) async => const {'id': 'workspace-1'},
                  ),
                  setupChecklistDismissedProvider.overrideWith(
                    (ref) async => true,
                  ),
                  dashboardClockProvider.overrideWith(
                    (ref) => Stream.value(DateTime(2026, 7, 30, 9)),
                  ),
                  dashboardAttentionProvider.overrideWith(
                    (ref) async => const [],
                  ),
                  clientsProvider.overrideWith((ref) async => const []),
                  appointmentsProvider.overrideWith((ref) async => const []),
                  bookingRequestsProvider.overrideWith((ref) async => const []),
                  invoicesProvider.overrideWith((ref) async => const []),
                  expensesProvider.overrideWith((ref) async => const []),
                  financeSummaryProvider.overrideWith((ref) async => finance),
                  workspaceSettingsProvider.overrideWith(
                    (ref) async => const {'revenue_target': 5000},
                  ),
                  allTasksProvider.overrideWith((ref) async => const []),
                  allNotesProvider.overrideWith((ref) async => const []),
                  businessFeedProvider.overrideWith((ref) async => const []),
                  authRepositoryProvider.overrideWithValue(authRepository),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.dark.copyWith(platform: device.platform),
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: device.size,
                      devicePixelRatio: 1,
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                      padding: device.platform == TargetPlatform.iOS
                          ? const EdgeInsets.only(top: 47, bottom: 34)
                          : const EdgeInsets.only(top: 24, bottom: 24),
                    ),
                    child: surface.builder(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason:
                  '${surface.name} failed on ${device.name} at ${scale}x text',
            );
          }
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets('client form remains reachable with keyboard and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 568),
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(1.6),
            viewInsets: EdgeInsets.only(bottom: 280),
            disableAnimations: true,
          ),
          child: AddClientScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New client'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _DeviceCase {
  final String name;
  final Size size;
  final TargetPlatform platform;

  const _DeviceCase(this.name, this.size, this.platform);
}

class _SurfaceCase {
  final String name;
  final Widget Function() builder;

  const _SurfaceCase(this.name, this.builder);
}

const _previewProfile = PublicProfile(
  profile: BusinessProfile(
    id: 'profile-1',
    workspaceId: 'workspace-1',
    handle: 'quality-studio',
    bio:
        'A deliberately long business description that checks wrapping '
        'without hiding the booking request action.',
    bookingMode: 'request',
  ),
  businessName: 'Quality Studio With A Long Trading Name',
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
      name: 'Signature consultation with a clear next-step plan',
      durationMins: 60,
      price: 49.99,
    ),
  ],
);
