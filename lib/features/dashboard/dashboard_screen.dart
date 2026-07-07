import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/business_feed_item.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/business_feed_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/utils/date_format.dart';
import '../../shared/widgets/business_feed_list.dart';
import '../../shared/widgets/slate_ui.dart';
import '../appointments/add_appointment_screen.dart';
import '../appointments/appointment_detail_screen.dart';
import '../clients/add_client_screen.dart';
import '../clients/client_detail_screen.dart';
import '../finance/add_payment_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final void Function(int) onNavigate;
  final VoidCallback onOpenMoneyFollowUps;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenMoneyFollowUps,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final todayAppointments = ref.watch(todayAppointmentsProvider);
    final finance = ref.watch(financeSummaryProvider);
    final tasks = ref.watch(allTasksProvider);
    final attention = ref.watch(dashboardAttentionProvider);
    final feed = ref.watch(businessFeedProvider);
    final unreadNotifications = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async {
          SlateHaptics.action();
          ref.invalidate(workspaceProvider);
          ref.invalidate(todayAppointmentsProvider);
          ref.invalidate(appointmentsProvider);
          ref.invalidate(clientsProvider);
          ref.invalidate(financeSummaryProvider);
          ref.invalidate(invoicesProvider);
          ref.invalidate(expensesProvider);
          ref.invalidate(allTasksProvider);
          ref.invalidate(tasksProvider);
          ref.invalidate(allNotesProvider);
          ref.invalidate(dashboardAttentionProvider);
          ref.invalidate(businessFeedProvider);
          ref.invalidate(unreadNotificationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            AppSpacing.pageTop,
            AppSpacing.pageX,
            116,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                greeting: _greeting,
                workspaceName: workspace.when(
                  data: (ws) => ws?['name']?.toString() ?? 'Your Business',
                  loading: () => '...',
                  error: (_, __) => 'Workloop',
                ),
                unreadNotifications: unreadNotifications,
                onNotifications: () => context.push('/notifications'),
                onSettings: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _GlanceZone(
                appointments: todayAppointments,
                finance: finance,
                tasks: tasks,
                onOpenAppointment: (appointment) =>
                    _openAppointment(context, ref, appointment),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _DailyCommandSection(
                appointments: todayAppointments,
                finance: finance,
                tasks: tasks,
                attention: attention,
                feed: feed,
                onOpenAttentionItem: (item) =>
                    _openAttentionItem(context, ref, item),
                onOpenFeedItem: (item) => _openFeedItem(context, item),
                onViewAllFeed: () => context.push('/business-feed'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _QuickActionsSection(
                onAddClient: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddClientScreen()),
                ).then((_) => ref.invalidate(workspaceProvider)),
                onAddAppointment: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddAppointmentScreen()),
                    ).then((_) {
                      ref.invalidate(todayAppointmentsProvider);
                      ref.invalidate(appointmentsProvider);
                    }),
                onRecordPayment: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPaymentScreen(),
                      ),
                    ).then((_) {
                      ref.invalidate(financeSummaryProvider);
                      ref.invalidate(invoicesProvider);
                    }),
                onAddTask: () => onNavigate(4),
              ),
              const SizedBox(height: AppSpacing.xl),
              _CompactMoneySection(
                appointments: todayAppointments,
                finance: finance,
                onTap: () => onNavigate(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAppointment(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> appointment,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    ).then((_) {
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(dashboardAttentionProvider);
    });
  }

  void _openAttentionItem(
    BuildContext context,
    WidgetRef ref,
    DashboardAttentionItem item,
  ) {
    switch (item.type) {
      case DashboardAttentionType.unpaid:
        onOpenMoneyFollowUps();
      case DashboardAttentionType.overdueTask:
        onNavigate(4);
      case DashboardAttentionType.unconfirmedAppointment:
        final source = item.source;
        if (source is Map<String, dynamic>) {
          _openAppointment(context, ref, source);
        }
      case DashboardAttentionType.uncontactedLead:
        final source = item.source;
        if (source is Client) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientDetailScreen(client: source.toMap()),
            ),
          );
        }
    }
  }

  void _openFeedItem(BuildContext context, BusinessFeedItem item) {
    final route = item.routeTarget;
    if (route == null) return;
    if (route == '/clients') {
      onNavigate(1);
      return;
    }
    if (route == '/work') {
      onNavigate(2);
      return;
    }
    if (route == '/payments') {
      if (item.type == BusinessFeedItemType.invoiceOverdue ||
          item.type == BusinessFeedItemType.invoiceUnpaid) {
        onOpenMoneyFollowUps();
      } else {
        onNavigate(3);
      }
      return;
    }
    if (route == '/tasks') {
      onNavigate(4);
      return;
    }
    if (route == '/notes') {
      onNavigate(5);
      return;
    }
    context.push(route);
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String workspaceName;
  final AsyncValue<int> unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;

  const _DashboardHeader({
    required this.greeting,
    required this.workspaceName,
    required this.unreadNotifications,
    required this.onNotifications,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopPageHeader(
      icon: LucideIcons.layers,
      title: greeting,
      subtitle: workspaceName,
      color: AppColors.modHome,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkloopIconButton(
            icon: LucideIcons.bell,
            semanticLabel: 'Open notifications',
            onTap: onNotifications,
            badge: unreadNotifications.when(
              data: (count) => count == 0
                  ? null
                  : Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.bg, width: 2),
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
              loading: () => null,
              error: (_, __) => null,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          WorkloopIconButton(
            icon: Icons.settings_rounded,
            semanticLabel: 'Open settings',
            onTap: onSettings,
          ),
        ],
      ),
      metrics: [
        WorkloopMetricItem(
          value: _todayLabel(),
          label: 'Today',
          color: AppColors.modCalendar,
        ),
      ],
    );
  }

  static String _todayLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

class _GlanceZone extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final AsyncValue<FinanceSummary> finance;
  final AsyncValue<List<SlateTask>> tasks;
  final ValueChanged<Map<String, dynamic>> onOpenAppointment;

  const _GlanceZone({
    required this.appointments,
    required this.finance,
    required this.tasks,
    required this.onOpenAppointment,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isLoading || finance.isLoading || tasks.isLoading) {
      return const SlateLoadingBlock(height: 154, radius: AppRadius.lg);
    }
    if (appointments.hasError || finance.hasError || tasks.hasError) {
      return const SlateErrorState(message: 'Could not load today');
    }

    final rows = _sortedToday(appointments.value ?? const []);
    final next = _nextUpcoming(rows);
    final appointmentCount = _activeAppointmentCount(rows);
    final expected = _expectedToday(rows);
    final taskCount = _tasksDueToday(tasks.value ?? const []);
    final summary = _summarySentence(
      appointments: rows,
      finance: finance.value!,
      tasks: tasks.value ?? const [],
    );
    final recommendation = _briefingRecommendation(
      appointments: rows,
      finance: finance.value!,
      tasks: tasks.value ?? const [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 15,
              color: AppColors.accentPrimary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'MORNING BRIEFING',
              style: TextStyle(
                color: AppColors.t3,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _GlanceMetric(
              icon: LucideIcons.calendarDays,
              label: '$appointmentCount today',
            ),
            _GlanceMetric(
              icon: LucideIcons.banknote,
              label: '£${expected.toStringAsFixed(0)} expected',
            ),
            _GlanceMetric(
              icon: LucideIcons.listChecks,
              label: '$taskCount due',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (summary.isNotEmpty) ...[
          Text(
            summary,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _BriefingRecommendation(label: recommendation),
        const SizedBox(height: AppSpacing.md),
        if (next == null)
          const _NoMoreAppointments()
        else
          _NextAppointmentCard(
            appointment: next,
            onTap: () => onOpenAppointment(next),
          ),
      ],
    );
  }
}

class _GlanceMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlanceMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.t1.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.t3),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BriefingRecommendation extends StatelessWidget {
  final String label;

  const _BriefingRecommendation({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.accentPrimaryStrong, width: 3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.t1,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;

  const _NextAppointmentCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = _startTime(appointment);
    final end = _endTime(appointment);
    final client = _clientName(appointment);
    final service = _serviceName(appointment);
    final location = _location(appointment);

    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.accentPrimaryStrong.withValues(alpha: 0.28),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.calendarClock,
          color: AppColors.accentPrimary,
          size: 20,
        ),
      ),
      title: Text(
        client,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        [
          start == null ? 'Next appointment' : slateTimeRange(start, end),
          service,
          if (location != null) location,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.t3, fontSize: 13),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.t3,
        size: 18,
      ),
    );
  }
}

class _NoMoreAppointments extends StatelessWidget {
  const _NoMoreAppointments();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            LucideIcons.checkCircle2,
            color: AppColors.statusSuccess,
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No more appointments today',
              style: TextStyle(
                color: AppColors.t2,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCommandSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final AsyncValue<FinanceSummary> finance;
  final AsyncValue<List<SlateTask>> tasks;
  final AsyncValue<List<DashboardAttentionItem>> attention;
  final AsyncValue<List<BusinessFeedItem>> feed;
  final ValueChanged<DashboardAttentionItem> onOpenAttentionItem;
  final ValueChanged<BusinessFeedItem> onOpenFeedItem;
  final VoidCallback onViewAllFeed;

  const _DailyCommandSection({
    required this.appointments,
    required this.finance,
    required this.tasks,
    required this.attention,
    required this.feed,
    required this.onOpenAttentionItem,
    required this.onOpenFeedItem,
    required this.onViewAllFeed,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isLoading || finance.isLoading || tasks.isLoading) {
      return const SlateLoadingBlock(height: 280, radius: AppRadius.xl);
    }
    if (appointments.hasError || finance.hasError || tasks.hasError) {
      return const SlateErrorState(message: 'Could not load daily command');
    }

    final rows = _sortedToday(appointments.value ?? const []);
    final openTasks = (tasks.value ?? const [])
        .where((task) => task.status != 'done')
        .length;
    final expected = _expectedToday(rows);
    final weekPaid = finance.value!.thisWeekSummary.paid;
    final focusItems = attention.value ?? const <DashboardAttentionItem>[];
    final isCheckingAttention = attention.isLoading && !attention.hasValue;
    final attentionFailed = attention.hasError && !attention.hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily command',
                    style: TextStyle(
                      color: AppColors.t1,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      height: 1.08,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Your next best moves',
                    style: TextStyle(
                      color: AppColors.t3,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _FocusPill(
              count: focusItems.length,
              isLoading: isCheckingAttention,
              hasError: attentionFailed,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _CommandMetric(
                label: 'TO GO',
                value: '$openTasks',
                detail: 'open',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _CommandMetric(
                label: 'TODAY',
                value: '£${expected.toStringAsFixed(0)}',
                detail: 'expected',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _CommandMetric(
                label: 'WEEK',
                value: '£${weekPaid.toStringAsFixed(0)}',
                detail: 'paid',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _CommandAttentionPanel(
          items: focusItems,
          isLoading: isCheckingAttention,
          hasError: attentionFailed,
          onOpenItem: onOpenAttentionItem,
        ),
        const SizedBox(height: AppSpacing.md),
        _CommandFeedPreview(
          feed: feed,
          onOpenFeedItem: onOpenFeedItem,
          onViewAllFeed: onViewAllFeed,
        ),
      ],
    );
  }
}

class _CommandFeedPreview extends StatelessWidget {
  final AsyncValue<List<BusinessFeedItem>> feed;
  final ValueChanged<BusinessFeedItem> onOpenFeedItem;
  final VoidCallback onViewAllFeed;

  const _CommandFeedPreview({
    required this.feed,
    required this.onOpenFeedItem,
    required this.onViewAllFeed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.activity, color: AppColors.modHome, size: 18),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Business Feed',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        feed.when(
          loading: () =>
              const SlateLoadingBlock(height: 116, radius: AppRadius.lg),
          error: (_, __) =>
              const SlateErrorState(message: 'Could not load feed'),
          data: (items) => BusinessFeedList(
            items: items,
            compact: true,
            limit: 4,
            onItemTap: onOpenFeedItem,
            onViewAll: onViewAllFeed,
          ),
        ),
      ],
    );
  }
}

class _FocusPill extends StatelessWidget {
  final int count;
  final bool isLoading;
  final bool hasError;

  const _FocusPill({
    required this.count,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAttention = count > 0;
    final color = hasError
        ? AppColors.error
        : hasAttention
        ? AppColors.warning
        : AppColors.statusSuccess;
    final background = hasError
        ? AppColors.error.withValues(alpha: 0.10)
        : hasAttention
        ? AppColors.warningDim
        : AppColors.statusSuccess.withValues(alpha: 0.10);
    final label = isLoading
        ? 'Checking'
        : hasError
        ? 'Review'
        : hasAttention
        ? '$count focus'
        : 'Clear';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CommandMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const _CommandMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.58)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandAttentionPanel extends StatelessWidget {
  final List<DashboardAttentionItem> items;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<DashboardAttentionItem> onOpenItem;

  const _CommandAttentionPanel({
    required this.items,
    required this.onOpenItem,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final topItems = items.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.alertCircle,
              color: AppColors.warning,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Needs attention',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${items.length}',
              style: const TextStyle(
                color: AppColors.t3,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isLoading)
          const SlateLoadingBlock(height: 52, radius: AppRadius.pill)
        else if (hasError)
          const _CommandAttentionStatus(
            icon: LucideIcons.alertTriangle,
            iconColor: AppColors.error,
            label: 'Could not check attention items',
          )
        else if (topItems.isEmpty)
          const _CommandClearState()
        else
          for (final item in topItems) ...[
            _CommandAttentionRow(item: item, onTap: () => onOpenItem(item)),
            if (item != topItems.last) const SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }
}

class _CommandAttentionStatus extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _CommandAttentionStatus({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.t2,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandClearState extends StatelessWidget {
  const _CommandClearState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.checkCircle2, color: AppColors.statusSuccess),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Nothing needs attention',
            style: TextStyle(
              color: AppColors.t2,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandAttentionRow extends StatelessWidget {
  final DashboardAttentionItem item;
  final VoidCallback onTap;

  const _CommandAttentionRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      DashboardAttentionType.unpaid => LucideIcons.banknote,
      DashboardAttentionType.unconfirmedAppointment =>
        LucideIcons.calendarClock,
      DashboardAttentionType.overdueTask => LucideIcons.listChecks,
      DashboardAttentionType.uncontactedLead => LucideIcons.user,
    };

    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      leading: Icon(icon, color: AppColors.warning, size: 17),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.t3,
        size: 16,
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddClient;
  final VoidCallback onAddAppointment;
  final VoidCallback onRecordPayment;
  final VoidCallback onAddTask;

  const _QuickActionsSection({
    required this.onAddClient,
    required this.onAddAppointment,
    required this.onRecordPayment,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkloopSectionHeader(label: 'QUICK ACTIONS'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: LucideIcons.userPlus,
                label: 'Client',
                onTap: onAddClient,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _QuickActionButton(
                icon: LucideIcons.calendarPlus,
                label: 'Booking',
                onTap: onAddAppointment,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: LucideIcons.banknote,
                label: 'Payment',
                onTap: onRecordPayment,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _QuickActionButton(
                icon: LucideIcons.listPlus,
                label: 'Task',
                onTap: onAddTask,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      onTap: onTap,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: AppColors.t1.withValues(alpha: 0.045),
      borderColor: AppColors.border.withValues(alpha: 0.54),
      child: Row(
        children: [
          Icon(icon, color: AppColors.t2, size: 17),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.t1,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMoneySection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final AsyncValue<FinanceSummary> finance;
  final VoidCallback onTap;

  const _CompactMoneySection({
    required this.appointments,
    required this.finance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isLoading || finance.isLoading) {
      return const SlateLoadingBlock(height: 104, radius: AppRadius.lg);
    }
    if (appointments.hasError || finance.hasError) {
      return const SlateErrorState(message: 'Could not load money');
    }

    final expectedToday = _expectedToday(appointments.value ?? const []);
    final weekPaid = finance.value!.thisWeekSummary.paid;

    return SlateSurface(
      onTap: onTap,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.panelSoft,
      borderColor: AppColors.panelSoftRaised,
      child: Row(
        children: [
          const Icon(
            LucideIcons.banknote,
            color: AppColors.panelMuted,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONEY',
                  style: TextStyle(
                    color: AppColors.panelMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '£${expectedToday.toStringAsFixed(0)} expected today · £${weekPaid.toStringAsFixed(0)} this week',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.panelInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: AppColors.panelMuted,
            size: 16,
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _sortedToday(List<Map<String, dynamic>> rows) {
  final sorted = [...rows];
  sorted.sort((a, b) {
    final aStart = _startTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bStart = _startTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aStart.compareTo(bStart);
  });
  return sorted;
}

Map<String, dynamic>? _nextUpcoming(List<Map<String, dynamic>> rows) {
  final now = DateTime.now();
  for (final row in rows) {
    final status = row['status']?.toString() ?? 'scheduled';
    final start = _startTime(row);
    if (start == null) continue;
    if (status == 'completed' || status == 'cancelled' || status == 'no_show') {
      continue;
    }
    if (start.isAfter(now)) return row;
  }
  return null;
}

String _summarySentence({
  required List<Map<String, dynamic>> appointments,
  required FinanceSummary finance,
  required List<SlateTask> tasks,
}) {
  final parts = <String>[];
  final appointmentCount = appointments
      .where((row) => row['status']?.toString() != 'cancelled')
      .length;
  final expected = _expectedToday(appointments);
  final taskCount = _tasksDueToday(tasks);

  if (appointmentCount > 0) {
    parts.add(
      '$appointmentCount appointment${appointmentCount == 1 ? '' : 's'} today',
    );
  }
  if (expected > 0) parts.add('£${expected.toStringAsFixed(0)} expected');
  if (taskCount > 0) {
    parts.add('$taskCount task${taskCount == 1 ? '' : 's'} due');
  }
  return parts.join(' · ');
}

String _briefingRecommendation({
  required List<Map<String, dynamic>> appointments,
  required FinanceSummary finance,
  required List<SlateTask> tasks,
}) {
  final overdueTasks = tasks.where((task) {
    final due = task.dueDate;
    if (task.status == 'done' || due == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }).length;
  final appointmentCount = _activeAppointmentCount(appointments);
  if (finance.overdue > 0) return 'Send overdue payment reminder';
  if (overdueTasks > 0) return 'Clear overdue tasks before the day moves on';
  if (appointmentCount > 0) return 'Review today\'s bookings';
  return 'No urgent actions today';
}

int _activeAppointmentCount(List<Map<String, dynamic>> appointments) {
  return appointments.where((row) {
    final status = row['status']?.toString() ?? 'scheduled';
    return status != 'cancelled' && status != 'no_show';
  }).length;
}

double _expectedToday(List<Map<String, dynamic>> appointments) {
  return appointments
      .where((row) {
        final status = row['status']?.toString() ?? 'scheduled';
        return status != 'cancelled' && status != 'no_show';
      })
      .fold<double>(0, (sum, row) {
        final value = row['price'];
        if (value is num) return sum + value.toDouble();
        return sum + (double.tryParse(value?.toString() ?? '') ?? 0);
      });
}

int _tasksDueToday(List<SlateTask> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return tasks.where((task) {
    final due = task.dueDate;
    if (task.status == 'done' || due == null) return false;
    final dueDay = DateTime(due.year, due.month, due.day);
    return !dueDay.isAfter(today);
  }).length;
}

DateTime? _startTime(Map<String, dynamic> appointment) =>
    DateTime.tryParse(appointment['start_time']?.toString() ?? '')?.toLocal();

DateTime? _endTime(Map<String, dynamic> appointment) =>
    DateTime.tryParse(appointment['end_time']?.toString() ?? '')?.toLocal();

String _clientName(Map<String, dynamic> appointment) =>
    appointment['contacts']?['name']?.toString() ?? 'Walk-in';

String _serviceName(Map<String, dynamic> appointment) =>
    appointment['services']?['name']?.toString() ??
    appointment['title']?.toString() ??
    'Booking';

String? _location(Map<String, dynamic> appointment) {
  final value = appointment['location']?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
