import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_config.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/clients/clients_screen.dart';
import 'features/clients/add_client_screen.dart';
import 'features/appointments/appointments_screen.dart';
import 'features/appointments/add_appointment_screen.dart';
import 'features/finance/finance_screen.dart';
import 'features/finance/add_payment_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/calendar_sync/calendar_sync_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/public_profile/booking_requests_screen.dart';
import 'features/public_profile/public_profile_screen.dart';
import 'shared/providers/debug_demo_data_provider.dart';
import 'shared/providers/workspace_provider.dart';
import 'shared/widgets/slate_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseConfig.validate();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: SlateApp()));
}

class SlateApp extends ConsumerWidget {
  const SlateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Slate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const MainShell()),
    GoRoute(
      path: '/clients',
      builder: (context, state) => const MainShell(initialIndex: 1),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const MainShell(initialIndex: 4),
    ),
    GoRoute(
      path: '/work',
      builder: (context, state) => const MainShell(initialIndex: 2),
    ),
    GoRoute(
      path: '/payments',
      builder: (context, state) => const MainShell(initialIndex: 3),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/booking-requests',
      builder: (context, state) => const BookingRequestsScreen(),
    ),
    GoRoute(
      path: '/calendar-sync',
      builder: (context, state) => const CalendarSyncScreen(),
    ),
    GoRoute(
      path: '/p/:handle',
      builder: (context, state) {
        return PublicProfileScreen(
          handle: state.pathParameters['handle'] ?? '',
        );
      },
    ),
  ],
);

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

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
        return const WorkspaceGate();
      },
    );
  }
}

class WorkspaceGate extends ConsumerWidget {
  const WorkspaceGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    return workspace.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) => const AuthScreen(),
      data: (ws) {
        if (ws == null) return const OnboardingScreen();
        const seedDemoData = bool.fromEnvironment('SEED_DEMO_DATA');
        if (seedDemoData) {
          ref.watch(debugDemoSeedProvider);
        }
        return const MainShell();
      },
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Tabs: 0=Home, 1=Clients, 2=Bookings, 3=Money, 4=Tasks
  Widget getScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          onNavigate: (i) => setState(() => _currentIndex = i),
          onOpenMoneyFollowUps: () => setState(() {
            _financeInitialFocus = FinanceInitialFocus.followUps;
            _currentIndex = 3;
          }),
        );
      case 1:
        return const ClientsScreen();
      case 2:
        return const AppointmentsScreen();
      case 3:
        return FinanceScreen(initialFocus: _financeInitialFocus);
      case 4:
        return const TasksScreen();
      default:
        return DashboardScreen(
          onNavigate: (i) => setState(() => _currentIndex = i),
          onOpenMoneyFollowUps: () => setState(() {
            _financeInitialFocus = FinanceInitialFocus.followUps;
            _currentIndex = 3;
          }),
        );
    }
  }

  void _showFabSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return SlateSheetFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fabOption(
                icon: LucideIcons.calendarPlus,
                label: 'New Booking',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddAppointmentScreen()),
                  ).then((_) {
                    if (mounted) setState(() => _currentIndex = 2);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              _fabOption(
                icon: LucideIcons.userPlus,
                label: 'New Client',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddClientScreen()),
                  ).then((_) {
                    if (mounted) setState(() => _currentIndex = 1);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              _fabOption(
                icon: LucideIcons.banknote,
                label: 'Record Payment',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
                  ).then((_) {
                    if (mounted) setState(() => _currentIndex = 3);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              _fabOption(
                icon: LucideIcons.checkSquare,
                label: 'New Task',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SlateSurface(
      onTap: onTap,
      color: AppColors.t1.withValues(alpha: 0.06),
      borderColor: AppColors.t1.withValues(alpha: 0.08),
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.t1.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.t2, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.t1,
            ),
          ),
          const Spacer(),
          const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.curve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.curve,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: getScreen()),
      ),
      bottomNavigationBar: _SlatePillNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() {
          _financeInitialFocus = FinanceInitialFocus.top;
          _currentIndex = i;
        }),
        onAction: _showFabSheet,
      ),
    );
  }
}

class _SlatePillNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAction;

  const _SlatePillNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAction,
  });

  static const _tabs = [
    _NavItem(label: 'Home', icon: LucideIcons.home, color: AppColors.slate),
    _NavItem(label: 'Clients', icon: LucideIcons.users, color: AppColors.slate),
    _NavItem(
      label: 'Bookings',
      icon: LucideIcons.calendarDays,
      color: AppColors.slate,
    ),
    _NavItem(
      label: 'Money',
      icon: LucideIcons.banknote,
      color: AppColors.slate,
    ),
    _NavItem(
      label: 'Tasks',
      icon: LucideIcons.listChecks,
      color: AppColors.slate,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final tabCount = _tabs.length;
    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottom > 0 ? 2 : AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SlateGlassSurface(
              blur: 30,
              color: AppColors.bgRaised.withValues(alpha: 0.40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 70,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / tabCount;
                    final left = currentIndex * tabWidth;

                    int indexForPosition(double dx) {
                      return (dx / tabWidth).floor().clamp(0, tabCount - 1);
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (details) {
                        final index = indexForPosition(
                          details.localPosition.dx,
                        );
                        if (index != currentIndex) onTap(index);
                      },
                      onHorizontalDragUpdate: (details) {
                        final index = indexForPosition(
                          details.localPosition.dx,
                        );
                        if (index != currentIndex) onTap(index);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedPositioned(
                            duration: AppMotion.deliberate,
                            curve: AppMotion.emphasized,
                            left: left,
                            top: 9,
                            width: tabWidth,
                            height: 52,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _tabs[currentIndex].color.withValues(
                                    alpha: 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: _tabs[currentIndex].color.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.t1.withValues(
                                        alpha: 0.07,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: AppColors.slateGlow.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 26,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(
                              tabCount,
                              (index) => Expanded(child: _buildTab(index)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SlateGlassSurface(
            radius: AppRadius.pill,
            blur: 30,
            color: AppColors.bgRaised.withValues(alpha: 0.44),
            child: GestureDetector(
              onTap: onAction,
              child: const SizedBox(
                width: 68,
                height: 68,
                child: Icon(LucideIcons.plus, color: AppColors.t1, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final tab = _tabs[index];
    final active = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1,
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              child: Icon(
                tab.icon,
                color: active ? tab.color : AppColors.t3,
                size: 19,
              ),
            ),
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            color: tab.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Color color;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: AppMotion.deliberate,
          curve: AppMotion.curve,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: AppColors.slateLight,
                  strokeWidth: 2.4,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Opening Slate',
                style: TextStyle(
                  color: AppColors.t3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
