import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import '../utils/currency_format.dart';
import 'appointments_provider.dart';
import 'clients_provider.dart';
import 'finance_provider.dart';
import 'tasks_provider.dart';
import 'workspace_provider.dart';

const dashboardUnpaidThreshold = Duration(days: 3);
const dashboardUncontactedThreshold = Duration(days: 7);
const dashboardClientFollowUpThreshold = Duration(days: 42);

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

  const DashboardFocus({
    required this.nextAppointment,
    required this.pendingBookingRequests,
    required this.overduePayments,
    required this.overdueTotal,
  });

  bool get hasAttention =>
      pendingBookingRequests > 0 ||
      overduePayments > 0 ||
      nextAppointment != null;
}

DashboardRevenue dashboardRevenueFromFinance(FinanceSummary summary) {
  return DashboardRevenue(
    weekTotal: summary.thisWeekPaid,
    monthTotal: summary.thisMonthPaid,
    weekExpenses: summary.thisWeekExpenses,
    monthExpenses: summary.thisMonthExpenses,
    outstanding: summary.unpaid + summary.overdue,
    revenueTarget: summary.monthlyTarget,
  );
}

DashboardFocus dashboardFocusFrom({
  required Map<String, dynamic>? nextAppointment,
  required int pendingBookingRequests,
  required List<Payment> payments,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final overdue = payments
      .where(
        (payment) =>
            moneyStatusFor(payment, now: current) == MoneyStatus.overdue &&
            outstandingAmountFor(payment) > 0,
      )
      .toList();
  return DashboardFocus(
    nextAppointment: nextAppointment,
    pendingBookingRequests: pendingBookingRequests,
    overduePayments: overdue.length,
    overdueTotal: overdue.fold<double>(
      0,
      (sum, payment) => sum + outstandingAmountFor(payment),
    ),
  );
}

final dashboardRevenueProvider = FutureProvider<DashboardRevenue>((ref) async {
  final summary = await ref.watch(financeSummaryProvider.future);
  return dashboardRevenueFromFinance(summary);
});

final todayAppointmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  final now = DateTime.now();
  final startOfToday = startOfDay(now);
  final startOfTomorrow = addBusinessCalendarDays(startOfToday, 1);

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
    );
  }

  final repository = ref.watch(dashboardRepositoryProvider);
  final now = DateTime.now();

  final nextAppointmentFuture = repository.nextAppointment(
    workspaceId: workspaceId,
    from: now,
  );
  final pendingRequestsFuture = repository.pendingBookingRequests(workspaceId);
  final paymentsFuture = ref.watch(invoicesProvider.future);

  return dashboardFocusFrom(
    nextAppointment: await nextAppointmentFuture,
    pendingBookingRequests: await pendingRequestsFuture,
    payments: await paymentsFuture,
    now: now,
  );
});

enum DashboardAttentionType {
  bookingRequest,
  unpaid,
  overdueTask,
  clientFollowUp,
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
    final appointmentsFuture = ref.watch(appointmentsProvider.future);
    final clientsFuture = ref.watch(clientsProvider.future);
    final focusFuture = ref.watch(dashboardFocusProvider.future);

    final payments = await paymentsFuture;
    final tasks = await tasksFuture;
    final appointments = await appointmentsFuture;
    final clients = await clientsFuture;
    final focus = await focusFuture;

    return buildDashboardAttentionItems(
      pendingBookingRequests: focus.pendingBookingRequests,
      payments: payments,
      tasks: tasks,
      appointments: appointments,
      clients: clients,
    );
  },
);

List<DashboardAttentionItem> buildDashboardAttentionItems({
  required int pendingBookingRequests,
  required List<Payment> payments,
  required List<SlateTask> tasks,
  required List<Map<String, dynamic>> appointments,
  required List<Client> clients,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final items = <DashboardAttentionItem>[];

  if (pendingBookingRequests > 0) {
    items.add(
      DashboardAttentionItem(
        type: DashboardAttentionType.bookingRequest,
        title: pendingBookingRequests == 1
            ? 'Review booking request'
            : 'Review $pendingBookingRequests booking requests',
        detail: 'Waiting for your response',
        source: pendingBookingRequests,
        sortTime: current,
      ),
    );
  }

  for (final payment in payments) {
    if (payment.status == 'paid') continue;
    final outstanding = outstandingAmountFor(payment);
    if (outstanding <= 0) continue;
    final dueDate = payment.dueDate ?? payment.issueDate;
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (today.difference(dueDay) <= dashboardUnpaidThreshold) continue;
    items.add(
      DashboardAttentionItem(
        type: DashboardAttentionType.unpaid,
        title: 'Collect ${formatPounds(outstanding)}',
        detail: payment.clientName ?? payment.number,
        source: payment,
        sortTime: dueDate,
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

  final upcomingContactIds = appointments
      .where((row) {
        final appointment = Appointment.fromMap(row);
        return !appointment.startTime.isBefore(current) &&
            !const {
              'cancelled',
              'completed',
              'no_show',
            }.contains(appointment.status.toLowerCase());
      })
      .map((row) => row['contact_id'] as String?)
      .whereType<String>()
      .toSet();

  for (final client in clients) {
    final isLead = client.status == 'lead';
    final isActiveClient = client.status == 'active';
    if ((!isLead && !isActiveClient) ||
        upcomingContactIds.contains(client.id)) {
      continue;
    }
    final latest = client.lastActivityAt ?? client.createdAt;
    if (latest == null) continue;
    final age = current.difference(latest);
    final threshold = isLead
        ? dashboardUncontactedThreshold
        : dashboardClientFollowUpThreshold;
    if (age < threshold) continue;
    items.add(
      DashboardAttentionItem(
        type: DashboardAttentionType.clientFollowUp,
        title: isLead
            ? 'Contact ${client.name}'
            : 'Reconnect with ${client.name}',
        detail: isLead
            ? 'Lead waiting ${age.inDays}d'
            : 'No booking in ${age.inDays ~/ 7}w',
        source: client,
        sortTime: latest,
      ),
    );
  }

  items.sort((a, b) {
    final priority = _dashboardAttentionPriority(
      a.type,
    ).compareTo(_dashboardAttentionPriority(b.type));
    if (priority != 0) return priority;
    return a.sortTime.compareTo(b.sortTime);
  });
  return items;
}

int _dashboardAttentionPriority(DashboardAttentionType type) {
  return switch (type) {
    DashboardAttentionType.bookingRequest => 0,
    DashboardAttentionType.overdueTask => 1,
    DashboardAttentionType.unpaid => 2,
    DashboardAttentionType.clientFollowUp => 3,
  };
}
