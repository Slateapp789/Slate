import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/business_feed_item.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/business_feed_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/setup_checklist_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/date_format.dart';
import '../../shared/widgets/slate_ui.dart';
import '../appointments/appointment_detail_screen.dart';

final dashboardClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

String dashboardGreetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String dashboardDateLabel(DateTime date) => _dashboardDate(date);

List<Map<String, dynamic>> selectDashboardTodayBookings(
  List<Map<String, dynamic>> rows, {
  required DateTime now,
}) => _todayJobs(rows, now: now);

List<Map<String, dynamic>> selectDashboardComingUpBookings(
  List<Map<String, dynamic>> rows, {
  required DateTime now,
}) => _upcomingJobs(
  rows,
  now: now,
).where((job) => !_isSameDay(_startTime(job), now)).take(3).toList();

int dashboardSetupCompletedCount({
  required bool hasClient,
  required bool hasBooking,
  required bool hasPayment,
}) => [hasClient, hasBooking, hasPayment].where((value) => value).length;

class DashboardScreen extends ConsumerWidget {
  final void Function(int) onNavigate;
  final VoidCallback onOpenMoneyFollowUps;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenMoneyFollowUps,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final appointments = ref.watch(appointmentsProvider);
    final clients = ref.watch(clientsProvider);
    final payments = ref.watch(invoicesProvider);
    final finance = ref.watch(financeSummaryProvider);
    final feed = ref.watch(businessFeedProvider);
    final attention = ref.watch(dashboardAttentionProvider);
    final displayName = ref.watch(authRepositoryProvider).currentFirstName;
    final now = ref
        .watch(dashboardClockProvider)
        .maybeWhen(data: (value) => value, orElse: DateTime.now);
    final greeting = dashboardGreetingForHour(now.hour);
    final checklistDismissed = ref
        .watch(setupChecklistDismissedProvider)
        .asData
        ?.value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          RefreshIndicator(
            color: AppColors.accentPrimary,
            onRefresh: () async {
              SlateHaptics.action();
              ref.invalidate(workspaceProvider);
              ref.invalidate(appointmentsProvider);
              ref.invalidate(todayAppointmentsProvider);
              ref.invalidate(financeSummaryProvider);
              ref.invalidate(invoicesProvider);
              ref.invalidate(expensesProvider);
              ref.invalidate(clientsProvider);
              ref.invalidate(allTasksProvider);
              ref.invalidate(tasksProvider);
              ref.invalidate(allNotesProvider);
              ref.invalidate(businessFeedProvider);
              ref.invalidate(dashboardAttentionProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.pageTop + AppSpacing.xxl,
                AppSpacing.pageX,
                AppSpacing.bottomNavClearance,
              ),
              children: [
                _DashboardGreeting(
                  greeting: displayName == null
                      ? greeting
                      : '$greeting $displayName',
                  subtitle: dashboardDateLabel(now),
                ),
                if (checklistDismissed == false)
                  _SetupChecklist(
                    hasClient: clients.asData?.value.isNotEmpty ?? false,
                    hasBooking: appointments.asData?.value.isNotEmpty ?? false,
                    hasPayment: payments.asData?.value.isNotEmpty ?? false,
                    onAddClient: () => context.push('/clients/new'),
                    onAddBooking: () => context.push('/bookings/new'),
                    onAddPayment: () => onNavigate(3),
                    onImport: () => context.push('/import-data'),
                    onDismiss: () => dismissSetupChecklist(ref),
                  ),
                const SizedBox(height: AppSpacing.xxl),
                _TodaySection(
                  appointments: appointments,
                  now: now,
                  onOpenJob: (appointment) =>
                      _openAppointment(context, ref, appointment),
                  onViewBookings: () => onNavigate(2),
                ),
                attention.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: _WorthALookSection(
                            items: items.take(2).toList(),
                            onOpen: (item) =>
                                _openAttentionItem(context, ref, item),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _MoneyPulse(finance: finance, onOpen: () => onNavigate(3)),
                const SizedBox(height: AppSpacing.xl),
                _QuickAccessRow(
                  taskSummary: 'Plan and follow up',
                  noteSummary: 'Capture useful context',
                  onOpenTasks: () => onNavigate(4),
                  onOpenNotes: () => onNavigate(5),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _UpcomingJobsSection(
                  appointments: appointments,
                  now: now,
                  onOpenJob: (appointment) =>
                      _openAppointment(context, ref, appointment),
                  onViewBookings: () => onNavigate(2),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _CalmFeedSection(
                  feed: feed,
                  onOpenFeedItem: (item) => _openFeedItem(context, item),
                  onViewAllFeed: () => context.push('/business-feed'),
                ),
                if (workspace.hasError) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const SlateErrorState(message: 'Could not refresh workspace'),
                ],
              ],
            ),
          ),
        ],
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
      ref.invalidate(appointmentsProvider);
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(businessFeedProvider);
    });
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
      onNavigate(3);
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

  void _openAttentionItem(
    BuildContext context,
    WidgetRef ref,
    DashboardAttentionItem item,
  ) {
    switch (item.type) {
      case DashboardAttentionType.unpaid:
        onOpenMoneyFollowUps();
      case DashboardAttentionType.unconfirmedAppointment:
        final appointment = item.source;
        if (appointment is Map<String, dynamic>) {
          _openAppointment(context, ref, appointment);
        } else {
          onNavigate(2);
        }
      case DashboardAttentionType.overdueTask:
        onNavigate(4);
      case DashboardAttentionType.uncontactedLead:
        onNavigate(1);
    }
  }
}

