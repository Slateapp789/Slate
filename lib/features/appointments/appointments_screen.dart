import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/widgets/slate_ui.dart';
import 'add_appointment_screen.dart';
import 'appointment_detail_screen.dart';

part 'appointment_list_view.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bookings',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      letterSpacing: 0,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _calendarMode = !_calendarMode),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _calendarMode
                                ? AppColors.slateLight
                                : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.t1.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(
                            _calendarMode
                                ? LucideIcons.list
                                : LucideIcons.calendarDays,
                            color: _calendarMode
                                ? AppColors.panelInk
                                : AppColors.t2,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _addAppointment(
                          date: _calendarMode ? _selectedCalendarDate : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.slateLight,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.t1.withValues(alpha: 0.16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.plus,
                                color: AppColors.panelInk,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.panelInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                  child: _NextBookingCard(
                    booking: stats.nextBooking,
                    onTap: stats.nextBooking == null
                        ? () => _addAppointment()
                        : () => _openDetail(stats.nextBooking!),
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
                    color: AppColors.t1.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.t1.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.t1.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.t1.withValues(alpha: 0.14),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(3),
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.t1,
                    unselectedLabelColor: AppColors.t3,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

    final upcoming = appointments.where((appt) {
      final dt = _start(appt);
      return dt != null && dt.isAfter(now) && appt['status'] != 'cancelled';
    }).toList()..sort((a, b) => _start(a)!.compareTo(_start(b)!));

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
      nextBooking: upcoming.isEmpty ? null : upcoming.first,
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

    return GestureDetector(
      onTap: onTap,
      child: SlateSurface(
        radius: AppRadius.xl,
        color: AppColors.panelSoft,
        borderColor: AppColors.t1.withValues(alpha: 0.06),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.t1.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    start == null ? '--' : _shortTime(start),
                    style: const TextStyle(
                      color: AppColors.panelInk,
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
                      color: AppColors.panelInk.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT BOOKING',
                    style: TextStyle(
                      color: AppColors.t3,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    client,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      service,
                      if (location?.isNotEmpty == true) location!,
                      if (price != null && price > 0)
                        '£${price.toStringAsFixed(0)}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.t3, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              booking == null ? LucideIcons.plus : LucideIcons.chevronRight,
              color: AppColors.t3,
              size: 18,
            ),
          ],
        ),
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
