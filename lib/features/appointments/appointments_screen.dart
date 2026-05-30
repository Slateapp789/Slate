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

  Future<void> _addAppointment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAppointmentScreen()),
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
                    'Work',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      letterSpacing: 0,
                    ),
                  ),
                  GestureDetector(
                    onTap: _addAppointment,
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
            ),
            const SizedBox(height: 16),

            appointments.when(
              data: (data) {
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayEnd = todayStart.add(const Duration(days: 1));
                final todayAll = data.where((a) {
                  final dt = DateTime.tryParse(
                    a['start_time'] as String? ?? '',
                  )?.toLocal();
                  return dt != null &&
                      dt.isAfter(todayStart) &&
                      dt.isBefore(todayEnd) &&
                      a['status'] != 'cancelled';
                }).toList();
                final completed = todayAll
                    .where((a) => a['status'] == 'completed')
                    .length;
                final remaining = todayAll
                    .where((a) => a['status'] == 'scheduled')
                    .length;
                final todayRevenue = todayAll
                    .where((a) => a['status'] == 'completed')
                    .fold<double>(
                      0,
                      (sum, a) => sum + ((a['price'] as num?)?.toDouble() ?? 0),
                    );

                if (todayAll.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    0,
                    AppSpacing.pageX,
                    AppSpacing.md,
                  ),
                  child: SlateSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    radius: AppRadius.md,
                    color: AppColors.greenDim,
                    borderColor: AppColors.green.withValues(alpha: 0.25),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.sun,
                          color: AppColors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Today — $completed done, $remaining to go',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                        if (todayRevenue > 0)
                          Text(
                            '£${todayRevenue.toStringAsFixed(0)} earned',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
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

            Expanded(
              child: appointments.when(
                loading: () => _skeletonList(),
                error: (e, _) =>
                    _errorState(() => ref.invalidate(appointmentsProvider)),
                data: (data) {
                  final now = DateTime.now();
                  final todayStart = DateTime(now.year, now.month, now.day);
                  final todayEnd = todayStart.add(const Duration(days: 1));

                  final today = data.where((a) {
                    final dt = DateTime.tryParse(
                      a['start_time'] as String? ?? '',
                    )?.toLocal();
                    return dt != null &&
                        dt.isAfter(todayStart) &&
                        dt.isBefore(todayEnd) &&
                        a['status'] != 'cancelled';
                  }).toList();

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

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _AppointmentListView(
                        appointments: today,
                        emptyIcon: LucideIcons.calendarDays,
                        emptyTitle: 'Nothing scheduled today',
                        emptySubtitle: 'Tap New to add an appointment',
                        onTap: _openDetail,
                        onRefresh: () => ref.invalidate(appointmentsProvider),
                        onEmptyAction: _addAppointment,
                        groupByDate: false,
                      ),
                      _AppointmentListView(
                        appointments: upcoming,
                        emptyIcon: LucideIcons.calendarClock,
                        emptyTitle: 'No upcoming appointments',
                        emptySubtitle: 'Your future schedule is clear',
                        onTap: _openDetail,
                        onRefresh: () => ref.invalidate(appointmentsProvider),
                        groupByDate: true,
                      ),
                      _AppointmentListView(
                        appointments: past,
                        emptyIcon: LucideIcons.history,
                        emptyTitle: 'No past appointments',
                        emptySubtitle: 'Completed sessions will appear here',
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
      child: SlateErrorState(message: 'Could not load appointments'),
    );
  }
}
