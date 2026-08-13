import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/business_feed_item.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/business_feed_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/setup_checklist_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/currency_format.dart';
import '../../shared/utils/date_format.dart';
import '../../shared/widgets/slate_ui.dart';
import '../appointments/appointment_detail_screen.dart';
import '../clients/client_detail_screen.dart';

final dashboardClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

String dashboardGreetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String dashboardDateLabel(DateTime date) => _dashboardDate(date);

List<Map<String, dynamic>> selectDashboardTodayBookings(
  List<Map<String, dynamic>> rows, {
  required DateTime now,
}) => _todayJobs(rows, now: now);

List<Map<String, dynamic>> selectDashboardComingUpBookings(
  List<Map<String, dynamic>> rows, {
  required DateTime now,
}) => _upcomingJobs(
  rows,
  now: now,
).where((job) => !_isSameDay(_startTime(job), now)).take(3).toList();

int dashboardSetupCompletedCount({
  required bool hasClient,
  required bool hasBooking,
  required bool hasPayment,
}) => [hasClient, hasBooking, hasPayment].where((value) => value).length;

class DashboardScreen extends ConsumerWidget {
  final void Function(int) onNavigate;
  final VoidCallback onOpenMoneyFollowUps;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenMoneyFollowUps,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = SlateTheme.of(context);
    final workspace = ref.watch(workspaceProvider);
    final appointments = ref.watch(appointmentsProvider);
    final clients = ref.watch(clientsProvider);
    final payments = ref.watch(invoicesProvider);
    final finance = ref.watch(financeSummaryProvider);
    final feed = ref.watch(businessFeedProvider);
    final attention = ref.watch(dashboardAttentionProvider);
    final tasks = ref.watch(allTasksProvider);
    final notes = ref.watch(allNotesProvider);
    final unreadNotifications = ref.watch(unreadNotificationsProvider);
    final displayName = ref.watch(authRepositoryProvider).currentFirstName;
    final now = ref
        .watch(dashboardClockProvider)
        .maybeWhen(data: (value) => value, orElse: DateTime.now);
    final greeting = dashboardGreetingForHour(now.hour);
    final checklistDismissed = ref
        .watch(setupChecklistDismissedProvider)
        .asData
        ?.value;
    final setupDataReady =
        clients.hasValue && appointments.hasValue && payments.hasValue;
    final overviewHasFailure =
        workspace.hasError || clients.hasError || payments.hasError;

    void retryOverview() {
      ref.invalidate(workspaceProvider);
      ref.invalidate(clientsProvider);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(invoicesProvider);
    }

