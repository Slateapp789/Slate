import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import 'clients_provider.dart';
import 'finance_provider.dart';
import 'tasks_provider.dart';
import 'workspace_provider.dart';

const dashboardUnpaidThreshold = Duration(days: 3);
const dashboardUnconfirmedThreshold = Duration(hours: 24);
const dashboardUncontactedThreshold = Duration(days: 7);

class DashboardRevenue {
  final double weekTotal;
  final double monthTotal;
  final double weekExpenses;
  final double monthExpenses;
  final double outstanding;
  final double revenueTarget;

  const DashboardRevenue({
    required this.weekTotal,
    required this.monthTotal,
    required this.weekExpenses,
    required this.monthExpenses,
    required this.outstanding,
    required this.revenueTarget,
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

double _sumAmounts(List<Map<String, dynamic>> rows) {
  return rows.fold<double>(0, (sum, row) {
    final v = row['amount'];
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
      weekExpenses: 0,
      monthExpenses: 0,
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
  final weekExpenses = await repository.expenseTotals(
    workspaceId: workspaceId,
    expenseDateFrom: weekStart,
  );
  final monthExpenses = await repository.expenseTotals(
    workspaceId: workspaceId,
    expenseDateFrom: monthStart,
  );

  double revenueTarget = 0;
  try {
    revenueTarget = await repository.revenueTarget(workspaceId);
  } catch (_) {}

  return DashboardRevenue(
    weekTotal: _sumTotals(List<Map<String, dynamic>>.from(weekPaid)),
    monthTotal: _sumTotals(List<Map<String, dynamic>>.from(monthPaid)),
    weekExpenses: _sumAmounts(List<Map<String, dynamic>>.from(weekExpenses)),
    monthExpenses: _sumAmounts(List<Map<String, dynamic>>.from(monthExpenses)),
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

enum DashboardAttentionType {
  unpaid,
  unconfirmedAppointment,
  overdueTask,
  uncontactedLead,
}

class DashboardAttentionItem {
  final DashboardAttentionType type;
  final String title;
  final String detail;
  final Object source;
  final DateTime sortTime;

  const DashboardAttentionItem({
    required this.type,
    required this.title,
    required this.detail,
    required this.source,
    required this.sortTime,
  });
}

final dashboardAttentionProvider = FutureProvider<List<DashboardAttentionItem>>(
  (ref) async {
    final paymentsFuture = ref.watch(invoicesProvider.future);
    final tasksFuture = ref.watch(allTasksProvider.future);
    final appointmentsFuture = ref.watch(todayAppointmentsProvider.future);
    final clientsFuture = ref.watch(clientsProvider.future);

    final payments = await safeDashboardSource(
      paymentsFuture,
      const <Payment>[],
    );
    final tasks = await safeDashboardSource(tasksFuture, const <SlateTask>[]);
    final appointments = await safeDashboardSource(
      appointmentsFuture,
      const <Map<String, dynamic>>[],
    );
    final clients = await safeDashboardSource(clientsFuture, const <Client>[]);

    return buildDashboardAttentionItems(
      payments: payments,
      tasks: tasks,
      appointments: appointments,
      clients: clients,
    );
  },
);

Future<T> safeDashboardSource<T>(Future<T> future, T fallback) async {
  try {
    return await future;
  } catch (_) {
    return fallback;
  }
}

List<DashboardAttentionItem> buildDashboardAttentionItems({
  required List<Payment> payments,
  required List<SlateTask> tasks,
  required List<Map<String, dynamic>> appointments,
  required List<Client> clients,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final items = <DashboardAttentionItem>[];

  for (final payment in payments) {
    if (payment.status == 'paid') continue;
    final dueDate = payment.dueDate ?? payment.issueDate;
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (today.difference(dueDay) <= dashboardUnpaidThreshold) continue;
    items.add(
      DashboardAttentionItem(
        type: DashboardAttentionType.unpaid,
        title: 'Collect £${payment.total.toStringAsFixed(0)}',
        detail: payment.clientName ?? payment.number,
        source: payment,
        sortTime: dueDate,
      ),
    );
  }

  for (final row in appointments) {
    final appointment = Appointment.fromMap(row);
    final status = appointment.status.toLowerCase();
    final isUnconfirmed = status == 'unconfirmed' || status == 'pending';
    final startsSoon =
        appointment.startTime.isAfter(current) &&
        appointment.startTime.difference(current) <=
            dashboardUnconfirmedThreshold;
    if (!isUnconfirmed || !startsSoon) continue;
    items.add(
      DashboardAttentionItem(
        type: DashboardAttentionType.unconfirmedAppointment,
        title: 'Confirm ${appointment.clientName ?? 'appointment'}',
        detail: appointment.serviceName ?? appointment.title ?? 'Today',
        source: row,
        sortTime: appointment.startTime,
      ),
    );
  }

  for (final task in tasks) {
    final due = task.dueDate;
    if (task.status == 'done' || due == null) continue;
    final dueDay = DateTime(due.year, due.month, due.day);
    if (!dueDay.isBefore(today)) continue;
    items.add(
      DashboardAttentionItem(
        type: DashboardAttentionType.overdueTask,
        title: task.title,
        detail: task.clientName ?? 'Overdue task',
        source: task,
        sortTime: due,
      ),
    );
  }

  for (final client in clients) {
    if (client.status != 'lead') continue;
    final latest = client.lastActivityAt ?? client.createdAt;
    if (latest == null) continue;
    if (current.difference(latest) <= dashboardUncontactedThreshold) continue;
    items.add(
      DashboardAttentionItem(
        type: DashboardAttentionType.uncontactedLead,
        title: 'Contact ${client.name}',
        detail: 'Lead waiting ${current.difference(latest).inDays}d',
        source: client,
        sortTime: latest,
      ),
    );
  }

  items.sort((a, b) => a.sortTime.compareTo(b.sortTime));
  return items;
}
