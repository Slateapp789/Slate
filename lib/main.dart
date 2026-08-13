import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/workloop_font_license.dart';
import 'core/supabase/supabase_config.dart';
import 'core/workloop_app_info.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/mfa_screens.dart';
import 'features/auth/password_recovery_screen.dart';
import 'features/business_feed/business_feed_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/clients/clients_screen.dart';
import 'features/clients/add_client_screen.dart';
import 'features/appointments/add_appointment_screen.dart';
import 'features/business/business_screen.dart';
import 'features/finance/finance_screen.dart';
import 'features/work/work_screen.dart';
import 'features/work/work_workspace_switcher.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/calendar_sync/calendar_sync_screen.dart';
import 'features/imports/import_data_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/public_profile/booking_requests_screen.dart';
import 'features/public_profile/public_profile_screen.dart';
import 'shared/providers/debug_demo_data_provider.dart';
import 'shared/providers/appointments_provider.dart';
import 'shared/providers/dashboard_provider.dart';
import 'shared/providers/theme_mode_provider.dart';
import 'shared/providers/workspace_provider.dart';
import 'shared/notifications/local_reminder_bootstrap.dart';
import 'shared/utils/public_profile_routes.dart';
import 'shared/widgets/slate_ui.dart';

const workloopMinimumLaunchDuration = Duration(milliseconds: 700);

Duration remainingLaunchDuration(
  Duration elapsed, {
  Duration minimum = workloopMinimumLaunchDuration,
}) {
  if (elapsed >= minimum) return Duration.zero;
  return minimum - elapsed;
}

void main() async {
  final launchClock = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  registerWorkloopFontLicenses();
  usePathUrlStrategy();
  SupabaseConfig.validate();
  final appInfoFuture = WorkloopAppInfo.initialize();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabasePublishableKey,
  );
  await appInfoFuture;
  final remaining = remainingLaunchDuration(launchClock.elapsed);
  if (remaining > Duration.zero) {
    await Future<void>.delayed(remaining);
  }
  runApp(const ProviderScope(child: WorkloopApp()));
}

class WorkloopApp extends ConsumerStatefulWidget {
  const WorkloopApp({super.key});

  @override
  ConsumerState<WorkloopApp> createState() => _WorkloopAppState();
}

class _WorkloopAppState extends ConsumerState<WorkloopApp>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event != AuthChangeEvent.passwordRecovery) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _router.go('/reset-password');
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(workloopAppearanceProvider);
    final themeMode = appearance.value?.themeMode ?? ThemeMode.system;
    final effectiveBrightness = WorkloopLegacyPalette.resolve(
      themeMode: themeMode,
      platformBrightness:
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );

    // Legacy adaptive colours must resolve before MaterialApp builds its child
    // tree. Synchronising inside MaterialApp.builder is one frame too late: the
    // new theme reaches the screen while legacy icon chips still paint with the
    // outgoing appearance until another rebuild.
    WorkloopLegacyPalette.sync(effectiveBrightness);

    return MaterialApp.router(
      title: 'Workloop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      scrollBehavior: const WorkloopScrollBehavior(),
      routerConfig: _router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final overlayStyle = brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: SlateTheme.of(context).background,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: SlateTheme.of(context).background,
                systemNavigationBarIconBrightness: Brightness.dark,
              );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: WorkloopNavigationAssistRegion(
            observer: _navigationObserver,
            child: WorkloopLocalReminderBootstrap(
              child: WorkloopKeyboardDismissRegion(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

final _navigationObserver = WorkloopNavigationObserver();

final _router = GoRouter(
  observers: [_navigationObserver],
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const PasswordRecoveryScreen(),
    ),
    GoRoute(
      path: '/security/2fa',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: MfaSetupScreen()),
    ),
    GoRoute(path: '/onboarding', builder: (context, state) => const AuthGate()),
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: MainShell()),
    ),
    GoRoute(
      path: '/business-feed',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: BusinessFeedScreen()),
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: MainShell(initialIndex: 1)),
    ),
    GoRoute(
      path: '/clients/new',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: AddClientScreen()),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: MainShell(initialIndex: 4)),
    ),
    GoRoute(
      path: '/work',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: MainShell(initialIndex: 2)),
    ),
    GoRoute(
      path: '/bookings/new',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: AddAppointmentScreen()),
    ),
    GoRoute(
      path: '/payments',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: MainShell(initialIndex: 3)),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: NotificationsScreen()),
    ),
    GoRoute(
      path: '/notes',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: MainShell(initialIndex: 5)),
    ),
    GoRoute(
      path: '/booking-requests',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: BookingRequestsScreen()),
    ),
    GoRoute(
      path: '/calendar-sync',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: CalendarSyncScreen()),
    ),
    GoRoute(
      path: '/import-data',
      builder: (context, state) =>
          const AuthGate(authenticatedChild: ImportDataScreen()),
    ),
    GoRoute(
      path: '/p/:handle',
      builder: (context, state) {
        return PublicProfileScreen(
          handle: state.pathParameters['handle'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/:handle',
      redirect: (context, state) {
        final handle = state.pathParameters['handle'] ?? '';
        return isReservedPublicHandle(handle) ? '/' : null;
      },
      builder: (context, state) =>
          PublicProfileScreen(handle: state.pathParameters['handle'] ?? ''),
    ),
  ],
);

class AuthGate extends ConsumerStatefulWidget {
  final Widget authenticatedChild;

  const AuthGate({super.key, this.authenticatedChild = const MainShell()});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        final currentUserId = session?.user.id;
        if (currentUserId != _lastUserId) {
          _lastUserId = currentUserId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(workspaceProvider);
          });
        }
        if (session == null) return const AuthScreen();
        final assurance = Supabase.instance.client.auth.mfa
            .getAuthenticatorAssuranceLevel();
        final needsMfa =
            assurance.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
            assurance.nextLevel == AuthenticatorAssuranceLevels.aal2;
        if (needsMfa) {
          return MfaChallengeScreen(onVerified: () => setState(() {}));
        }
        return WorkspaceGate(child: widget.authenticatedChild);
      },
    );
  }
}