    void retryAttention() {
      ref.invalidate(invoicesProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(clientsProvider);
      ref.invalidate(dashboardFocusProvider);
      ref.invalidate(dashboardAttentionProvider);
    }

    void retryFinance() {
      ref.invalidate(invoicesProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(financeSummaryProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.accentPrimary,
              onRefresh: () async {
                SlateHaptics.action();
                ref.invalidate(workspaceProvider);
                ref.invalidate(appointmentsProvider);
                ref.invalidate(todayAppointmentsProvider);
                ref.invalidate(financeSummaryProvider);
                ref.invalidate(invoicesProvider);
                ref.invalidate(expensesProvider);
                ref.invalidate(clientsProvider);
                ref.invalidate(allTasksProvider);
                ref.invalidate(tasksProvider);
                ref.invalidate(allNotesProvider);
                ref.invalidate(businessFeedProvider);
                ref.invalidate(dashboardFocusProvider);
                ref.invalidate(dashboardAttentionProvider);
                ref.invalidate(unreadNotificationsProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.screenTop,
                  AppSpacing.pageX,
                  AppSpacing.shellBottomClearance(context),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tokens.heroGradientStart,
                          tokens.heroGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.34)
                              : tokens.accentStrong.withValues(alpha: 0.3),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _DashboardGreeting(
                          inverse: true,
                          greeting: displayName == null
                              ? greeting
                              : '$greeting $displayName',
                          subtitle: dashboardDateLabel(now),
                          unreadNotifications: unreadNotifications.maybeWhen(
                            data: (value) => value,
                            orElse: () => 0,
                          ),
                          onOpenNotifications: () async {
                            await context.push('/notifications');
                            ref.invalidate(unreadNotificationsProvider);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _TodaySection(
                          inverse: true,
                          appointments: appointments,
                          now: now,
                          onOpenJob: (appointment) =>
                              _openAppointment(context, ref, appointment),
                          onViewBookings: () => onNavigate(2),
                        ),
                      ],
                    ),
                  ),
                  if (overviewHasFailure) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SlateErrorState(
                      message:
                          'Some workspace details could not be refreshed. Existing details are still shown.',
                      onRetry: retryOverview,
                    ),
                  ],
                  attention.when(
                    data: (items) => items.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.section,
                            ),
                            child: _WorthALookSection(
                              items: items.take(2).toList(),
                              onOpen: (item) =>
                                  _openAttentionItem(context, ref, item),
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.section),
                      child: SlateErrorState(
                        message: 'Could not check what needs your attention.',
                        onRetry: retryAttention,
                      ),
                    ),
                  ),
                  if (checklistDismissed == false && setupDataReady)
                    _SetupChecklist(
                      hasClient: clients.asData?.value.isNotEmpty ?? false,
                      hasBooking:
                          appointments.asData?.value.isNotEmpty ?? false,
                      hasPayment: payments.asData?.value.isNotEmpty ?? false,
                      onAddClient: () => context.push('/clients/new'),
                      onAddBooking: () => context.push('/bookings/new'),
                      onAddPayment: () => onNavigate(3),
                      onImport: () => context.push('/import-data'),
                      onDismiss: () => dismissSetupChecklist(ref),
                    ),
                  const SizedBox(height: AppSpacing.section),
                  _DashboardSection(
                    title: 'At a glance',
                    child: WorkloopSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      borderColor: Colors.transparent,
                      child: Column(
                        children: [
                          _MoneyPulse(
                            finance: finance,
                            onOpen: () => onNavigate(3),
                            onRetry: retryFinance,
                          ),
                          _QuickAccessRow(
                            taskSummary: tasks.maybeWhen(
                              data: (items) {
                                final open = items
                                    .where((item) => item.status != 'done')
                                    .length;
                                return open == 1
                                    ? '1 open task'
                                    : '$open open tasks';
                              },
                              orElse: () => 'Plan and follow up',
                            ),
                            noteSummary: notes.maybeWhen(
                              data: (items) => items.length == 1
                                  ? '1 saved note'
                                  : '${items.length} saved notes',
                              orElse: () => 'Capture useful context',
                            ),
                            onOpenTasks: () => onNavigate(4),
                            onOpenNotes: () => onNavigate(5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _CalmFeedSection(
                    feed: feed,
                    onOpenFeedItem: (item) => _openFeedItem(context, item),
                    onViewAllFeed: () => context.push('/business-feed'),
                    onRetry: () => ref.invalidate(businessFeedProvider),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _UpcomingJobsSection(
                    appointments: appointments,
                    now: now,
                    onOpenJob: (appointment) =>
                        _openAppointment(context, ref, appointment),
                    onViewBookings: () => onNavigate(2),
                    onRetry: () => ref.invalidate(appointmentsProvider),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAppointment(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> appointment,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    ).then((_) {
      ref.invalidate(appointmentsProvider);
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(businessFeedProvider);
    });
  }

  void _openFeedItem(BuildContext context, BusinessFeedItem item) {
    final route = item.routeTarget;
    if (route == null) return;
    if (route == '/clients') {
      onNavigate(1);
      return;
    }
    if (route == '/work') {
      onNavigate(2);
      return;
    }
    if (route == '/payments') {
      onNavigate(3);
      return;
    }
    if (route == '/tasks') {
      onNavigate(4);
      return;
    }
    if (route == '/notes') {
      onNavigate(5);
      return;
    }
    context.push(route);
  }

  void _openAttentionItem(
    BuildContext context,
    WidgetRef ref,
    DashboardAttentionItem item,
  ) {
    switch (item.type) {
      case DashboardAttentionType.unpaid:
        onOpenMoneyFollowUps();
      case DashboardAttentionType.bookingRequest:
        context.push('/booking-requests');
      case DashboardAttentionType.overdueTask:
        onNavigate(4);
      case DashboardAttentionType.clientFollowUp:
        final client = item.source;
        if (client is Client) {
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => ClientDetailScreen(client: client.toMap()),
            ),
          ).then((_) {
            ref.invalidate(clientsProvider);
            ref.invalidate(dashboardAttentionProvider);
            ref.invalidate(businessFeedProvider);
          });
        } else {
          onNavigate(1);
        }
    }
  }
}

class _SetupChecklist extends StatelessWidget {
  final bool hasClient;
  final bool hasBooking;
  final bool hasPayment;
  final VoidCallback onAddClient;
  final VoidCallback onAddBooking;
  final VoidCallback onAddPayment;
  final VoidCallback onImport;
  final VoidCallback onDismiss;

  const _SetupChecklist({
    required this.hasClient,
    required this.hasBooking,
    required this.hasPayment,
    required this.onAddClient,
    required this.onAddBooking,
    required this.onAddPayment,
    required this.onImport,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final completed = dashboardSetupCompletedCount(
      hasClient: hasClient,
      hasBooking: hasBooking,
      hasPayment: hasPayment,
    );
    if (completed == 3) return const SizedBox.shrink();
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: WorkloopSurface(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up your workspace',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$completed of 3 essentials complete',
                        style: TextStyle(
                          color: tokens.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                WorkloopIconButton(
                  icon: LucideIcons.x,
                  semanticLabel: 'Dismiss setup checklist',
                  onTap: onDismiss,
                  size: 36,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SetupStep(
              complete: hasClient,
              label: 'Add your first client',
              onTap: onAddClient,
            ),
            _SetupStep(
              complete: hasBooking,
              label: 'Create your first booking',
              onTap: onAddBooking,
            ),
            _SetupStep(
              complete: hasPayment,
              label: 'Record your first payment',
              onTap: onAddPayment,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: WorkloopTextButton(
                label: 'Import existing data',
                onPressed: onImport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final bool complete;
  final String label;
  final VoidCallback onTap;

  const _SetupStep({
    required this.complete,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopListRow(
      onTap: complete ? null : onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      leading: Icon(
        complete ? LucideIcons.checkCircle2 : LucideIcons.circle,
        size: 19,
        color: complete ? tokens.accentInk : tokens.textTertiary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: complete ? tokens.textTertiary : tokens.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          decoration: complete ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: complete
          ? null
          : Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: tokens.textTertiary,
            ),
      showDivider: false,
    );
  }
}

class _DashboardGreeting extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final int unreadNotifications;
  final VoidCallback onOpenNotifications;
  final bool inverse;

  const _DashboardGreeting({
    required this.greeting,
    required this.subtitle,
    required this.unreadNotifications,
    required this.onOpenNotifications,
    this.inverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final title = Text(
      greeting,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        color: inverse ? tokens.onHeroPrimary : tokens.textPrimary,
        fontSize: 27,
        fontWeight: FontWeight.w700,
      ),
    );
    final date = Text(
      subtitle,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: inverse ? tokens.onHeroMuted : tokens.textSecondary,
        fontSize: 14,
        height: 1.25,
      ),
    );
    final utilities = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkloopIconButton(
          icon: unreadNotifications > 0
              ? LucideIcons.bellRing
              : LucideIcons.bell,
          semanticLabel: unreadNotifications == 0
              ? 'Open notifications'
              : 'Open notifications, $unreadNotifications unread',
          badge: unreadNotifications == 0
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
                      color: tokens.onHeroPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.capsule),
                      border: Border.all(color: tokens.accentStrong, width: 2),
                    ),
                    child: Text(
                      unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                      style: TextStyle(
                        color: tokens.heroActionForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
          onTap: onOpenNotifications,
          color: inverse ? tokens.onHeroPrimary : null,
          backgroundColor: inverse ? tokens.heroControlSurface : null,
          borderColor: inverse ? tokens.heroBorder : null,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stackUtilities =
                constraints.maxWidth < 290 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.25;
            if (stackUtilities) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: AppSpacing.xxs),
                  date,
                  const SizedBox(height: AppSpacing.sm),
                  Align(alignment: Alignment.centerRight, child: utilities),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(child: date),
                    const SizedBox(width: AppSpacing.sm),
                    utilities,
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 1,
          color: inverse ? tokens.heroBorder : tokens.divider,
        ),
      ],
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  final String taskSummary;
  final String noteSummary;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotes;

  const _QuickAccessRow({
    required this.taskSummary,
    required this.noteSummary,
    required this.onOpenTasks,
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WorkloopModuleRow(
          icon: LucideIcons.listChecks,
          title: 'Tasks',
          subtitle: taskSummary,
          color: AppColors.accentPrimary,
          onTap: onOpenTasks,
        ),
        WorkloopModuleRow(
          icon: LucideIcons.stickyNote,
          title: 'Notes',
          subtitle: noteSummary,
          color: AppColors.accentPrimary,
          showDivider: false,
          onTap: onOpenNotes,
        ),
      ],
    );
  }
}

class _TodaySection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final DateTime now;
  final ValueChanged<Map<String, dynamic>> onOpenJob;
  final VoidCallback onViewBookings;
  final bool inverse;

  const _TodaySection({
    required this.appointments,
    required this.now,
    required this.onOpenJob,
    required this.onViewBookings,
    this.inverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Today',
      prominent: true,
      inverse: inverse,
      child: appointments.when(
        loading: () =>
            const SlateLoadingBlock(height: 220, radius: AppRadius.lg),
        error: (_, _) => _DailyFocusHero(
          label: 'YOUR SCHEDULE',
          title: 'Open today\'s bookings',
          detail: 'See the full schedule and keep the day moving.',
          icon: LucideIcons.calendarDays,
          actionLabel: 'Open Bookings',
          onAction: onViewBookings,
          dayProgress: _dayProgress(now),
        ),
        data: (rows) {
          final jobs = selectDashboardTodayBookings(rows, now: now);
          if (jobs.isEmpty) {
            return _DailyFocusHero(
              label: 'YOUR DAY',
              title: 'Your day is clear',
              detail: 'No more bookings are scheduled today.',
              icon: LucideIcons.sun,
              actionLabel: 'Open Bookings',
              onAction: onViewBookings,
              dayProgress: _dayProgress(now),
            );
          }

          final bookingPositions = jobs
              .map(_startTime)
              .whereType<DateTime>()
              .map(_dayProgress)
              .toList(growable: false);
          return _TodayBookingCarousel(
            jobs: jobs,
            now: now,
            bookingPositions: bookingPositions,
            onOpenJob: onOpenJob,
          );
        },
      ),
    );
  }
}

class _TodayBookingCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  final DateTime now;
  final List<double> bookingPositions;
  final ValueChanged<Map<String, dynamic>> onOpenJob;

  const _TodayBookingCarousel({
    required this.jobs,
    required this.now,
    required this.bookingPositions,
    required this.onOpenJob,
  });

  @override
  State<_TodayBookingCarousel> createState() => _TodayBookingCarouselState();
}

class _TodayBookingCarouselState extends State<_TodayBookingCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: widget.jobs.length > 1 ? 0.97 : 1,
    );
  }

  @override
  void didUpdateWidget(covariant _TodayBookingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index < widget.jobs.length) return;
    _index = math.max(0, widget.jobs.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.jumpToPage(_index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final baseHeight = widget.jobs.length > 1 ? 264 : 220;
    final carouselHeight = (baseHeight + ((textScale - 1) * 90).clamp(0, 90))
        .toDouble();

    return Semantics(
      container: true,
      label:
          '${widget.jobs.length} remaining booking${widget.jobs.length == 1 ? '' : 's'} today. Swipe horizontally to browse.',
      child: Column(
        children: [
          SizedBox(
            height: carouselHeight,
            child: PageView.builder(
              key: const ValueKey('today-booking-carousel'),
              controller: _controller,
              padEnds: false,
              physics: widget.jobs.length > 1
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: widget.jobs.length,
              onPageChanged: (index) {
                if (index == _index) return;
                SlateHaptics.tap();
                setState(() => _index = index);
              },
              itemBuilder: (context, index) {
                final job = widget.jobs[index];
                final start = _startTime(job);
                final end = _endTime(job);
                final happeningNow =
                    start != null &&
                    end != null &&
                    !widget.now.isBefore(start) &&
                    widget.now.isBefore(end);
                final time = start == null
                    ? null
                    : slateTimeRange(start, end).split('–').first.trim();
                final later = widget.jobs.length - index - 1;

                return Padding(
                  padding: EdgeInsets.only(
                    right: widget.jobs.length > 1 ? AppSpacing.xs : 0,
                  ),
                  child: Semantics(
                    label:
                        'Booking ${index + 1} of ${widget.jobs.length}, ${_clientName(job)}',
                    child: _DailyFocusHero(
                      label: happeningNow
                          ? 'HAPPENING NOW · ${index + 1} OF ${widget.jobs.length}'
                          : 'NEXT TODAY · ${index + 1} OF ${widget.jobs.length}',
                      value: time,
                      title: _clientName(job),
                      detail: [
                        _serviceName(job),
                        if (later == 1) '1 later today',
                        if (later > 1) '$later later today',
                      ].join(' · '),
                      icon: happeningNow
                          ? LucideIcons.radio
                          : LucideIcons.calendarClock,
                      actionLabel: 'Open booking',
                      onAction: () => widget.onOpenJob(job),
                      dayProgress: _dayProgress(widget.now),
                      bookingPositions: widget.bookingPositions,
                      activeBookingIndex: _index,
                      fillHeight: true,
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.jobs.length > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < widget.jobs.length; index++)
                  AnimatedContainer(
                    duration: AppMotion.responsive(context, AppMotion.standard),
                    curve: AppMotion.curve,
                    width: index == _index ? 18 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index == _index
                          ? tokens.onHeroPrimary
                          : tokens.onHeroSecondary.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(AppRadius.capsule),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyFocusHero extends StatelessWidget {
  final String label;
  final String? value;
  final String title;
  final String detail;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;
  final double dayProgress;
  final List<double> bookingPositions;
  final int? activeBookingIndex;
  final bool fillHeight;

  const _DailyFocusHero({
    required this.label,
    this.value,
    required this.title,
    required this.detail,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.dayProgress,
    this.bookingPositions = const [],
    this.activeBookingIndex,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopSurface(
      color: tokens.heroSurface,
      borderColor: tokens.heroBorder,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.heroControlSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.heroBorder),
                ),
                child: Icon(icon, color: tokens.onHeroPrimary, size: 13),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: tokens.onHeroMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(width: 22, height: 2, color: tokens.accentStrong),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Semantics(
            label: bookingPositions.isEmpty
                ? 'Today is ${(dayProgress * 100).round()} percent complete'
                : '${bookingPositions.length} booking${bookingPositions.length == 1 ? '' : 's'} remain today',
            child: ExcludeSemantics(
              child: SizedBox(
                key: ValueKey(
                  'active-job-marker-${activeBookingIndex ?? 'none'}',
                ),
                height: 20,
                width: double.infinity,
                child: _AnimatedDayPath(
                  progress: dayProgress,
                  bookingPositions: bookingPositions,
                  activeBookingIndex: activeBookingIndex,
                  track: tokens.onHeroSecondary,
                  accent: tokens.accentStrong,
                  ink: tokens.onHeroPrimary,
                ),
              ),
            ),
          ),
          if (value != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value!,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: tokens.onHeroPrimary,
                fontSize: 27,
                height: 1.05,
              ),
            ),
          ] else
            const SizedBox(height: AppSpacing.xxs),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: tokens.onHeroPrimary,
              fontSize: 20,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.onHeroSecondary),
          ),
          if (fillHeight)
            const Spacer()
          else
            const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.onHeroPrimary,
                foregroundColor: tokens.heroActionForeground,
              ),
              onPressed: onAction,
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

double _dayProgress(DateTime value) {
  final minutes = value.hour * 60 + value.minute;
  return (minutes / (24 * 60)).clamp(0.0, 1.0);
}

class _DayPathPainter extends CustomPainter {
  final double progress;
  final List<double> bookingPositions;
  final int? activeBookingIndex;
  final double? activeBookingPosition;
  final double activeMarkerScale;
  final Color track;
  final Color accent;
  final Color ink;

  const _DayPathPainter({
    required this.progress,
    required this.bookingPositions,
    required this.activeBookingIndex,
    required this.activeBookingPosition,
    required this.activeMarkerScale,
    required this.track,
    required this.accent,
    required this.ink,
  });

  double _y(double x, Size size) {
    return size.height * 0.52 + math.sin(x * math.pi * 2.1) * 4;
  }

  Path _path(Size size, double end) {
    final path = Path();
    const steps = 48;
    for (var index = 0; index <= steps; index++) {
      final fraction = (index / steps) * end;
      final point = Offset(fraction * size.width, _y(fraction, size));
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 4.0;
    final contentSize = Size(size.width - inset * 2, size.height);
    canvas.save();
    canvas.translate(inset, 0);

    canvas.drawPath(
      _path(contentSize, 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..color = track.withValues(alpha: 0.42),
    );
    canvas.drawPath(
      _path(contentSize, progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.25
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.78),
    );

    final current = Offset(
      progress * contentSize.width,
      _y(progress, contentSize),
    );
    canvas.drawCircle(
      current,
      3.25,
      Paint()
        ..style = PaintingStyle.fill
        ..color = ink.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      current,
      3.25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = accent.withValues(alpha: 0.72),
    );

    final visiblePositions = bookingPositions.take(6).toList(growable: false);
    for (var index = 0; index < visiblePositions.length; index++) {
      if (index == activeBookingIndex) continue;
      final position = visiblePositions[index];
      final clamped = position.clamp(0.0, 1.0);
      final point = Offset(
        clamped * contentSize.width,
        _y(clamped, contentSize),
      );
      canvas.drawCircle(
        point,
        3,
        Paint()
          ..style = PaintingStyle.fill
          ..color = clamped <= progress
              ? ink.withValues(alpha: 0.62)
              : accent.withValues(alpha: 0.82),
      );
    }

    if (activeBookingPosition case final position?) {
      final clamped = position.clamp(0.0, 1.0);
      final point = Offset(
        clamped * contentSize.width,
        _y(clamped, contentSize),
      );
      canvas.drawCircle(
        point,
        9 * activeMarkerScale,
        Paint()..color = accent.withValues(alpha: 0.20),
      );
      canvas.drawCircle(point, 6.25 * activeMarkerScale, Paint()..color = ink);
      canvas.drawCircle(
        point,
        6.25 * activeMarkerScale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DayPathPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        bookingPositions != oldDelegate.bookingPositions ||
        activeBookingIndex != oldDelegate.activeBookingIndex ||
        activeBookingPosition != oldDelegate.activeBookingPosition ||
        activeMarkerScale != oldDelegate.activeMarkerScale ||
        track != oldDelegate.track ||
        accent != oldDelegate.accent ||
        ink != oldDelegate.ink;
  }
}

class _AnimatedDayPath extends StatefulWidget {
  final double progress;
  final List<double> bookingPositions;
  final int? activeBookingIndex;
  final Color track;
  final Color accent;
  final Color ink;

  const _AnimatedDayPath({
    required this.progress,
    required this.bookingPositions,
    required this.activeBookingIndex,
    required this.track,
    required this.accent,
    required this.ink,
  });

  @override
  State<_AnimatedDayPath> createState() => _AnimatedDayPathState();
}

class _AnimatedDayPathState extends State<_AnimatedDayPath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double? _fromPosition;
  double? _targetPosition;

  double? _positionFor(_AnimatedDayPath value) {
    final index = value.activeBookingIndex;
    if (index == null || index < 0 || index >= value.bookingPositions.length) {
      return null;
    }
    return value.bookingPositions[index].clamp(0.0, 1.0);
  }

  double? get _currentPosition {
    final from = _fromPosition;
    final target = _targetPosition;
    if (target == null) return null;
    if (from == null) return target;
    final travel = Curves.easeInOutCubic.transform(_controller.value);
    return from + (target - from) * travel;
  }

  @override
  void initState() {
    super.initState();
    _targetPosition = _positionFor(widget);
    _fromPosition = _targetPosition;
    _controller = AnimationController(
      vsync: this,
      duration: Duration.zero,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = AppMotion.responsive(context, AppMotion.deliberate);
    if (_controller.duration == Duration.zero) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedDayPath oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPosition = _positionFor(widget);
    if (nextPosition == _targetPosition &&
        widget.activeBookingIndex == oldWidget.activeBookingIndex) {
      return;
    }
    _fromPosition = _currentPosition ?? nextPosition;
    _targetPosition = nextPosition;
    if (_controller.duration == Duration.zero || nextPosition == null) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bounce = _controller.isAnimating
            ? Curves.easeOutBack.transform(_controller.value)
            : 1.0;
        final markerScale = 0.78 + 0.22 * bounce;
        return CustomPaint(
          painter: _DayPathPainter(
            progress: widget.progress,
            bookingPositions: widget.bookingPositions,
            activeBookingIndex: widget.activeBookingIndex,
            activeBookingPosition: _currentPosition,
            activeMarkerScale: markerScale,
            track: widget.track,
            accent: widget.accent,
            ink: widget.ink,
          ),
        );
      },
    );
  }
}

class _WorthALookSection extends StatelessWidget {
  final List<DashboardAttentionItem> items;
  final ValueChanged<DashboardAttentionItem> onOpen;

  const _WorthALookSection({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Worth a look',
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++)
            WorkloopListRow(
              onTap: () => onOpen(items[index]),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              leading: _SoftIcon(icon: _attentionIcon(items[index].type)),
              title: Text(
                _attentionTitle(items[index]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _attentionDetail(items[index]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.t2,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
              showDivider: index != items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _MoneyPulse extends StatelessWidget {
  final AsyncValue<FinanceSummary> finance;
  final VoidCallback onOpen;
  final VoidCallback onRetry;

  const _MoneyPulse({
    required this.finance,
    required this.onOpen,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return finance.when(
      loading: () => const SlateLoadingBlock(height: 68, radius: AppRadius.md),
      error: (_, _) => SlateErrorState(
        message: 'Could not load your Money summary.',
        onRetry: onRetry,
      ),
      data: (summary) => _MoneyRow(
        onOpen: onOpen,
        amount: summary.thisMonthPaid,
        target: summary.monthlyTarget,
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final VoidCallback onOpen;
  final double? amount;
  final double target;

  const _MoneyRow({required this.onOpen, this.amount, required this.target});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopListRow(
      onTap: onOpen,
      flat: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: tokens.divider),
        ),
        child: Icon(LucideIcons.banknote, color: tokens.accentInk, size: 20),
      ),
      title: const Text(
        'Money',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.t1,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        amount == null
            ? 'See your latest business progress'
            : target > 0
            ? '${formatPounds(amount!)} of ${formatPounds(target)} this month'
            : '${formatPounds(amount!)} received this month',
        style: const TextStyle(
          color: AppColors.t2,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: target > 0 && amount != null
          ? _MoneyTargetDial(amount: amount!, target: target)
          : const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
    );
  }
}

class _MoneyTargetDial extends StatelessWidget {
  final double amount;
  final double target;

  const _MoneyTargetDial({required this.amount, required this.target});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final progress = target <= 0 ? 0.0 : (amount / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    return Semantics(
      label: '$percentage percent of monthly Money target',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: 40,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  color: tokens.accent,
                  backgroundColor: tokens.surfaceRaised,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingJobsSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> appointments;
  final DateTime now;
  final ValueChanged<Map<String, dynamic>> onOpenJob;
  final VoidCallback onViewBookings;
  final VoidCallback onRetry;

  const _UpcomingJobsSection({
    required this.appointments,
    required this.now,
    required this.onOpenJob,
    required this.onViewBookings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Coming up',
      actionLabel: 'View all',
      onAction: onViewBookings,
      child: appointments.when(
        loading: () =>
            const SlateLoadingBlock(height: 150, radius: AppRadius.lg),
        error: (_, _) => SlateErrorState(
          message: 'Could not load upcoming bookings',
          onRetry: onRetry,
        ),
        data: (rows) {
          final jobs = selectDashboardComingUpBookings(rows, now: now);
          if (jobs.isEmpty) {
            return WorkloopListRow(
              onTap: onViewBookings,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              leading: const _SoftIcon(icon: LucideIcons.calendarDays),
              title: const Text(
                'Nothing else scheduled yet',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Your upcoming schedule is open.',
                style: TextStyle(
                  color: AppColors.t2,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
            );
          }

          return Column(
            children: [
              for (final job in jobs)
                _UpcomingJobRow(job: job, onTap: () => onOpenJob(job)),
            ],
          );
        },
      ),
    );
  }
}

class _UpcomingJobRow extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _UpcomingJobRow({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = _startTime(job);
    final end = _endTime(job);
    final client = _clientName(job);
    final service = _serviceName(job);
    final date = start == null ? 'Upcoming' : _friendlyDate(start);
    final time = start == null ? null : slateTimeRange(start, end);

    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      leading: _SoftIcon(icon: LucideIcons.calendarClock),
      title: Text(
        client,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [date, ?time, service].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t2,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.t3,
        size: 16,
      ),
    );
  }
}

class _CalmFeedSection extends StatelessWidget {
  final AsyncValue<List<BusinessFeedItem>> feed;
  final ValueChanged<BusinessFeedItem> onOpenFeedItem;
  final VoidCallback onViewAllFeed;
  final VoidCallback onRetry;

  const _CalmFeedSection({
    required this.feed,
    required this.onOpenFeedItem,
    required this.onViewAllFeed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Business feed',
      actionLabel: 'View all',
      onAction: onViewAllFeed,
      child: feed.when(
        loading: () =>
            const SlateLoadingBlock(height: 190, radius: AppRadius.lg),
        error: (_, _) => SlateErrorState(
          message: 'Could not load recent activity',
          onRetry: onRetry,
        ),
        data: (items) {
          final calmItems = items.where(_isCalmFeedItem).take(2).toList();
          if (calmItems.isEmpty) {
            return const WorkloopEmptyState(
              icon: LucideIcons.activity,
              title: 'No activity yet.',
              subtitle:
                  'Recent bookings, notes, and payments will appear here.',
            );
          }

          return Column(
            children: [
              for (final item in calmItems) ...[
                _CalmFeedRow(
                  item: item,
                  onTap: item.routeTarget == null
                      ? null
                      : () => onOpenFeedItem(item),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CalmFeedRow extends StatelessWidget {
  final BusinessFeedItem item;
  final VoidCallback? onTap;

  const _CalmFeedRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      leading: _SoftIcon(icon: _iconForFeedItem(item)),
      title: Text(
        _calmFeedTitle(item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${item.subtitle} · ${_relativeTime(item.timestamp)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t2,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: onTap == null
          ? null
          : const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool prominent;
  final bool inverse;

  const _DashboardSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.prominent = false,
    this.inverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: inverse ? Colors.white : AppColors.t1,
                  fontSize: prominent ? 20 : 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              WorkloopTextButton(label: actionLabel!, onPressed: onAction),
          ],
        ),
        SizedBox(height: prominent ? AppSpacing.xs : AppSpacing.sm),
        child,
      ],
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.t1.withValues(alpha: 0.045),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.t3, size: 17),
    );
  }
}

String _dashboardDate(DateTime date) {
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
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

List<Map<String, dynamic>> _todayJobs(
  List<Map<String, dynamic>> rows, {
  required DateTime now,
}) {
  return _upcomingJobs(
    rows,
    now: now,
  ).where((row) => _isSameDay(_startTime(row), now)).toList();
}

bool _isSameDay(DateTime? first, DateTime second) {
  return first != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _attentionTitle(DashboardAttentionItem item) {
  return item.title;
}

String _attentionDetail(DashboardAttentionItem item) {
  return switch (item.type) {
    DashboardAttentionType.bookingRequest => item.detail,
    DashboardAttentionType.unpaid => item.detail,
    DashboardAttentionType.overdueTask =>
      item.detail == 'Overdue task' ? 'A task ready when you are' : item.detail,
    DashboardAttentionType.clientFollowUp => item.detail,
  };
}

IconData _attentionIcon(DashboardAttentionType type) {
  return switch (type) {
    DashboardAttentionType.bookingRequest => LucideIcons.inbox,
    DashboardAttentionType.unpaid => LucideIcons.banknote,
    DashboardAttentionType.overdueTask => LucideIcons.listChecks,
    DashboardAttentionType.clientFollowUp => LucideIcons.userRoundCheck,
  };
}

List<Map<String, dynamic>> _upcomingJobs(
  List<Map<String, dynamic>> rows, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final jobs = rows.where((row) {
    final status = row['status']?.toString().toLowerCase() ?? 'scheduled';
    final start = _startTime(row);
    if (start == null) return false;
    if (status == 'completed' || status == 'cancelled' || status == 'no_show') {
      return false;
    }
    final end = _endTime(row);
    final happeningNow =
        end != null && !current.isBefore(start) && current.isBefore(end);
    return start.isAfter(current) || happeningNow;
  }).toList();

  jobs.sort((a, b) {
    final aStart = _startTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bStart = _startTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aStart.compareTo(bStart);
  });
  return jobs;
}

bool _isCalmFeedItem(BusinessFeedItem item) {
  if (item.priority == BusinessFeedPriority.attention) return false;
  return switch (item.type) {
    BusinessFeedItemType.bookingToday ||
    BusinessFeedItemType.bookingUpcoming ||
    BusinessFeedItemType.paymentReceived ||
    BusinessFeedItemType.expenseRecorded ||
    BusinessFeedItemType.noteCreated ||
    BusinessFeedItemType.weeklyTargetProgress => true,
    BusinessFeedItemType.invoiceUnpaid ||
    BusinessFeedItemType.invoiceOverdue ||
    BusinessFeedItemType.taskDue ||
    BusinessFeedItemType.taskOverdue ||
    BusinessFeedItemType.clientFollowUp ||
    BusinessFeedItemType.bookingRequestNew ||
    BusinessFeedItemType.quietDayDetected ||
    BusinessFeedItemType.dailySummary => false,
  };
}

String _calmFeedTitle(BusinessFeedItem item) {
  return switch (item.type) {
    BusinessFeedItemType.bookingToday => 'Booking scheduled today',
    BusinessFeedItemType.bookingUpcoming => 'Upcoming booking added',
    BusinessFeedItemType.paymentReceived => 'Payment received',
    BusinessFeedItemType.expenseRecorded => 'Expense recorded',
    BusinessFeedItemType.noteCreated => 'Note added',
    BusinessFeedItemType.weeklyTargetProgress => 'Progress updated',
    _ => item.title,
  };
}

IconData _iconForFeedItem(BusinessFeedItem item) {
  return switch (item.type) {
    BusinessFeedItemType.bookingToday ||
    BusinessFeedItemType.bookingUpcoming => LucideIcons.calendarDays,
    BusinessFeedItemType.paymentReceived => LucideIcons.banknote,
    BusinessFeedItemType.expenseRecorded => LucideIcons.receipt,
    BusinessFeedItemType.noteCreated => LucideIcons.stickyNote,
    BusinessFeedItemType.weeklyTargetProgress => LucideIcons.trendingUp,
    _ => LucideIcons.activity,
  };
}

DateTime? _startTime(Map<String, dynamic> appointment) =>
    DateTime.tryParse(appointment['start_time']?.toString() ?? '')?.toLocal();

DateTime? _endTime(Map<String, dynamic> appointment) =>
    DateTime.tryParse(appointment['end_time']?.toString() ?? '')?.toLocal();

String _clientName(Map<String, dynamic> appointment) =>
    appointment['contacts']?['name']?.toString() ?? 'Client';

String _serviceName(Map<String, dynamic> appointment) =>
    appointment['services']?['name']?.toString() ??
    appointment['title']?.toString() ??
    'Booking';

String _friendlyDate(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  if (day == today) return 'Today';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
  return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]}';
}

String _relativeTime(DateTime timestamp) {
  final now = DateTime.now();
  if (timestamp.isAfter(now)) {
    final until = timestamp.difference(now);
    if (until.inHours < 24) return 'in ${until.inHours.clamp(1, 23)}h';
    return 'in ${until.inDays}d';
  }

  final difference = now.difference(timestamp);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(0, 59)}m ago';
  }
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return _friendlyDate(timestamp);
}
