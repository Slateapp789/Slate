import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/business_feed_item.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/business_feed_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/utils/date_format.dart';
import '../../shared/widgets/slate_ui.dart';
import '../appointments/appointment_detail_screen.dart';

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
    final appointments = ref.watch(appointmentsProvider);
    final finance = ref.watch(financeSummaryProvider);
    final feed = ref.watch(businessFeedProvider);
    final tasks = ref.watch(allTasksProvider);
    final notes = ref.watch(allNotesProvider);
    final displayName = _displayName();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
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
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            AppSpacing.pageTop,
            AppSpacing.pageX,
            AppSpacing.bottomNavClearance,
          ),
          children: [
            _DashboardGreeting(
              greeting: displayName == null
                  ? _greeting
                  : '$_greeting, $displayName',
              subtitle: 'Here\'s what\'s happening today.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _QuickAccessRow(
              taskSummary: tasks.maybeWhen(
                data: (items) {
                  final open = items
                      .where(
                        (task) =>
                            task.status != 'done' && task.status != 'completed',
                      )
                      .length;
                  return open == 1 ? '1 open' : '$open open';
                },
                orElse: () => 'View tasks',
              ),
              noteSummary: notes.maybeWhen(
                data: (items) =>
                    items.length == 1 ? '1 note' : '${items.length} notes',
                orElse: () => 'View notes',
              ),
              onOpenTasks: () => onNavigate(4),
              onOpenNotes: () => onNavigate(5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _IncomeThisMonthCard(finance: finance),
            const SizedBox(height: AppSpacing.xxl),
            _UpcomingJobsSection(
              appointments: appointments,
              onOpenJob: (appointment) =>
                  _openAppointment(context, ref, appointment),
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
    );
  }

  String? _displayName() {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final raw =
        metadata?['full_name'] ??
        metadata?['name'] ??
        metadata?['display_name'];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value.split(RegExp(r'\s+')).first;
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
            color: AppColors.t3,
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
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: AppColors.border.withValues(alpha: 0.58),
        ),
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
      child: InkWell(
        onTap: () {
          SlateHaptics.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
              const Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: AppColors.t3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeThisMonthCard extends StatelessWidget {
  final AsyncValue<FinanceSummary> finance;

  const _IncomeThisMonthCard({required this.finance});

  @override
  Widget build(BuildContext context) {
    return finance.when(
      loading: () => const SlateLoadingBlock(height: 132, radius: AppRadius.lg),
      error: (_, __) => const SlateErrorState(message: 'Could not load income'),
      data: (summary) => WorkloopSurface(
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: AppColors.t1.withValues(alpha: 0.04),
        borderColor: AppColors.border.withValues(alpha: 0.46),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Income this month',
              style: TextStyle(
                color: AppColors.t3,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '£${summary.thisMonthPaid.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.t1,
                fontSize: 46,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Received so far in this calendar month.',
              style: TextStyle(
                color: AppColors.t3,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingJobsSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final ValueChanged<Map<String, dynamic>> onOpenJob;

  const _UpcomingJobsSection({
    required this.appointments,
    required this.onOpenJob,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Upcoming jobs',
      child: appointments.when(
        loading: () =>
            const SlateLoadingBlock(height: 180, radius: AppRadius.lg),
        error: (_, __) =>
            const SlateErrorState(message: 'Could not load upcoming jobs'),
        data: (rows) {
          final jobs = _upcomingJobs(rows).take(5).toList();
          if (jobs.isEmpty) {
            return const WorkloopEmptyState(
              icon: LucideIcons.calendarDays,
              title: 'No upcoming jobs yet.',
              subtitle: 'Your schedule is clear.',
            );
          }

          return Column(
            children: [
              for (final job in jobs) ...[
                _UpcomingJobRow(job: job, onTap: () => onOpenJob(job)),
              ],
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

  const _UpcomingJobRow({required this.job, required this.onTap});

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
        [date, if (time != null) time, service].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t3,
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
      title: 'Feed',
      actionLabel: 'View all',
      onAction: onViewAllFeed,
      child: feed.when(
        loading: () =>
            const SlateLoadingBlock(height: 190, radius: AppRadius.lg),
        error: (_, __) => const SlateErrorState(message: 'Could not load feed'),
        data: (items) {
          final calmItems = items.where(_isCalmFeedItem).take(6).toList();
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
          color: AppColors.t3,
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

  const _DashboardSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
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
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 20,
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

List<Map<String, dynamic>> _upcomingJobs(List<Map<String, dynamic>> rows) {
  final now = DateTime.now();
  final jobs = rows.where((row) {
    final status = row['status']?.toString().toLowerCase() ?? 'scheduled';
    final start = _startTime(row);
    if (start == null) return false;
    if (status == 'completed' || status == 'cancelled' || status == 'no_show') {
      return false;
    }
    return start.isAfter(now);
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
