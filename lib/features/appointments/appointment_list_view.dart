part of 'appointments_screen.dart';

class _AppointmentListView extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Function(Map<String, dynamic>) onTap;
  final VoidCallback onRefresh;
  final VoidCallback? onEmptyAction;
  final bool groupByDate;
  final bool showStatusBadge;

  const _AppointmentListView({
    required this.appointments,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
    required this.onRefresh,
    this.onEmptyAction,
    this.groupByDate = false,
    this.showStatusBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SlateEmptyState(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
              if (onEmptyAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onEmptyAction,
                    icon: const Icon(LucideIcons.calendarPlus, size: 17),
                    label: const Text(
                      'Add Appointment',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!groupByDate) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.green,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            0,
            AppSpacing.pageX,
            100,
          ),
          itemCount: appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (_, i) => _AppointmentCard(
            appt: appointments[i],
            onTap: () => onTap(appointments[i]),
            showStatusBadge: showStatusBadge,
          ),
        ),
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final appt in appointments) {
      final dt = DateTime.tryParse(
        appt['start_time'] as String? ?? '',
      )?.toLocal();
      final key = dt != null ? _dateKey(dt) : 'Unknown';
      grouped.putIfAbsent(key, () => []).add(appt);
    }

    final keys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.green,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          0,
          AppSpacing.pageX,
          100,
        ),
        itemCount: keys.length,
        itemBuilder: (_, i) {
          final key = keys[i];
          final group = grouped[key]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: AppColors.t3,
                  ),
                ),
              ),
              ...group.map(
                (appt) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _AppointmentCard(
                    appt: appt,
                    onTap: () => onTap(appt),
                    showStatusBadge: showStatusBadge,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  String _dateKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;

    if (d == today) return 'TODAY';
    if (d == tomorrow) return 'TOMORROW';
    if (diff > 0 && diff < 7) {
      const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return days[dt.weekday - 1];
    }
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onTap;
  final bool showStatusBadge;

  const _AppointmentCard({
    required this.appt,
    required this.onTap,
    this.showStatusBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = appt['status'] as String? ?? 'scheduled';
    final clientName = appt['contacts']?['name'] as String? ?? 'Walk-in';
    final serviceName = appt['services']?['name'] as String? ?? 'Appointment';
    final startDt = DateTime.tryParse(
      appt['start_time'] as String? ?? '',
    )?.toLocal();
    final endDt = DateTime.tryParse(
      appt['end_time'] as String? ?? '',
    )?.toLocal();
    final price = appt['price'];
    final notes = appt['notes'] as String? ?? '';
    final recurrenceRule = appt['recurrence_rule'] as String?;

    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';
    final isNoShow = status == 'no_show';

    final statusColor = isCompleted
        ? AppColors.success
        : isCancelled
        ? AppColors.error
        : isNoShow
        ? AppColors.warning
        : AppColors.green;

    final startStr = startDt != null ? _time(startDt) : '--:--';
    final endStr = endDt != null ? _time(endDt) : null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.t1.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      height: 1,
                    ),
                  ),
                  if (endStr != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      endStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.t3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.18),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 1,
                    height:
                        ((isCancelled || isNoShow) && notes.isNotEmpty) ||
                            (recurrenceRule != null &&
                                recurrenceRule.isNotEmpty)
                        ? 72
                        : 42,
                    color: AppColors.t1.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.t1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              serviceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.t3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (price != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '£${(price as num).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.t1,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.t3,
                        size: 16,
                      ),
                    ],
                  ),
                  if (showStatusBadge ||
                      (recurrenceRule != null &&
                          recurrenceRule.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (showStatusBadge)
                          _AppointmentPill(
                            label: status.replaceAll('_', ' '),
                            icon: isCompleted
                                ? LucideIcons.checkCircle
                                : isCancelled
                                ? LucideIcons.xCircle
                                : isNoShow
                                ? LucideIcons.alertCircle
                                : LucideIcons.clock,
                            color: statusColor,
                          ),
                        if (recurrenceRule != null && recurrenceRule.isNotEmpty)
                          const _AppointmentPill(
                            label: 'Repeats',
                            icon: LucideIcons.repeat,
                            color: AppColors.t3,
                          ),
                      ],
                    ),
                  ],
                  if ((isCancelled || isNoShow) && notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      isCancelled ? 'Cancelled: $notes' : 'No show: $notes',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _AppointmentPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _AppointmentPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
