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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, color: AppColors.t3, size: 36),
            const SizedBox(height: 12),
            Text(
              emptyTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.t2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              emptySubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.t3),
            ),
            if (onEmptyAction != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onEmptyAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slateLight.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.t1.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Text(
                    '+ Add Appointment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.panelInk,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (!groupByDate) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.green,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
                    letterSpacing: 0.8,
                    color: AppColors.t3,
                  ),
                ),
              ),
              ...group.map(
                (appt) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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

    final isScheduled = status == 'scheduled';
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

    final initials = clientName
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    final timeStr = startDt != null
        ? endDt != null
              ? '${_time(startDt)} - ${_time(endDt)}'
              : _time(startDt)
        : '-';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isScheduled
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isScheduled
                        ? AppColors.greenDim
                        : AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isScheduled ? AppColors.green : AppColors.t3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.t1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.t3,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (price != null)
                      Text(
                        '£${(price as num).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.t1,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (showStatusBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.t3,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: isScheduled ? AppColors.green : AppColors.t3,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isScheduled ? AppColors.green : AppColors.t3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (recurrenceRule != null && recurrenceRule.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgInteract,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.repeat, size: 12, color: AppColors.t3),
                        SizedBox(width: 6),
                        Text(
                          'Repeats',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.t3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if ((isCancelled || isNoShow) && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCancelled ? 'Cancelled: $notes' : 'No show: $notes',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
