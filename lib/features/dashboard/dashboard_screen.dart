import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import '../settings/settings_screen.dart';
import '../appointments/appointment_detail_screen.dart';

part 'dashboard_revenue_card.dart';

class DashboardScreen extends ConsumerWidget {
  final void Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final revenue = ref.watch(dashboardRevenueProvider);
    final focus = ref.watch(dashboardFocusProvider);
    final unreadNotifications = ref.watch(unreadNotificationsProvider);
    final todayAppts = ref.watch(todayAppointmentsProvider);
    final tasks = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workspaceProvider);
          ref.invalidate(dashboardRevenueProvider);
          ref.invalidate(dashboardFocusProvider);
          ref.invalidate(unreadNotificationsProvider);
          ref.invalidate(todayAppointmentsProvider);
          ref.invalidate(allTasksProvider);
          ref.invalidate(tasksProvider);
        },
        color: AppColors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            AppSpacing.pageTop,
            AppSpacing.pageX,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.t1,
                            letterSpacing: 0,
                          ),
                        ),
                        workspace.when(
                          data: (ws) => Text(
                            ws?['name'] ?? 'Your Business',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.t3,
                            ),
                          ),
                          loading: () => const Text(
                            '...',
                            style: TextStyle(color: AppColors.t3),
                          ),
                          error: (_, __) => const Text(
                            'Slate',
                            style: TextStyle(color: AppColors.t3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      SlateIconButton(
                        icon: LucideIcons.bell,
                        onTap: () => context.push('/notifications'),
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
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: AppColors.bg,
                                        width: 2,
                                      ),
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
                      const SizedBox(width: 10),
                      SlateIconButton(
                        icon: Icons.settings_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Revenue card ─────────────────────────────────────────
              revenue.when(
                data: (r) => _RevenueCard(
                  weekRevenue: r.weekTotal,
                  monthRevenue: r.monthTotal,
                  outstanding: r.outstanding,
                  revenueTarget: r.revenueTarget,
                ),
                loading: () => _skeletonBox(height: 200, radius: 20),
                error: (_, __) => _errorCard('Could not load revenue'),
              ),
              const SizedBox(height: 24),

              if (focus.isLoading || todayAppts.isLoading || tasks.isLoading)
                _skeletonBox(height: 172, radius: AppRadius.lg)
              else if (focus.hasError || todayAppts.hasError || tasks.hasError)
                _errorCard('Could not load today pulse')
              else
                _TodayPulsePanel(
                  focus: focus.value!,
                  appointments: todayAppts.value ?? const [],
                  tasks: tasks.value ?? const [],
                  onNavigate: onNavigate,
                ),
              const SizedBox(height: 24),

              // ── Today's schedule ─────────────────────────────────────
              SlateSectionHeader(
                label: "TODAY'S SCHEDULE",
                actionLabel: todayAppts.value?.isNotEmpty == true
                    ? 'See all'
                    : null,
                onAction: () => onNavigate(2),
              ),
              const SizedBox(height: 10),
              todayAppts.when(
                data: (appts) => appts.isEmpty
                    ? _emptyCard(
                        LucideIcons.calendar,
                        'No appointments today',
                        'Tap + to add one',
                      )
                    : SlateSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        radius: AppRadius.lg,
                        child: Column(
                          children: appts.take(4).map((appt) {
                            return _DashboardTimelineRow(
                              appt: appt,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AppointmentDetailScreen(
                                      appointment: appt,
                                    ),
                                  ),
                                ).then((_) {
                                  ref.invalidate(todayAppointmentsProvider);
                                  ref.invalidate(dashboardRevenueProvider);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                loading: () => _skeletonBox(height: 118),
                error: (_, __) => _errorCard('Could not load appointments'),
              ),
              const SizedBox(height: 24),

              // ── Tasks ────────────────────────────────────────────────
              SlateSectionHeader(
                label: 'TASKS',
                actionLabel: 'See all',
                onAction: () => onNavigate(4),
              ),
              const SizedBox(height: 10),
              tasks.when(
                data: (allTasks) {
                  final open = allTasks
                      .where((t) => t.status == 'open')
                      .take(5)
                      .toList();
                  if (open.isEmpty) {
                    return _emptyCard(
                      LucideIcons.checkCircle,
                      'No open tasks',
                      'Tap + to add one',
                    );
                  }
                  return SlateSurface(
                    padding: EdgeInsets.zero,
                    radius: AppRadius.lg,
                    child: Column(
                      children: open.asMap().entries.map((e) {
                        final i = e.key;
                        final t = e.value;
                        return _DashboardTaskRow(
                          task: t,
                          isLast: i == open.length - 1,
                          onToggle: () async {
                            final newStatus = t.status == 'done'
                                ? 'open'
                                : 'done';
                            await ref
                                .read(tasksRepositoryProvider)
                                .updateStatus(t.id, newStatus);
                            ref.invalidate(allTasksProvider);
                            ref.invalidate(tasksProvider);
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => _skeletonBox(height: 160, radius: 16),
                error: (_, __) => _errorCard('Could not load tasks'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox({double height = 80, double radius = AppRadius.md}) =>
      SlateLoadingBlock(height: height, radius: radius);

  Widget _errorCard(String message) => SlateErrorState(message: message);

  Widget _emptyCard(IconData icon, String title, String subtitle) =>
      SlateEmptyState(icon: icon, title: title, subtitle: subtitle);
}

class _TodayPulsePanel extends StatelessWidget {
  final DashboardFocus focus;
  final List<Map<String, dynamic>> appointments;
  final List<SlateTask> tasks;
  final void Function(int) onNavigate;

  const _TodayPulsePanel({
    required this.focus,
    required this.appointments,
    required this.tasks,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueTasks = tasks.where((task) {
      final due = task.dueDate;
      if (task.status == 'done' || due == null) return false;
      final dueDay = DateTime(due.year, due.month, due.day);
      return !dueDay.isAfter(today);
    }).length;
    final remainingToday = appointments.where((appt) {
      final status = appt['status']?.toString() ?? 'scheduled';
      if (status == 'completed' || status == 'cancelled') return false;
      final start = DateTime.tryParse(
        appt['start_time']?.toString() ?? '',
      )?.toLocal();
      return start == null || start.isAfter(now);
    }).length;

    return SlateSurface(
      padding: const EdgeInsets.all(16),
      radius: AppRadius.lg,
      color: AppColors.bgCard.withValues(alpha: 0.78),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.activity, size: 16, color: AppColors.t2),
              SizedBox(width: 8),
              Text(
                'TODAY PULSE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t3,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PulseAction(
                  icon: LucideIcons.inbox,
                  label: 'Requests',
                  value: focus.pendingBookingRequests.toString(),
                  detail: focus.pendingBookingRequests == 0
                      ? 'Clear'
                      : 'Review now',
                  color: focus.pendingBookingRequests > 0
                      ? AppColors.warning
                      : AppColors.t2,
                  emphasized: focus.pendingBookingRequests > 0,
                  onTap: () => context.push('/booking-requests'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PulseAction(
                  icon: LucideIcons.banknote,
                  label: 'Overdue',
                  value: '£${focus.overdueTotal.toStringAsFixed(0)}',
                  detail: focus.overduePayments == 0
                      ? 'Settled'
                      : '${focus.overduePayments} to chase',
                  color: focus.overduePayments > 0
                      ? AppColors.error
                      : AppColors.t2,
                  emphasized: focus.overduePayments > 0,
                  onTap: () => onNavigate(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PulseAction(
                  icon: LucideIcons.listChecks,
                  label: 'Due tasks',
                  value: dueTasks.toString(),
                  detail: dueTasks == 0 ? 'On track' : 'Finish today',
                  color: dueTasks > 0 ? AppColors.warning : AppColors.t2,
                  emphasized: dueTasks > 0,
                  onTap: () => onNavigate(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PulseAction(
                  icon: LucideIcons.calendarClock,
                  label: 'Today left',
                  value: remainingToday.toString(),
                  detail: remainingToday == 0 ? 'Day clear' : 'Bookings',
                  color: remainingToday > 0 ? AppColors.green : AppColors.t2,
                  onTap: () => onNavigate(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;
  final bool emphasized;
  final VoidCallback onTap;

  const _PulseAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized
          ? color.withValues(alpha: 0.1)
          : AppColors.t1.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: color),
                  const Spacer(),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppColors.t3.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t1,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t3,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTimelineRow extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onTap;

  const _DashboardTimelineRow({required this.appt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.tryParse(
      appt['start_time'] as String? ?? '',
    )?.toLocal();
    final endTime = DateTime.tryParse(
      appt['end_time'] as String? ?? '',
    )?.toLocal();
    final timeStr = startTime == null
        ? '--:--'
        : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = endTime == null
        ? null
        : '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final clientName = appt['contacts']?['name'] as String? ?? 'Walk-in';
    final serviceName = appt['services']?['name'] as String? ?? 'Appointment';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                    ),
                  ),
                  if (endStr != null)
                    Text(
                      endStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.t3,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.t1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.t3),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 15),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard task row ────────────────────────────────────────────────────────
class _DashboardTaskRow extends StatefulWidget {
  final SlateTask task;
  final bool isLast;
  final VoidCallback onToggle;

  const _DashboardTaskRow({
    required this.task,
    required this.isLast,
    required this.onToggle,
  });

  @override
  State<_DashboardTaskRow> createState() => _DashboardTaskRowState();
}

class _DashboardTaskRowState extends State<_DashboardTaskRow> {
  bool _toggling = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final priority = t.priority;
    final isDone = t.status == 'done';
    final dueDate = t.dueDate;
    final clientName = t.clientName;

    final priorityColor = priority == 'high'
        ? AppColors.error
        : priority == 'medium'
        ? AppColors.warning
        : AppColors.t3;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.isLast ? 16 : 0),
            onTap: _toggling
                ? null
                : () async {
                    setState(() => _toggling = true);
                    await Future.delayed(const Duration(milliseconds: 80));
                    widget.onToggle();
                    if (mounted) setState(() => _toggling = false);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.green : Colors.transparent,
                      border: Border.all(
                        color: isDone ? AppColors.green : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 12,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDone ? AppColors.t3 : AppColors.t1,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (clientName != null || dueDate != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (clientName != null) ...[
                                const Icon(
                                  LucideIcons.user,
                                  size: 10,
                                  color: AppColors.t3,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.t3,
                                  ),
                                ),
                                if (dueDate != null)
                                  const Text(
                                    '  ·  ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.t3,
                                    ),
                                  ),
                              ],
                              if (dueDate != null)
                                Text(
                                  _formatDue(dueDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isDueToday(dueDate)
                                        ? AppColors.warning
                                        : AppColors.t3,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!widget.isLast) Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  bool _isDueToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Due today';
    if (diff == -1) return 'Due yesterday';
    if (diff == 1) return 'Due tomorrow';
    if (diff < 0) return 'Overdue ${-diff}d';
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
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
