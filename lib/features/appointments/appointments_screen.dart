import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/utils/currency_format.dart';
import '../../shared/widgets/slate_ui.dart';
import '../public_profile/booking_requests_screen.dart';
import '../work/work_workspace_switcher.dart';
import 'add_appointment_screen.dart';
import 'appointment_detail_screen.dart';

part 'appointment_list_view.dart';

const inactiveUpcomingBookingStatuses = {'cancelled', 'no_show', 'completed'};

bool isUpcomingBookingStatus(Object? status) {
  return !inactiveUpcomingBookingStatuses.contains(
    status?.toString().toLowerCase(),
  );
}

DateTime nextBookingCalendarDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day + 1);
}

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
            isUpcomingBookingStatus(entry.$2['status']);
      }).toList()..sort((a, b) {
        final startCompare = _start(a.$2)!.compareTo(_start(b.$2)!);
        if (startCompare != 0) return startCompare;
        return a.$1.compareTo(b.$1);
      });
  return upcoming.isEmpty ? null : upcoming.first.$2;
}

class AppointmentsScreen extends ConsumerStatefulWidget {
  final DateTime? initialCalendarDate;
  final DateTime? calendarReferenceDate;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenNotes;
  final bool embedded;
  final int createRequest;

  const AppointmentsScreen({
    super.key,
    this.initialCalendarDate,
    this.calendarReferenceDate,
    this.onOpenTasks,
    this.onOpenNotes,
    this.embedded = false,
    this.createRequest = 0,
  });

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedCalendarDate;
  late DateTime _calendarToday;
  bool _calendarMode = false;
  int _selectedListTab = 0;

  @override
  void initState() {
    super.initState();
    _calendarToday = _dateOnly(widget.calendarReferenceDate ?? DateTime.now());
    _selectedCalendarDate = _dateOnly(
      widget.initialCalendarDate ?? _calendarToday,
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    if (widget.createRequest != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addAppointment();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.createRequest == 0 ||
        widget.createRequest == oldWidget.createRequest) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _addAppointment();
    });
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

  Future<void> _openRequests() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const BookingRequestsScreen()),
    );
    ref.invalidate(bookingRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final bookingRequests = ref.watch(bookingRequestsProvider);
    final activeRequestCount = bookingRequests.maybeWhen(
      data: (items) => _activeRequests(items).length,
      orElse: () => 0,
    );
    final content = NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.embedded) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    AppSpacing.screenTop,
                    AppSpacing.pageX,
                    0,
                  ),
                  child: _BookingsHeader(
                    onAdd: _addAppointment,
                    onRequests: _openRequests,
                    requestCount: activeRequestCount,
                    workMode: widget.onOpenTasks != null,
                  ),
                ),
                if (widget.onOpenTasks != null &&
                    widget.onOpenNotes != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageX,
                    ),
                    child: WorkWorkspaceSwitcher(
                      selected: WorkWorkspaceSection.schedule,
                      onChanged: (section) {
                        switch (section) {
                          case WorkWorkspaceSection.schedule:
                            break;
                          case WorkWorkspaceSection.tasks:
                            widget.onOpenTasks!();
                          case WorkWorkspaceSection.notes:
                            widget.onOpenNotes!();
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageX,
                ),
                child: _BookingScheduleToolbar(
                  calendarMode: _calendarMode,
                  selectedListTab: _selectedListTab,
                  onSelected: (index) {
                    if (index == 3) {
                      setState(() => _calendarMode = true);
                      return;
                    }
                    setState(() {
                      _calendarMode = false;
                      _selectedListTab = index;
                    });
                    _tabController.animateTo(index);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
      body: appointments.when(
        loading: () => _skeletonList(),
        error: (e, _) =>
            _errorState(() => ref.invalidate(appointmentsProvider)),
        data: (data) {
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = nextBookingCalendarDay(todayStart);

          final today = _appointmentsForDay(data, todayStart);

          final upcoming = data.where((a) {
            final dt = DateTime.tryParse(
              a['start_time'] as String? ?? '',
            )?.toLocal();
            return dt != null &&
                !dt.isBefore(todayEnd) &&
                isUpcomingBookingStatus(a['status']);
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
                final dtA = DateTime.tryParse(a['start_time'] as String? ?? '');
                final dtB = DateTime.tryParse(b['start_time'] as String? ?? '');
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
              today: _calendarToday,
              selectedDayAppointments: selectedDayAppointments,
              onDateSelected: (date) {
                setState(() => _selectedCalendarDate = date);
              },
              onTap: _openDetail,
              onRefresh: () => ref.invalidate(appointmentsProvider),
              onEmptyAction: () => _addAppointment(date: _selectedCalendarDate),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _AppointmentListView(
                appointments: today,
                emptyIcon: LucideIcons.calendarDays,
                emptyTitle: 'Nothing scheduled today',
                emptySubtitle: 'Add a booking when work is agreed.',
                onTap: _openDetail,
                onRefresh: () => ref.invalidate(appointmentsProvider),
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
    );
    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(bottom: false, child: content),
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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) =>
          const SlateLoadingBlock(height: 80, radius: AppRadius.md),
    );
  }

  Widget _errorState(VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
      child: SlateErrorState(
        message: 'Could not load bookings',
        onRetry: onRetry,
      ),
    );
  }

  List<Map<String, dynamic>> _appointmentsForDay(
    List<Map<String, dynamic>> appointments,
    DateTime day,
  ) {
    final start = _dateOnly(day);
    final end = nextBookingCalendarDay(start);
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
  final VoidCallback onRequests;
  final int requestCount;
  final bool workMode;

  const _BookingsHeader({
    required this.onAdd,
    required this.onRequests,
    required this.requestCount,
    required this.workMode,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopPageHeader(
      title: workMode ? 'Work' : 'Bookings',
      subtitle: workMode
          ? 'Schedule it, do it, and keep the context.'
          : 'Run today. Plan ahead.',
      color: AppColors.modCalendar,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkloopIconButton(
            icon: LucideIcons.inbox,
            semanticLabel: requestCount == 0
                ? 'Booking requests'
                : 'Booking requests, $requestCount active',
            onTap: onRequests,
            size: AppSpacing.minTouch,
            badge: requestCount == 0
                ? null
                : Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: tokens.accentStrong,
                        borderRadius: BorderRadius.circular(AppRadius.capsule),
                        border: Border.all(color: tokens.background, width: 2),
                      ),
                      child: Text(
                        requestCount > 99 ? '99+' : '$requestCount',
                        style: TextStyle(
                          color: tokens.onAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.xs),
          WorkloopTopAction(
            label: 'New booking',
            semanticLabel: 'New booking',
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _BookingScheduleToolbar extends StatelessWidget {
  final bool calendarMode;
  final int selectedListTab;
  final ValueChanged<int> onSelected;

  const _BookingScheduleToolbar({
    required this.calendarMode,
    required this.selectedListTab,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopNavigationControl<int>(
      selected: calendarMode ? 3 : selectedListTab,
      onChanged: onSelected,
      compact: true,
      emphasized: false,
      segments: const [
        WorkloopSegment(value: 0, label: 'Today'),
        WorkloopSegment(value: 1, label: 'Upcoming'),
        WorkloopSegment(value: 2, label: 'Past'),
        WorkloopSegment(value: 3, label: 'Calendar'),
      ],
    );
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime? _start(Map<String, dynamic> appt) =>
    DateTime.tryParse(appt['start_time'] as String? ?? '')?.toLocal();