class _SetupChecklist extends StatelessWidget {
  final bool hasClient;
  final bool hasBooking;
  final bool hasPayment;
  final VoidCallback onAddClient;
  final VoidCallback onAddBooking;
  final VoidCallback onAddPayment;
  final VoidCallback onImport;
  final VoidCallback onDismiss;

  const _SetupChecklist({
    required this.hasClient,
    required this.hasBooking,
    required this.hasPayment,
    required this.onAddClient,
    required this.onAddBooking,
    required this.onAddPayment,
    required this.onImport,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final completed = dashboardSetupCompletedCount(
      hasClient: hasClient,
      hasBooking: hasBooking,
      hasPayment: hasPayment,
    );
    if (completed == 3) return const SizedBox.shrink();
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: WorkloopSurface(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up your workspace',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$completed of 3 essentials complete',
                        style: TextStyle(
                          color: tokens.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                WorkloopIconButton(
                  icon: LucideIcons.x,
                  semanticLabel: 'Dismiss setup checklist',
                  onTap: onDismiss,
                  size: 36,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SetupStep(
              complete: hasClient,
              label: 'Add your first client',
              onTap: onAddClient,
            ),
            _SetupStep(
              complete: hasBooking,
              label: 'Create your first booking',
              onTap: onAddBooking,
            ),
            _SetupStep(
              complete: hasPayment,
              label: 'Record your first payment',
              onTap: onAddPayment,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: WorkloopTextButton(
                label: 'Import existing data',
                onPressed: onImport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final bool complete;
  final String label;
  final VoidCallback onTap;

  const _SetupStep({
    required this.complete,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopListRow(
      onTap: complete ? null : onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      leading: Icon(
        complete ? LucideIcons.checkCircle2 : LucideIcons.circle,
        size: 19,
        color: complete ? tokens.accentInk : tokens.textTertiary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: complete ? tokens.textTertiary : tokens.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: complete ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: complete
          ? null
          : Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: tokens.textTertiary,
            ),
      showDivider: false,
    );
  }
}

class _DashboardGreeting extends StatelessWidget {
  final String greeting;
  final String subtitle;

  const _DashboardGreeting({required this.greeting, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.04,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.t2,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.32,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  final String taskSummary;
  final String noteSummary;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotes;

  const _QuickAccessRow({
    required this.taskSummary,
    required this.noteSummary,
    required this.onOpenTasks,
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessItem(
            icon: LucideIcons.listChecks,
            label: 'Tasks',
            summary: taskSummary,
            onTap: onOpenTasks,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAccessItem(
            icon: LucideIcons.stickyNote,
            label: 'Notes',
            summary: noteSummary,
            onTap: onOpenNotes,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String summary;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $summary',
      child: WorkloopSurface(
        onTap: () {
          SlateHaptics.tap();
          onTap();
        },
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.sm),
        color: AppColors.t1.withValues(alpha: 0.028),
        borderColor: AppColors.border.withValues(alpha: 0.52),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.t3),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.t3,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.t3),
          ],
        ),
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final DateTime now;
  final ValueChanged<Map<String, dynamic>> onOpenJob;
  final VoidCallback onViewBookings;

  const _TodaySection({
    required this.appointments,
    required this.now,
    required this.onOpenJob,
    required this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Today',
      prominent: true,
      child: appointments.when(
        loading: () =>
            const SlateLoadingBlock(height: 72, radius: AppRadius.md),
        error: (_, __) => WorkloopListRow(
          onTap: onViewBookings,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          leading: const _SoftIcon(icon: LucideIcons.calendarDays),
          title: const Text(
            'Open today\'s bookings',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: const Text(
            'See the full schedule in Bookings.',
            style: TextStyle(
              color: AppColors.t2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            LucideIcons.chevronRight,
            color: AppColors.t3,
            size: 16,
          ),
        ),
        data: (rows) {
          final jobs = selectDashboardTodayBookings(rows, now: now);
          if (jobs.isEmpty) {
            return WorkloopListRow(
              onTap: onViewBookings,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              leading: const _SoftIcon(icon: LucideIcons.sun),
              title: const Text(
                'Your day is clear',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'There are no more bookings scheduled today.',
                style: TextStyle(
                  color: AppColors.t2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UpcomingJobRow(
                job: jobs.first,
                onTap: () => onOpenJob(jobs.first),
                showDate: false,
              ),
              if (jobs.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    jobs.length == 2
                        ? '1 more booking later today'
                        : '${jobs.length - 1} more bookings later today',
                    style: const TextStyle(
                      color: AppColors.t2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WorthALookSection extends StatelessWidget {
  final List<DashboardAttentionItem> items;
  final ValueChanged<DashboardAttentionItem> onOpen;

  const _WorthALookSection({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Worth a look',
      child: Column(
        children: [
          for (final item in items)
            WorkloopListRow(
              onTap: () => onOpen(item),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              leading: _SoftIcon(icon: _attentionIcon(item.type)),
              title: Text(
                _attentionTitle(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                _attentionDetail(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.t2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _MoneyPulse extends StatelessWidget {
  final AsyncValue<FinanceSummary> finance;
  final VoidCallback onOpen;

  const _MoneyPulse({required this.finance, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Money',
      child: finance.when(
        loading: () =>
            const SlateLoadingBlock(height: 68, radius: AppRadius.md),
        error: (_, __) => _MoneyRow(onOpen: onOpen),
        data: (summary) =>
            _MoneyRow(onOpen: onOpen, amount: summary.thisMonthPaid),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final VoidCallback onOpen;
  final double? amount;

  const _MoneyRow({required this.onOpen, this.amount});

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: const _SoftIcon(icon: LucideIcons.banknote),
      title: Text(
        amount == null
            ? 'Open Money'
            : '£${amount!.toStringAsFixed(0)} received',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        amount == null
            ? 'See your latest business progress.'
            : 'So far this calendar month.',
        style: const TextStyle(
          color: AppColors.t2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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

class _UpcomingJobsSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final DateTime now;
  final ValueChanged<Map<String, dynamic>> onOpenJob;
  final VoidCallback onViewBookings;

  const _UpcomingJobsSection({
    required this.appointments,
    required this.now,
    required this.onOpenJob,
    required this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Coming up',
      actionLabel: 'View all',
      onAction: onViewBookings,
      child: appointments.when(
        loading: () =>
            const SlateLoadingBlock(height: 150, radius: AppRadius.lg),
        error: (_, __) =>
            const SlateErrorState(message: 'Could not load upcoming bookings'),
        data: (rows) {
          final jobs = selectDashboardComingUpBookings(rows, now: now);
          if (jobs.isEmpty) {
            return WorkloopListRow(
              onTap: onViewBookings,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              leading: const _SoftIcon(icon: LucideIcons.calendarDays),
              title: const Text(
                'Nothing else scheduled yet',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Your upcoming schedule is open.',
                style: TextStyle(
                  color: AppColors.t2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
            );
          }

          return Column(
            children: [
              for (final job in jobs)
                _UpcomingJobRow(job: job, onTap: () => onOpenJob(job)),
            ],
          );
        },
      ),
    );
  }
}

class _UpcomingJobRow extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;
  final bool showDate;

  const _UpcomingJobRow({
    required this.job,
    required this.onTap,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final start = _startTime(job);
    final end = _endTime(job);
    final client = _clientName(job);
    final service = _serviceName(job);
    final date = start == null ? 'Upcoming' : _friendlyDate(start);
    final time = start == null ? null : slateTimeRange(start, end);

    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: _SoftIcon(icon: LucideIcons.calendarClock),
      title: Text(
        client,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        [if (showDate) date, if (time != null) time, service].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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

class _CalmFeedSection extends StatelessWidget {
  final AsyncValue<List<BusinessFeedItem>> feed;
  final ValueChanged<BusinessFeedItem> onOpenFeedItem;
  final VoidCallback onViewAllFeed;

  const _CalmFeedSection({
    required this.feed,
    required this.onOpenFeedItem,
    required this.onViewAllFeed,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Recent activity',
      actionLabel: 'View all',
      onAction: onViewAllFeed,
      child: feed.when(
        loading: () =>
            const SlateLoadingBlock(height: 190, radius: AppRadius.lg),
        error: (_, __) => const SlateErrorState(message: 'Could not load feed'),
        data: (items) {
          final calmItems = items.where(_isCalmFeedItem).take(3).toList();
          if (calmItems.isEmpty) {
            return const WorkloopEmptyState(
              icon: LucideIcons.activity,
              title: 'No activity yet.',
              subtitle:
                  'Recent bookings, notes, and payments will appear here.',
            );
          }

          return Column(
            children: [
              for (final item in calmItems) ...[
                _CalmFeedRow(
                  item: item,
                  onTap: item.routeTarget == null
                      ? null
                      : () => onOpenFeedItem(item),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CalmFeedRow extends StatelessWidget {
  final BusinessFeedItem item;
  final VoidCallback? onTap;

  const _CalmFeedRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: _SoftIcon(icon: _iconForFeedItem(item)),
      title: Text(
        _calmFeedTitle(item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${item.subtitle} · ${_relativeTime(item.timestamp)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: onTap == null
          ? null
          : const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool prominent;

  const _DashboardSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: prominent ? 22 : 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              WorkloopTextButton(label: actionLabel!, onPressed: onAction),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.t1.withValues(alpha: 0.045),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.t3, size: 17),
    );
  }
}

String _dashboardDate(DateTime date) {
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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

List<Map<String, dynamic>> _todayJobs(
  List<Map<String, dynamic>> rows, {
  required DateTime now,
}) {
  return _upcomingJobs(
    rows,
    now: now,
  ).where((row) => _isSameDay(_startTime(row), now)).toList();
}

bool _isSameDay(DateTime? first, DateTime second) {
  return first != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _attentionTitle(DashboardAttentionItem item) {
  return switch (item.type) {
    DashboardAttentionType.unpaid => 'Payment follow-up',
    DashboardAttentionType.unconfirmedAppointment => 'Booking to confirm',
    DashboardAttentionType.overdueTask => item.title,
    DashboardAttentionType.uncontactedLead => 'Client follow-up',
  };
}

String _attentionDetail(DashboardAttentionItem item) {
  return switch (item.type) {
    DashboardAttentionType.unpaid => item.detail,
    DashboardAttentionType.unconfirmedAppointment => item.detail,
    DashboardAttentionType.overdueTask =>
      item.detail == 'Overdue task' ? 'A task ready when you are' : item.detail,
    DashboardAttentionType.uncontactedLead => item.title.replaceFirst(
      'Contact ',
      '',
    ),
  };
}

IconData _attentionIcon(DashboardAttentionType type) {
  return switch (type) {
    DashboardAttentionType.unpaid => LucideIcons.banknote,
    DashboardAttentionType.unconfirmedAppointment => LucideIcons.calendarCheck,
    DashboardAttentionType.overdueTask => LucideIcons.listChecks,
    DashboardAttentionType.uncontactedLead => LucideIcons.user,
  };
}

List<Map<String, dynamic>> _upcomingJobs(
  List<Map<String, dynamic>> rows, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final jobs = rows.where((row) {
    final status = row['status']?.toString().toLowerCase() ?? 'scheduled';
    final start = _startTime(row);
    if (start == null) return false;
    if (status == 'completed' || status == 'cancelled' || status == 'no_show') {
      return false;
    }
    return start.isAfter(current);
  }).toList();

  jobs.sort((a, b) {
    final aStart = _startTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bStart = _startTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aStart.compareTo(bStart);
  });
  return jobs;
}

bool _isCalmFeedItem(BusinessFeedItem item) {
  if (item.priority == BusinessFeedPriority.attention) return false;
  return switch (item.type) {
    BusinessFeedItemType.bookingToday ||
    BusinessFeedItemType.bookingUpcoming ||
    BusinessFeedItemType.paymentReceived ||
    BusinessFeedItemType.expenseRecorded ||
    BusinessFeedItemType.noteCreated ||
    BusinessFeedItemType.weeklyTargetProgress => true,
    BusinessFeedItemType.invoiceUnpaid ||
    BusinessFeedItemType.invoiceOverdue ||
    BusinessFeedItemType.taskDue ||
    BusinessFeedItemType.taskOverdue ||
    BusinessFeedItemType.clientFollowUp ||
    BusinessFeedItemType.bookingRequestNew ||
    BusinessFeedItemType.quietDayDetected ||
    BusinessFeedItemType.dailySummary => false,
  };
}

String _calmFeedTitle(BusinessFeedItem item) {
  return switch (item.type) {
    BusinessFeedItemType.bookingToday => 'Job scheduled today',
    BusinessFeedItemType.bookingUpcoming => 'Upcoming job added',
    BusinessFeedItemType.paymentReceived => 'Invoice marked paid',
    BusinessFeedItemType.expenseRecorded => 'Expense recorded',
    BusinessFeedItemType.noteCreated => 'Note added',
    BusinessFeedItemType.weeklyTargetProgress => 'Progress updated',
    _ => item.title,
  };
}

IconData _iconForFeedItem(BusinessFeedItem item) {
  return switch (item.type) {
    BusinessFeedItemType.bookingToday ||
    BusinessFeedItemType.bookingUpcoming => LucideIcons.calendarDays,
    BusinessFeedItemType.paymentReceived => LucideIcons.banknote,
    BusinessFeedItemType.expenseRecorded => LucideIcons.receipt,
    BusinessFeedItemType.noteCreated => LucideIcons.stickyNote,
    BusinessFeedItemType.weeklyTargetProgress => LucideIcons.trendingUp,
    _ => LucideIcons.activity,
  };
}

DateTime? _startTime(Map<String, dynamic> appointment) =>
    DateTime.tryParse(appointment['start_time']?.toString() ?? '')?.toLocal();

DateTime? _endTime(Map<String, dynamic> appointment) =>
    DateTime.tryParse(appointment['end_time']?.toString() ?? '')?.toLocal();

String _clientName(Map<String, dynamic> appointment) =>
    appointment['contacts']?['name']?.toString() ?? 'Client';

String _serviceName(Map<String, dynamic> appointment) =>
    appointment['services']?['name']?.toString() ??
    appointment['title']?.toString() ??
    'Job';

String _friendlyDate(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  if (day == today) return 'Today';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
  return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]}';
}

String _relativeTime(DateTime timestamp) {
  final now = DateTime.now();
  if (timestamp.isAfter(now)) {
    final until = timestamp.difference(now);
    if (until.inHours < 24) return 'in ${until.inHours.clamp(1, 23)}h';
    return 'in ${until.inDays}d';
  }

  final difference = now.difference(timestamp);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(0, 59)}m ago';
  }
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return _friendlyDate(timestamp);
}