class WorkspaceGate extends ConsumerWidget {
  final Widget child;

  const WorkspaceGate({super.key, this.child = const MainShell()});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    return workspace.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) => _WorkspaceErrorScreen(
        message:
            'Your workspace could not be opened. Check your connection and try again.',
        onRetry: () => ref.invalidate(workspaceProvider),
        onSignOut: () async {
          await Supabase.instance.client.auth.signOut();
          ref.invalidate(workspaceProvider);
        },
      ),
      data: (ws) {
        if (ws == null) return const OnboardingScreen();
        const seedDemoData = bool.fromEnvironment('SEED_DEMO_DATA');
        if (kDebugMode && seedDemoData) {
          ref.watch(debugDemoSeedProvider);
        }
        final destination = child;
        final opensOnDashboard =
            destination is MainShell && destination.initialIndex == 0;
        return opensOnDashboard ? _DashboardInitialGate(child: child) : child;
      },
    );
  }
}

class _DashboardInitialGate extends ConsumerStatefulWidget {
  final Widget child;

  const _DashboardInitialGate({required this.child});

  @override
  ConsumerState<_DashboardInitialGate> createState() =>
      _DashboardInitialGateState();
}

class _DashboardInitialGateState extends ConsumerState<_DashboardInitialGate> {
  bool _opened = false;
  bool _revealScheduled = false;

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final attention = ref.watch(dashboardAttentionProvider);
    final sourcesSettled =
        (appointments.hasValue || appointments.hasError) &&
        (attention.hasValue || attention.hasError);

