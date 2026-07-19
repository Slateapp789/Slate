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
  int _selectedListTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_selectedListTab == _tabController.index) return;
    setState(() => _selectedListTab = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageX,
                          AppSpacing.xxl,
                          AppSpacing.pageX,
                          0,
                        ),
                        child: _BookingsHeader(onAdd: _addAppointment),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageX,
                        ),
                        child: _BookingsViewSwitch(
                          selected: _view,
                          requestCount: activeRequestCount,
                          onSelected: (view) => setState(() {
                            _view = view;
                            if (view == _BookingsView.requests) {
                              _calendarMode = false;
                            }
                          }),
                        ),
                      ),
                      if (_view == _BookingsView.schedule) ...[
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.pageX,
                          ),
                          child: WorkloopNavigationControl<bool>(
                            selected: _calendarMode,
                            onChanged: (calendarMode) =>
                                setState(() => _calendarMode = calendarMode),
                            color: AppColors.accentPrimary,
                            segments: const [
                              WorkloopSegment(value: false, label: 'List'),
                              WorkloopSegment(value: true, label: 'Calendar'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        appointments.when(
                          data: (data) {
                            final nextBooking = selectNextBooking(data);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.pageX,
                              ),
                              child: _NextBookingCard(
                                booking: nextBooking,
                                onTap: nextBooking == null
                                    ? () => _addAppointment()
                                    : () => _openDetail(nextBooking),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        if (!_calendarMode) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.pageX,
                            ),
                            child: WorkloopNavigationControl<int>(
                              selected: _selectedListTab,
                              onChanged: (index) =>
                                  _tabController.animateTo(index),
                              color: AppColors.accentPrimary,
                              segments: const [
                                WorkloopSegment(value: 0, label: 'Today'),
                                WorkloopSegment(value: 1, label: 'Upcoming'),
                                WorkloopSegment(value: 2, label: 'Past'),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ],
              body: _view == _BookingsView.requests
                  ? bookingRequests.when(
                      loading: () => _skeletonList(),
                      error: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageX,
                        ),
                        child: SlateErrorState(
                          message: 'Could not load requests',
                        ),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
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
                    )
                  : appointments.when(
                      loading: () => _skeletonList(),
                      error: (e, _) => _errorState(
                        () => ref.invalidate(appointmentsProvider),
                      ),
                      data: (data) {
                        final now = DateTime.now();
                        final todayStart = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                        final todayEnd = todayStart.add(
                          const Duration(days: 1),
                        );

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
                            onRefresh: () =>
                                ref.invalidate(appointmentsProvider),
                            onEmptyAction: () =>
                                _addAppointment(date: _selectedCalendarDate),
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
                              onRefresh: () =>
                                  ref.invalidate(appointmentsProvider),
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
                              onRefresh: () =>
                                  ref.invalidate(appointmentsProvider),
                              groupByDate: true,
                            ),
                            _AppointmentListView(
                              appointments: past,
                              emptyIcon: LucideIcons.history,
                              emptyTitle: 'No past bookings',
                              emptySubtitle: 'Completed work will appear here',
                              onTap: _openDetail,
                              onRefresh: () =>
                                  ref.invalidate(appointmentsProvider),
                              groupByDate: true,
                              showStatusBadge: true,
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
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

class _BookingsHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const _BookingsHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bookings',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.04,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Your work, organised.',
                style: TextStyle(
                  color: AppColors.t2,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        WorkloopIconButton(
          icon: LucideIcons.plus,
          semanticLabel: 'New booking',
          color: AppColors.modCalendar,
          backgroundColor: AppColors.modCalendar.withValues(alpha: 0.10),
          size: 48,
          onTap: onAdd,
        ),
      ],
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
    return WorkloopNavigationControl<_BookingsView>(
      selected: selected,
      onChanged: onSelected,
      color: AppColors.accentPrimary,
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
        'Next booking',
        style: TextStyle(
          color: AppColors.t3,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
