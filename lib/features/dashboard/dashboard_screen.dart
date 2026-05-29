import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
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
    final pulse = ref.watch(dashboardPulseProvider);
    final todayAppts = ref.watch(todayAppointmentsProvider);
    final tasks = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workspaceProvider);
          ref.invalidate(dashboardRevenueProvider);
          ref.invalidate(dashboardPulseProvider);
          ref.invalidate(todayAppointmentsProvider);
          ref.invalidate(allTasksProvider);
          ref.invalidate(tasksProvider);
        },
        color: AppColors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.t1,
                          letterSpacing: -0.8,
                        ),
                      ),
                      workspace.when(
                        data: (ws) => Text(
                          ws?['name'] ?? 'Your Business',
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
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.t2,
                        size: 20,
                      ),
                    ),
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

              pulse.when(
                data: (p) => _PulseGrid(pulse: p),
                loading: () => _skeletonBox(height: 134, radius: 18),
                error: (_, __) => _errorCard('Could not load business pulse'),
              ),
              const SizedBox(height: 24),

              // ── Today's schedule ─────────────────────────────────────
              _SectionHeader(
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
                    : SizedBox(
                        height: 118,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: appts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) => _AppointmentCard(
                            appt: appts[i],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentDetailScreen(
                                    appointment: appts[i],
                                  ),
                                ),
                              ).then((_) {
                                ref.invalidate(todayAppointmentsProvider);
                                ref.invalidate(dashboardRevenueProvider);
                              });
                            },
                          ),
                        ),
                      ),
                loading: () => _skeletonBox(height: 118),
                error: (_, __) => _errorCard('Could not load appointments'),
              ),
              const SizedBox(height: 24),

              // ── Tasks ────────────────────────────────────────────────
              _SectionHeader(
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
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
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

  Widget _skeletonBox({double height = 80, double radius = 16}) => Container(
    width: double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  Widget _errorCard(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.t3)),
  );

  Widget _emptyCard(IconData icon, String title, String subtitle) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.t3, size: 26),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, color: AppColors.t2)),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.t3),
        ),
      ],
    ),
  );
}

class _PulseGrid extends StatelessWidget {
  final DashboardPulse pulse;
  const _PulseGrid({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        _PulseTile(
          icon: LucideIcons.calendarClock,
          label: 'Upcoming',
          value: pulse.upcomingBookings.toString(),
        ),
        _PulseTile(
          icon: LucideIcons.inbox,
          label: 'Requests',
          value: pulse.pendingBookingRequests.toString(),
          highlight: pulse.pendingBookingRequests > 0,
          onTap: () => context.push('/booking-requests'),
        ),
        _PulseTile(
          icon: LucideIcons.repeat,
          label: 'Repeat clients',
          value: pulse.repeatClients.toString(),
        ),
        _PulseTile(
          icon: LucideIcons.clock3,
          label: 'Busiest',
          value: pulse.busiestPeriod,
          compact: true,
        ),
      ],
    );
  }
}

class _PulseTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool compact;
  final VoidCallback? onTap;

  const _PulseTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.green : AppColors.t2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.greenDim : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? AppColors.green : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const Spacer(),
                if (onTap != null)
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.t3,
                    size: 14,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: compact ? 1 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.t1,
                fontSize: compact ? 17 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.t3,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.label, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.t3,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onTap;
  const _AppointmentCard({required this.appt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.tryParse(
      appt['start_time'] as String? ?? '',
    )?.toLocal();
    final endTime = DateTime.tryParse(
      appt['end_time'] as String? ?? '',
    )?.toLocal();
    final timeStr = startTime != null
        ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final endStr = endTime != null
        ? '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'
        : null;
    final clientName = appt['contacts']?['name'] as String? ?? 'Walk-in';
    final serviceName = appt['services']?['name'] as String? ?? 'Appointment';
    final status = appt['status'] as String? ?? 'scheduled';
    final isScheduled = status == 'scheduled';
    final isCompleted = status == 'completed';

    final borderColor = isCompleted
        ? AppColors.success.withValues(alpha: 0.4)
        : isScheduled
        ? AppColors.green.withValues(alpha: 0.4)
        : AppColors.border;
    final bgColor = isCompleted
        ? AppColors.successDim
        : isScheduled
        ? AppColors.greenDim
        : AppColors.bgCard;
    final timeColor = isCompleted
        ? AppColors.success
        : isScheduled
        ? AppColors.green
        : AppColors.t3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                  ),
                ),
                if (isCompleted)
                  const Icon(
                    LucideIcons.checkCircle,
                    size: 13,
                    color: AppColors.success,
                  ),
              ],
            ),
            if (endStr != null) ...[
              const SizedBox(height: 1),
              Text(
                '– $endStr',
                style: TextStyle(
                  fontSize: 10,
                  color: timeColor.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              clientName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.t1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              serviceName,
              style: const TextStyle(fontSize: 11, color: AppColors.t3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: timeColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
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