    if (!_opened && sourcesSettled && !_revealScheduled) {
      _revealScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _opened = true);
      });
    }

    return AnimatedSwitcher(
      duration: AppMotion.responsive(context, AppMotion.standard),
      switchInCurve: AppMotion.curve,
      switchOutCurve: Curves.easeOut,
      child: _opened
          ? KeyedSubtree(
              key: const ValueKey('dashboard-ready'),
              child: widget.child,
            )
          : const KeyedSubtree(
              key: ValueKey('dashboard-opening'),
              child: _LoadingScreen(),
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  FinanceInitialFocus _financeInitialFocus = FinanceInitialFocus.top;
  late final ValueNotifier<WorkWorkspaceSection> _workSectionController;
  late final List<Widget?> _destinations;
  late final List<ScrollController> _navigationScrollControllers;

  @override
  void initState() {
    super.initState();
    _currentIndex = _shellDestination(widget.initialIndex);
    _workSectionController = ValueNotifier(
      _workSectionForDestination(widget.initialIndex),
    );
    _destinations = List<Widget?>.filled(7, null);
    _navigationScrollControllers = List<ScrollController>.generate(
      7,
      (_) => ScrollController(),
    );
    _ensureDestination(_currentIndex);
  }

  @override
  void dispose() {
    _workSectionController.dispose();
    for (final controller in _navigationScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureDestination(int index) {
    _destinations[index] ??= switch (index) {
      0 => DashboardScreen(
        onNavigate: _navigateTo,
        onOpenMoneyFollowUps: () =>
            _navigateTo(3, financeFocus: FinanceInitialFocus.followUps),
      ),
      1 => const ClientsScreen(),
      2 => WorkScreen(sectionController: _workSectionController),
      3 => FinanceScreen(initialFocus: _financeInitialFocus),
      4 || 5 => const SizedBox.shrink(),
      6 => const BusinessScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  Object _navigationScopeId(int index) => 'main-shell-$index';

  int _shellDestination(int destination) => switch (destination) {
    4 || 5 => 2,
    _ => destination,
  };

  WorkWorkspaceSection _workSectionForDestination(int destination) =>
      switch (destination) {
        4 => WorkWorkspaceSection.tasks,
        5 => WorkWorkspaceSection.notes,
        _ => WorkWorkspaceSection.schedule,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WorkloopNavigationAssistRegion.activateScope(
      context,
      _navigationScopeId(_currentIndex),
      controller: _navigationScrollControllers[_currentIndex],
    );
  }

  void _navigateTo(
    int index, {
    FinanceInitialFocus financeFocus = FinanceInitialFocus.top,
  }) {
    if (index == 2 || index == 4 || index == 5) {
      _workSectionController.value = _workSectionForDestination(index);
      index = 2;
    }
    if (index == 3 && _financeInitialFocus != financeFocus) {
      _financeInitialFocus = financeFocus;
      _destinations[3] = FinanceScreen(initialFocus: financeFocus);
    }
    _ensureDestination(index);
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    WorkloopNavigationAssistRegion.activateScope(
      context,
      _navigationScopeId(index),
      controller: _navigationScrollControllers[index],
    );
  }

  int _primaryNavIndexForDestination(int destination) => switch (destination) {
    0 => 0,
    1 => 1,
    2 || 4 || 5 => 2,
    3 => 3,
    6 => 4,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final destinationChildren = List<Widget>.generate(
      _destinations.length,
      (index) => PrimaryScrollController(
        controller: _navigationScrollControllers[index],
        child: WorkloopNavigationScope(
          id: _navigationScopeId(index),
          child: _destinations[index] ?? const SizedBox.shrink(),
        ),
      ),
    );
    return Scaffold(
      backgroundColor: tokens.background,
      extendBody: true,
      body: WorkloopInteractiveWorkspaceStack(
        key: const ValueKey('main-shell-tabs'),
        index: _currentIndex,
        previousIndex: null,
        onBack: () {},
        children: destinationChildren,
      ),
      bottomNavigationBar: WorkloopBottomNav(
        currentIndex: _primaryNavIndexForDestination(_currentIndex),
        items: const [
          WorkloopNavItem(
            label: 'Today',
            icon: LucideIcons.home,
            color: AppColors.accentPrimary,
          ),
          WorkloopNavItem(
            label: 'Clients',
            icon: LucideIcons.users,
            color: AppColors.accentPrimary,
          ),
          WorkloopNavItem(
            label: 'Work',
            icon: LucideIcons.briefcase,
            color: AppColors.accentPrimary,
          ),
          WorkloopNavItem(
            label: 'Money',
            icon: LucideIcons.circlePoundSterling,
            color: AppColors.accentPrimary,
          ),
          WorkloopNavItem(
            label: 'Business',
            icon: LucideIcons.store,
            color: AppColors.accentPrimary,
          ),
        ],
        onTap: (i) {
          final destination = switch (i) {
            0 => 0,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => 6,
            _ => 0,
          };
          if (destination == _currentIndex) return;
          _navigateTo(destination);
        },
      ),
    );
  }
}

class _WorkspaceErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  const _WorkspaceErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: WorkloopSurface(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: tokens.warning,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Could not open your workspace',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textTertiary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: WorkloopPrimaryButton(
                          label: 'Try again',
                          icon: LucideIcons.refreshCcw,
                          onPressed: onRetry,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: WorkloopPrimaryButton(
                          label: 'Sign out',
                          icon: LucideIcons.logOut,
                          secondary: true,
                          onPressed: () {
                            onSignOut();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: AppMotion.responsive(context, AppMotion.deliberate),
          curve: AppMotion.curve,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: tokens.accent,
                  strokeWidth: 2.4,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Opening Workloop',
                style: TextStyle(
                  color: tokens.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
