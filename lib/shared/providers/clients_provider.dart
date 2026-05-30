import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';

final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(clientsRepositoryProvider).list(workspaceId);
});

final clientCrmRecordsProvider = FutureProvider<List<ClientCrmRecord>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  final clients = await ref.watch(clientsRepositoryProvider).list(workspaceId);
  final appointments = await ref
      .watch(appointmentsRepositoryProvider)
      .list(workspaceId);
  final payments = await ref
      .watch(paymentsRepositoryProvider)
      .list(workspaceId);
  final tasks = await ref.watch(tasksRepositoryProvider).list(workspaceId);

  return clients.map((client) {
    final clientAppointments = appointments
        .where((item) => item.contactId == client.id)
        .toList();
    final clientPayments = payments
        .where((item) => item.contactId == client.id)
        .toList();
    final clientTasks = tasks
        .where((item) => item.contactId == client.id)
        .toList();

    return ClientCrmRecord(
      client: client,
      bookingCount: clientAppointments.length,
      completedBookingCount: clientAppointments
          .where((item) => item.status == 'completed')
          .length,
      nextBooking: _nextBooking(clientAppointments),
      lastBooking: _lastBooking(clientAppointments),
      lifetimeValue: clientPayments
          .where((item) => item.status == 'paid')
          .fold<double>(0, (sum, item) => sum + item.amountPaid),
      outstandingBalance: clientPayments
          .where((item) => item.status != 'paid')
          .fold<double>(0, (sum, item) => sum + item.total),
      openTaskCount: clientTasks.where((item) => item.status != 'done').length,
      overdueTaskCount: clientTasks
          .where((item) => item.status != 'done' && _isOverdue(item.dueDate))
          .length,
    );
  }).toList();
});

class ClientCrmRecord {
  final Client client;
  final int bookingCount;
  final int completedBookingCount;
  final Appointment? nextBooking;
  final Appointment? lastBooking;
  final double lifetimeValue;
  final double outstandingBalance;
  final int openTaskCount;
  final int overdueTaskCount;

  const ClientCrmRecord({
    required this.client,
    required this.bookingCount,
    required this.completedBookingCount,
    required this.nextBooking,
    required this.lastBooking,
    required this.lifetimeValue,
    required this.outstandingBalance,
    required this.openTaskCount,
    required this.overdueTaskCount,
  });

  bool get needsAttention =>
      overdueTaskCount > 0 || outstandingBalance > 0 || client.status == 'lead';

  bool get isLead => client.status == 'lead';

  bool get isDormant {
    final latest = lastBooking?.startTime ?? client.lastActivityAt;
    if (latest == null) return false;
    return DateTime.now().difference(latest).inDays >= 60;
  }

  String get segment {
    if (client.status == 'lead') return 'Lead';
    if (outstandingBalance > 0 || overdueTaskCount > 0) return 'Attention';
    if (isDormant) return 'Dormant';
    if (completedBookingCount >= 3) return 'Regular';
    return 'Active';
  }

  int get attentionScore {
    var score = 0;
    if (client.status == 'lead') score += 4;
    if (overdueTaskCount > 0) score += 5;
    if (outstandingBalance > 0) score += 3;
    if (nextBooking != null) score += 1;
    if (isDormant) score += 2;
    return score;
  }
}

Appointment? _nextBooking(List<Appointment> appointments) {
  final now = DateTime.now();
  final future =
      appointments
          .where(
            (item) => item.startTime.isAfter(now) && item.status != 'cancelled',
          )
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return future.isEmpty ? null : future.first;
}

Appointment? _lastBooking(List<Appointment> appointments) {
  final now = DateTime.now();
  final past =
      appointments.where((item) => item.startTime.isBefore(now)).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
  return past.isEmpty ? null : past.first;
}

bool _isOverdue(DateTime? date) {
  if (date == null) return false;
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dueOnly = DateTime(date.year, date.month, date.day);
  return dueOnly.isBefore(todayOnly);
}
