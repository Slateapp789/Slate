import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';

class DashboardRevenue {
  final double weekTotal;
  final double monthTotal;
  final double outstanding;
  final double revenueTarget;

  const DashboardRevenue({
    required this.weekTotal,
    required this.monthTotal,
    required this.outstanding,
    required this.revenueTarget,
  });
}

class DashboardPulse {
  final int upcomingBookings;
  final int pendingBookingRequests;
  final int overduePayments;
  final int repeatClients;
  final String busiestPeriod;

  const DashboardPulse({
    required this.upcomingBookings,
    required this.pendingBookingRequests,
    required this.overduePayments,
    required this.repeatClients,
    required this.busiestPeriod,
  });
}

class DashboardFocus {
  final Map<String, dynamic>? nextAppointment;
  final int pendingBookingRequests;
  final int overduePayments;
  final double overdueTotal;
  final bool calendarSyncEnabled;

  const DashboardFocus({
    required this.nextAppointment,
    required this.pendingBookingRequests,
    required this.overduePayments,
    required this.overdueTotal,
    required this.calendarSyncEnabled,
  });

  bool get hasAttention =>
      pendingBookingRequests > 0 ||
      overduePayments > 0 ||
      nextAppointment != null ||
      !calendarSyncEnabled;
}

double _sumTotals(List<Map<String, dynamic>> rows) {
  return rows.fold<double>(0, (sum, row) {
    final v = row['total'];
    if (v is num) return sum + v.toDouble();
    return sum + (double.tryParse(v?.toString() ?? '') ?? 0);
  });
}

String _dateOnly(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

DateTime _startOfWeek(DateTime now) {
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

DateTime _startOfMonth(DateTime now) => DateTime(now.year, now.month, 1);

final dashboardRevenueProvider = FutureProvider<DashboardRevenue>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) {
    return const DashboardRevenue(
      weekTotal: 0,
      monthTotal: 0,
      outstanding: 0,
      revenueTarget: 0,
    );
  }

  final now = DateTime.now();
  final weekStart = _dateOnly(_startOfWeek(now));
  final monthStart = _dateOnly(_startOfMonth(now));
  final repository = ref.watch(dashboardRepositoryProvider);

  final weekPaid = await repository.invoiceTotals(
    workspaceId: workspaceId,
    status: 'paid',
    issueDateFrom: weekStart,
  );
  final monthPaid = await repository.invoiceTotals(
    workspaceId: workspaceId,
    status: 'paid',
    issueDateFrom: monthStart,
  );
  final outstandingRows = await repository.invoiceTotals(
    workspaceId: workspaceId,
    status: 'sent',
    statuses: ['sent', 'overdue'],
  );

  double revenueTarget = 0;
  try {
    revenueTarget = await repository.revenueTarget(workspaceId);
  } catch (_) {}

  return DashboardRevenue(
    weekTotal: _sumTotals(List<Map<String, dynamic>>.from(weekPaid)),
    monthTotal: _sumTotals(List<Map<String, dynamic>>.from(monthPaid)),
    outstanding: _sumTotals(List<Map<String, dynamic>>.from(outstandingRows)),
    revenueTarget: revenueTarget,
  );
});

final todayAppointmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfToday.add(const Duration(days: 1));

  return ref
      .watch(dashboardRepositoryProvider)
      .todayAppointments(
        workspaceId: workspaceId,
        start: startOfToday,
        end: startOfTomorrow,
      );
});

final dashboardPulseProvider = FutureProvider<DashboardPulse>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) {
    return const DashboardPulse(
      upcomingBookings: 0,
      pendingBookingRequests: 0,
      overduePayments: 0,
      repeatClients: 0,
      busiestPeriod: 'No bookings yet',
    );
  }

  final now = DateTime.now();
  final monthStart = _dateOnly(_startOfMonth(now));
  final repository = ref.watch(dashboardRepositoryProvider);

  final upcomingRows = await repository.upcomingAppointmentIds(
    workspaceId: workspaceId,
    from: now,
  );
  final overdueRows = await repository.overduePaymentIds(workspaceId);
  final monthlyAppointments = await repository.monthlyAppointmentSignals(
    workspaceId: workspaceId,
    monthStart: monthStart,
  );

  int pendingRequests = 0;
  try {
    pendingRequests = await repository.pendingBookingRequests(workspaceId);
  } catch (_) {
    pendingRequests = 0;
  }

  final contactCounts = <String, int>{};
  final hourBuckets = <String, int>{'Morning': 0, 'Afternoon': 0, 'Evening': 0};
  for (final row in List<Map<String, dynamic>>.from(monthlyAppointments)) {
    final contactId = row['contact_id'] as String?;
    if (contactId != null) {
      contactCounts[contactId] = (contactCounts[contactId] ?? 0) + 1;
    }
    final start = DateTime.tryParse(
      row['start_time']?.toString() ?? '',
    )?.toLocal();
    if (start != null) {
      if (start.hour < 12) {
        hourBuckets['Morning'] = hourBuckets['Morning']! + 1;
      } else if (start.hour < 17) {
        hourBuckets['Afternoon'] = hourBuckets['Afternoon']! + 1;
      } else {
        hourBuckets['Evening'] = hourBuckets['Evening']! + 1;
      }
    }
  }

  final busiest = hourBuckets.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final busiestPeriod = busiest.first.value == 0
      ? 'No bookings yet'
      : '${busiest.first.key} (${busiest.first.value})';

  return DashboardPulse(
    upcomingBookings: List<Map<String, dynamic>>.from(upcomingRows).length,
    pendingBookingRequests: pendingRequests,
    overduePayments: List<Map<String, dynamic>>.from(overdueRows).length,
    repeatClients: contactCounts.values.where((count) => count > 1).length,
    busiestPeriod: busiestPeriod,
  );
});

final dashboardFocusProvider = FutureProvider<DashboardFocus>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) {
    return const DashboardFocus(
      nextAppointment: null,
      pendingBookingRequests: 0,
      overduePayments: 0,
      overdueTotal: 0,
      calendarSyncEnabled: false,
    );
  }

  final repository = ref.watch(dashboardRepositoryProvider);
  final now = DateTime.now();

  Map<String, dynamic>? nextAppointment;
  var pendingRequests = 0;
  var overdueRows = <Map<String, dynamic>>[];
  var calendarSyncEnabled = false;

  try {
    nextAppointment = await repository.nextAppointment(
      workspaceId: workspaceId,
      from: now,
    );
  } catch (_) {}

  try {
    pendingRequests = await repository.pendingBookingRequests(workspaceId);
  } catch (_) {}

  try {
    overdueRows = await repository.overduePayments(workspaceId);
  } catch (_) {}

  try {
    calendarSyncEnabled = await repository.calendarSyncEnabled(workspaceId);
  } catch (_) {}

  return DashboardFocus(
    nextAppointment: nextAppointment,
    pendingBookingRequests: pendingRequests,
    overduePayments: overdueRows.length,
    overdueTotal: _sumTotals(overdueRows),
    calendarSyncEnabled: calendarSyncEnabled,
  );
});
