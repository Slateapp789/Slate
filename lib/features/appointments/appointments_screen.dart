import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/widgets/slate_ui.dart';
import '../public_profile/booking_requests_screen.dart';
import 'add_appointment_screen.dart';
import 'appointment_detail_screen.dart';

part 'appointment_list_view.dart';

enum _BookingsView { schedule, requests }

Map<String, dynamic>? selectNextBooking(
  List<Map<String, dynamic>> appointments, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final upcoming =
      appointments.indexed.where((entry) {
        final dt = _start(entry.$2);
        return dt != null &&
            !dt.isBefore(current) &&
            entry.$2['status'] != 'cancelled';
      }).toList()..sort((a, b) {
        final startCompare = _start(a.$2)!.compareTo(_start(b.$2)!);
        if (startCompare != 0) return startCompare;
        return a.$1.compareTo(b.$1);
      });
  return upcoming.isEmpty ? null : upcoming.first.$2;
}

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedCalendarDate = _dateOnly(DateTime.now());
  bool _calendarMode = false;
  _BookingsView _view = _BookingsView.schedule;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openDetail(Map<String, dynamic> appt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appt),
      ),
    );
    ref.invalidate(appointmentsProvider);
  }

  Future<void> _addAppointment({DateTime? date}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(initialDate: date),
      ),
    );
    ref.invalidate(appointmentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final bookingRequests = ref.watch(bookingRequestsProvider);
    final activeRequestCount = bookingRequests.maybeWhen(
      data: (items) => _activeRequests(items).length,
      orElse: () => 0,
    );
    final headerStats = appointments.maybeWhen(
      data: (items) => _BookingStats.from(items),
      orElse: () => const _BookingStats.empty(),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.lg,
                AppSpacing.pageX,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: WorkloopPageHeader(
                      icon: LucideIcons.calendarDays,
                      title: 'Bookings',
                      subtitle: 'Plan the day and keep bookings moving.',
                      color: AppColors.modCalendar,
                      trailing: _view == _BookingsView.schedule
                          ? WorkloopIconButton(
                              icon: _calendarMode
                                  ? LucideIcons.list
                                  : LucideIcons.calendarDays,
                              semanticLabel: _calendarMode
                                  ? 'Show list'
                                  : 'Show calendar',
                              color: AppColors.modCalendar,
                              backgroundColor: AppColors.modCalendar.withValues(
                                alpha: 0.10,
                              ),
                              onTap: () => setState(
                                () => _calendarMode = !_calendarMode,
                              ),
                            )
                          : null,
                      metrics: [
                        WorkloopMetricItem(
                          value: _calendarMode ? 'Calendar' : 'List',
                          label: 'Mode',
                          color: AppColors.modCalendar,
                        ),
                        WorkloopMetricItem(
                          value: '${headerStats.todayRemaining}',
                          label: 'Today',
                          color: AppColors.modCalendar,
                        ),
                        WorkloopMetricItem(
                          value: '${headerStats.weekBookings}',
                          label: 'Week',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: _BookingsViewSwitch(
                selected: _view,
                requestCount: activeRequestCount,
                onSelected: (view) => setState(() {
                  _view = view;
                  if (view == _BookingsView.requests) _calendarMode = false;
                }),
              ),
            ),
            const SizedBox(height: 16),

            if (_view == _BookingsView.requests)
              Expanded(
                child: bookingRequests.when(
                  loading: () => _skeletonList(),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageX,
                    ),
                    child: SlateErrorState(message: 'Could not load requests'),
                  ),
                  data: (items) {
                    final active = _activeRequests(items);
                    if (active.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageX,
                        ),
                        child: WorkloopEmptyState(
                          icon: LucideIcons.inbox,
                          title: 'No active requests',
                          subtitle:
                              'New public profile requests will appear here',
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.accentPrimary,
                      onRefresh: () async =>
                          ref.invalidate(bookingRequestsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageX,
                          0,
                          AppSpacing.pageX,
                          110,
                        ),
                        itemCount: active.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _InlineRequestCard(
                          request: active[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingRequestsScreen(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else ...[
              appointments.when(
                data: (data) {
                  final stats = _BookingStats.from(data);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageX,
                      0,
                      AppSpacing.pageX,
                      AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        _BookingModePanel(
                          calendarMode: _calendarMode,
                          stats: stats,
                          onToggle: () =>
                              setState(() => _calendarMode = !_calendarMode),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _NextBookingCard(
                          booking: stats.nextBooking,
                          onTap: stats.nextBooking == null
                              ? () => _addAppointment()
                              : () => _openDetail(stats.nextBooking!),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              if (!_calendarMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageX,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.t1.withValues(alpha: 0.028),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.54),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.accentPrimaryStrong.withValues(
                          alpha: 0.34,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.accentPrimaryStrong.withValues(
                            alpha: 0.54,
                          ),
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(3),
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.t1,
                      unselectedLabelColor: AppColors.t3,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      tabs: const [
                        Tab(text: 'Today'),
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Past'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Expanded(
                child: appointments.when(
                  loading: () => _skeletonList(),
                  error: (e, _) =>
                      _errorState(() => ref.invalidate(appointmentsProvider)),
                  data: (data) {
                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);
                    final todayEnd = todayStart.add(const Duration(days: 1));

                    final today = _appointmentsForDay(data, todayStart);

                    final upcoming = data.where((a) {
                      final dt = DateTime.tryParse(
                        a['start_time'] as String? ?? '',
                      )?.toLocal();
                      return dt != null &&
                          dt.isAfter(todayEnd) &&
                          a['status'] != 'cancelled';
                    }).toList();

                    final past =
                        data.where((a) {
                          final dt = DateTime.tryParse(
                            a['start_time'] as String? ?? '',
                          )?.toLocal();
                          final status = a['status'] as String? ?? '';
                          return (dt != null && dt.isBefore(todayStart)) ||
                              status == 'cancelled' ||
                              status == 'no_show';
                        }).toList()..sort((a, b) {
                          final dtA = DateTime.tryParse(
                            a['start_time'] as String? ?? '',
                          );
                          final dtB = DateTime.tryParse(
                            b['start_time'] as String? ?? '',
                          );
                          if (dtA == null || dtB == null) return 0;
                          return dtB.compareTo(dtA);
                        });
                    final selectedDayAppointments = _appointmentsForDay(
                      data,
                      _selectedCalendarDate,
                    );

                    if (_calendarMode) {
                      return _BookingCalendarView(
                        appointments: data,
                        selectedDate: _selectedCalendarDate,
                        selectedDayAppointments: selectedDayAppointments,
                        onDateSelected: (date) {
                          setState(() => _selectedCalendarDate = date);
                        },
                        onTap: _openDetail,
                        onRefresh: () => ref.invalidate(appointmentsProvider),
                        onEmptyAction: () => _addAppointment(),
                      );
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _AppointmentListView(
                          appointments: today,
                          emptyIcon: LucideIcons.calendarDays,
                          emptyTitle: 'Nothing scheduled today',
                          emptySubtitle: 'Tap New to add a booking',
                          onTap: _openDetail,
                          onRefresh: () => ref.invalidate(appointmentsProvider),
                          onEmptyAction: () =>
                              _addAppointment(date: _selectedCalendarDate),
                          groupByDate: false,
                        ),
                        _AppointmentListView(
                          appointments: upcoming,
                          emptyIcon: LucideIcons.calendarClock,
                          emptyTitle: 'No upcoming bookings',
                          emptySubtitle: 'Your future schedule is clear',
                          onTap: _openDetail,
                          onRefresh: () => ref.invalidate(appointmentsProvider),
                          groupByDate: true,
                        ),
                        _AppointmentListView(
                          appointments: past,
                          emptyIcon: LucideIcons.history,
                          emptyTitle: 'No past bookings',
                          emptySubtitle: 'Completed work will appear here',
                          onTap: _openDetail,
                          onRefresh: () => ref.invalidate(appointmentsProvider),
                          groupByDate: true,
                          showStatusBadge: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        40,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) =>
          const SlateLoadingBlock(height: 80, radius: AppRadius.md),
    );
  }

  Widget _errorState(VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
      child: SlateErrorState(message: 'Could not load bookings'),
    );
  }

  List<Map<String, dynamic>> _appointmentsForDay(
    List<Map<String, dynamic>> appointments,
    DateTime day,
  ) {
    final start = _dateOnly(day);
    final end = start.add(const Duration(days: 1));
    return appointments.where((a) {
      final dt = DateTime.tryParse(a['start_time'] as String? ?? '')?.toLocal();
      return dt != null &&
          !dt.isBefore(start) &&
          dt.isBefore(end) &&
          a['status'] != 'cancelled';
    }).toList();
  }
}

List<BookingRequest> _activeRequests(List<BookingRequest> items) {
  final active = items
      .where((item) => item.status == 'pending' || item.status == 'contacted')
      .toList();
  const statusOrder = {'pending': 0, 'contacted': 1};
  active.sort((a, b) {
    final statusCompare = (statusOrder[a.status] ?? 9).compareTo(
      statusOrder[b.status] ?? 9,
    );
    if (statusCompare != 0) return statusCompare;
    final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bCreated.compareTo(aCreated);
  });
  return active;
}

class _BookingStats {
  final int todayTotal;
  final int todayCompleted;
  final int todayRemaining;
  final int overdueUnfinished;
  final int weekBookings;
  final double todayRevenue;
  final double weekValue;
  final Map<String, dynamic>? nextBooking;

  const _BookingStats({
    required this.todayTotal,
    required this.todayCompleted,
    required this.todayRemaining,
    required this.overdueUnfinished,
    required this.weekBookings,
    required this.todayRevenue,
    required this.weekValue,
    required this.nextBooking,
  });

  const _BookingStats.empty()
    : todayTotal = 0,
      todayCompleted = 0,
      todayRemaining = 0,
      overdueUnfinished = 0,
      weekBookings = 0,
      todayRevenue = 0,
      weekValue = 0,
      nextBooking = null;

  factory _BookingStats.from(List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final todayAppointments = appointments.where((appt) {
      final dt = _start(appt);
      return dt != null &&
          !dt.isBefore(today) &&
          dt.isBefore(tomorrow) &&
          appt['status'] != 'cancelled';
    }).toList();

    final weekAppointments = appointments.where((appt) {
      final dt = _start(appt);
      return dt != null &&
          !dt.isBefore(today) &&
          dt.isBefore(weekEnd) &&
          appt['status'] != 'cancelled';
    }).toList();

    final overdue = appointments.where((appt) {
      final dt = _end(appt) ?? _start(appt);
      final status = appt['status'] as String? ?? 'scheduled';
      return dt != null && dt.isBefore(now) && status == 'scheduled';
    }).length;

    return _BookingStats(
      todayTotal: todayAppointments.length,
      todayCompleted: todayAppointments
          .where((appt) => appt['status'] == 'completed')
          .length,
      todayRemaining: todayAppointments
          .where((appt) => appt['status'] == 'scheduled')
          .length,
      overdueUnfinished: overdue,
      weekBookings: weekAppointments.length,
      todayRevenue: todayAppointments
          .where((appt) => appt['status'] == 'completed')
          .fold<double>(0, (sum, appt) => sum + _price(appt)),
      weekValue: weekAppointments.fold<double>(
        0,
        (sum, appt) => sum + _price(appt),
      ),
      nextBooking: selectNextBooking(appointments, now: now),
    );
  }
}

class _BookingModePanel extends StatelessWidget {
  final bool calendarMode;
  final _BookingStats stats;
  final VoidCallback onToggle;

  const _BookingModePanel({
    required this.calendarMode,
    required this.stats,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onToggle,
      leading: Icon(
        calendarMode ? LucideIcons.calendarDays : LucideIcons.list,
        color: AppColors.modCalendar,
        size: 22,
      ),
      title: Text(
        calendarMode ? 'Calendar' : 'List',
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      subtitle: Text(
        '${stats.todayRemaining} left today · £${stats.weekValue.toStringAsFixed(0)} this week',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(LucideIcons.repeat2, color: AppColors.t3, size: 18),
    );
  }
}

class _BookingsViewSwitch extends StatelessWidget {
  final _BookingsView selected;
  final int requestCount;
  final ValueChanged<_BookingsView> onSelected;

  const _BookingsViewSwitch({
    required this.selected,
    required this.requestCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopSegmentedControl<_BookingsView>(
      selected: selected,
      onChanged: onSelected,
      segments: [
        const WorkloopSegment(value: _BookingsView.schedule, label: 'Schedule'),
        WorkloopSegment(
          value: _BookingsView.requests,
          label: 'Requests',
          badge: requestCount > 0 ? '$requestCount' : null,
        ),
      ],
    );
  }
}

class _InlineRequestCard extends StatelessWidget {
  final BookingRequest request;
  final VoidCallback onTap;

  const _InlineRequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final service = request.serviceName?.trim();
    final preferred = request.preferredTimeText?.trim();
    final subtitle = [
      if (service?.isNotEmpty == true) service!,
      if (preferred?.isNotEmpty == true) preferred!,
      if (service?.isNotEmpty != true && preferred?.isNotEmpty != true)
        request.phone,
    ].join(' · ');
    final statusColor = request.status == 'pending'
        ? AppColors.warning
        : AppColors.green;

    return WorkloopListRow(
      onTap: onTap,
      leading: Icon(LucideIcons.inbox, color: statusColor, size: 18),
      title: Row(
        children: [
          Expanded(
            child: Text(
              request.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.t1,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RequestStatusBadge(
            label: request.status == 'pending' ? 'New' : 'Contacted',
            color: statusColor,
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.t3, fontSize: 12),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.t3,
        size: 17,
      ),
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RequestStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  final Map<String, dynamic>? booking;
  final VoidCallback onTap;

  const _NextBookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = booking == null ? null : _start(booking!);
    final end = booking == null ? null : _end(booking!);
    final client = booking?['contacts']?['name'] as String? ?? 'No booking set';
    final service =
        booking?['services']?['name'] as String? ??
        booking?['title'] as String? ??
        'Add a booking';
    final location = booking?['location'] as String?;
    final price = booking == null ? null : _price(booking!);

    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: SizedBox(
        width: 58,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              start == null ? '--' : _shortTime(start),
              style: const TextStyle(
                color: AppColors.t1,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              start == null || end == null
                  ? 'new'
                  : '${end.difference(start).inMinutes}m',
              style: TextStyle(
                color: AppColors.t1.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      title: const Text(
        'NEXT BOOKING',
        style: TextStyle(
          color: AppColors.t3,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxs),
          Text(
            client,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            [
              service,
              if (location?.isNotEmpty == true) location!,
              if (price != null && price > 0) '£${price.toStringAsFixed(0)}',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.t3, fontSize: 12),
          ),
        ],
      ),
      trailing: Icon(
        booking == null ? LucideIcons.plus : LucideIcons.chevronRight,
        color: AppColors.modCalendar,
        size: 18,
      ),
    );
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime? _start(Map<String, dynamic> appt) =>
    DateTime.tryParse(appt['start_time'] as String? ?? '')?.toLocal();

DateTime? _end(Map<String, dynamic> appt) =>
    DateTime.tryParse(appt['end_time'] as String? ?? '')?.toLocal();

double _price(Map<String, dynamic> appt) =>
    (appt['price'] as num?)?.toDouble() ?? 0;

String _shortTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
