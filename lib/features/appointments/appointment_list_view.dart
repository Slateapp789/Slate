part of 'appointments_screen.dart';

class _AppointmentListView extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Function(Map<String, dynamic>) onTap;
  final VoidCallback onRefresh;
  final bool groupByDate;
  final bool showStatusBadge;

  const _AppointmentListView({
    required this.appointments,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
    required this.onRefresh,
    this.groupByDate = false,
    this.showStatusBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.accentPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                0,
                AppSpacing.pageX,
                AppSpacing.bottomNavClearance,
              ),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WorkloopEmptyState(
                        icon: emptyIcon,
                        title: emptyTitle,
                        subtitle: emptySubtitle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!groupByDate) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.accentPrimary,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            0,
            AppSpacing.pageX,
            AppSpacing.bottomNavClearance,
          ),
          itemCount: appointments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 2),
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
      color: AppColors.accentPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          0,
          AppSpacing.pageX,
          AppSpacing.bottomNavClearance,
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
                    fontWeight: FontWeight.w600,
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
    final tomorrow = nextBookingCalendarDay(today);
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

class _BookingCalendarView extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final DateTime selectedDate;
  final List<Map<String, dynamic>> selectedDayAppointments;
  final ValueChanged<DateTime> onDateSelected;
  final Function(Map<String, dynamic>) onTap;
  final VoidCallback onRefresh;
  final VoidCallback onEmptyAction;

  const _BookingCalendarView({
    required this.appointments,
    required this.selectedDate,
    required this.selectedDayAppointments,
    required this.onDateSelected,
    required this.onTap,
    required this.onRefresh,
    required this.onEmptyAction,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.accentPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          0,
          AppSpacing.pageX,
          AppSpacing.bottomNavClearance,
        ),
        children: [
          _MonthCalendar(
            selectedDate: selectedDate,
            countForDay: _countForDay,
            onDateSelected: onDateSelected,
          ),
          const SizedBox(height: 16),
          _DayPlanHeader(
            date: selectedDate,
            appointments: selectedDayAppointments,
            onAddBooking: onEmptyAction,
          ),
          const SizedBox(height: 12),
          if (selectedDayAppointments.isEmpty)
            const WorkloopEmptyState(
              icon: LucideIcons.calendarPlus,
              title: 'No bookings this day',
              subtitle:
                  'Use the gap for admin or choose Add in the day heading.',
            )
          else
            ...selectedDayAppointments.map(
              (appt) => _AppointmentCard(
                appt: appt,
                onTap: () => onTap(appt),
                showStatusBadge: true,
              ),
            ),
        ],
      ),
    );
  }

  int _countForDay(DateTime day) {
    final start = _dateOnly(day);
    final end = nextBookingCalendarDay(start);
    return appointments.where((appt) {
      final dt = _start(appt);
      return dt != null &&
          !dt.isBefore(start) &&
          dt.isBefore(end) &&
          appt['status'] != 'cancelled';
    }).length;
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final int Function(DateTime day) countForDay;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthCalendar({
    required this.selectedDate,
    required this.countForDay,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateTime(selectedDate.year, selectedDate.month);
    final firstGridDay = month.subtract(Duration(days: month.weekday - 1));
    final days = List.generate(42, (index) {
      return firstGridDay.add(Duration(days: index));
    });
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SlateSurface(
      radius: AppRadius.lg,
      color: AppColors.t1.withValues(alpha: 0.022),
      borderColor: AppColors.border.withValues(alpha: 0.54),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Previous month',
                child: ExcludeSemantics(
                  child: IconButton(
                    tooltip: 'Previous month',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouch,
                      minHeight: AppSpacing.minTouch,
                    ),
                    onPressed: () => onDateSelected(
                      DateTime(selectedDate.year, selectedDate.month - 1, 1),
                    ),
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _monthLabel(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    AppSpacing.minTouch,
                    AppSpacing.minTouch,
                  ),
                ),
                onPressed: () => onDateSelected(_dateOnly(DateTime.now())),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: AppColors.modCalendar,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Next month',
                child: ExcludeSemantics(
                  child: IconButton(
                    tooltip: 'Next month',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouch,
                      minHeight: AppSpacing.minTouch,
                    ),
                    onPressed: () => onDateSelected(
                      DateTime(selectedDate.year, selectedDate.month + 1, 1),
                    ),
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.t3,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            itemCount: days.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final selected = _dateOnly(date) == _dateOnly(selectedDate);
              final inMonth = date.month == month.month;
              final count = countForDay(date);
              void handleTap() {
                SlateHaptics.tap();
                onDateSelected(_dateOnly(date));
              }

              return Semantics(
                button: true,
                selected: selected,
                label: '${date.day}/${date.month}/${date.year}',
                value: '$count booking${count == 1 ? '' : 's'}',
                onTap: handleTap,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: handleTap,
                    child: AnimatedContainer(
                      key: ValueKey(Theme.of(context).brightness),
                      duration: AppMotion.fast,
                      curve: AppMotion.curve,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentPrimaryStrong.withValues(
                                alpha: 0.72,
                              )
                            : count > 0
                            ? AppColors.accentPrimaryStrong.withValues(
                                alpha: 0.20,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: selected
                              ? AppColors.accentPrimaryStrong.withValues(
                                  alpha: 0.74,
                                )
                              : AppColors.t1.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: selected
                                  ? AppColors.panelInk
                                  : inMonth
                                  ? AppColors.t1
                                  : AppColors.t3.withValues(alpha: 0.42),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (count > 0)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.panelInk
                                    : AppColors.accentPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _monthLabel(DateTime month) {
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
  return '${months[month.month - 1]} ${month.year}';
}

class _DayPlanHeader extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> appointments;
  final VoidCallback onAddBooking;

  const _DayPlanHeader({
    required this.date,
    required this.appointments,
    required this.onAddBooking,
  });

  @override
  Widget build(BuildContext context) {
    final scheduled = appointments
        .where((appt) => appt['status'] == 'scheduled')
        .length;
    final completed = appointments
        .where((appt) => appt['status'] == 'completed')
        .length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _friendlyDate(date),
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                appointments.isEmpty
                    ? 'No scheduled work'
                    : '$scheduled to go, $completed done',
                style: const TextStyle(color: AppColors.t3, fontSize: 12),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onAddBooking,
          icon: const Icon(LucideIcons.plus, size: 15),
          label: const Text('Add'),
        ),
      ],
    );
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
    final serviceName =
        appt['services']?['name'] as String? ??
        appt['title'] as String? ??
        'Booking';
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

    final location = (appt['location'] as String? ?? '').trim();
    final timing = endStr == null ? startStr : '$startStr–$endStr';

    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isCompleted
                ? LucideIcons.checkCircle2
                : isCancelled
                ? LucideIcons.xCircle
                : isNoShow
                ? LucideIcons.alertCircle
                : LucideIcons.calendarClock,
            size: 18,
            color: statusColor,
          ),
        ),
      ),
      title: Text(
        clientName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.t1,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              timing,
              serviceName,
              if (location.isNotEmpty) location,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.t2,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showStatusBadge ||
              (recurrenceRule != null && recurrenceRule.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
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
            const SizedBox(height: AppSpacing.xs),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (price != null) ...[
            Text(
              formatPounds(price as num),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.t1,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
        ],
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
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyDate(DateTime date) {
  final today = _dateOnly(DateTime.now());
  final day = _dateOnly(date);
  if (day == today) return 'Today';
  if (day == nextBookingCalendarDay(today)) return 'Tomorrow';
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
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}
