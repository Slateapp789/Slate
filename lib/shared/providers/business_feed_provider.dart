import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business_feed_item.dart';
import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import 'appointments_provider.dart';
import 'clients_provider.dart';
import 'finance_provider.dart';
import 'notes_provider.dart';
import 'tasks_provider.dart';
import 'workspace_provider.dart';

final businessFeedProvider = FutureProvider<List<BusinessFeedItem>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  final appointments = await ref.watch(appointmentsProvider.future);
  final payments = await ref.watch(invoicesProvider.future);
  final expenses = await ref.watch(expensesProvider.future);
  final tasks = await ref.watch(allTasksProvider.future);
  final notes = await ref.watch(allNotesProvider.future);
  final clients = await ref.watch(clientsProvider.future);
  final finance = await ref.watch(financeSummaryProvider.future);
  final bookingRequests = workspaceId == null
      ? <BookingRequest>[]
      : await ref.watch(profileRepositoryProvider).bookingRequests(workspaceId);

  return buildBusinessFeedItems(
    appointments: appointments,
    payments: payments,
    expenses: expenses,
    tasks: tasks,
    notes: notes,
    clients: clients,
    bookingRequests: bookingRequests,
    finance: finance,
  );
});

List<BusinessFeedItem> buildBusinessFeedItems({
  required List<Map<String, dynamic>> appointments,
  required List<Payment> payments,
  required List<Expense> expenses,
  required List<SlateTask> tasks,
  required List<SlateNote> notes,
  required List<Client> clients,
  required List<BookingRequest> bookingRequests,
  required FinanceSummary finance,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = _startOfDay(current);
  final tomorrow = today.add(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));
  final typedAppointments = appointments
      .map(Appointment.fromMap)
      .where((item) => item.startTime.year > 1970)
      .toList();
  final upcomingContactIds = typedAppointments
      .where(
        (item) =>
            item.contactId != null &&
            item.startTime.isAfter(current) &&
            !_cancelledStatuses.contains(item.status.toLowerCase()),
      )
      .map((item) => item.contactId!)
      .toSet();
  final items = <BusinessFeedItem>[];

  final activeToday = typedAppointments.where((item) {
    final start = item.startTime.toLocal();
    return !_cancelledStatuses.contains(item.status.toLowerCase()) &&
        !start.isBefore(today) &&
        start.isBefore(tomorrow);
  }).toList();
  final expectedToday = activeToday.fold<double>(
    0,
    (sum, item) => sum + item.price,
  );
  final dueTasks = tasks.where((task) {
    final due = task.dueDate;
    if (task.status == 'done' || due == null) return false;
    return !_startOfDay(due).isAfter(today);
  }).toList();
  final overdueTasks = dueTasks
      .where((task) => _startOfDay(task.dueDate!).isBefore(today))
      .toList();
  final overduePayments = payments.where((payment) {
    return payment.status != 'paid' &&
        _startOfDay(payment.dueDate ?? payment.issueDate).isBefore(today);
  }).toList();
  final pendingRequests = bookingRequests
      .where((request) => request.status == 'pending')
      .toList();

  items.add(
    BusinessFeedItem(
      id: 'daily-summary-${_dateKey(today)}',
      type: BusinessFeedItemType.dailySummary,
      title: _dailySummaryTitle(
        appointmentCount: activeToday.length,
        expectedToday: expectedToday,
        dueTaskCount: dueTasks.length,
        overduePaymentCount: overduePayments.length,
      ),
      subtitle: _primaryRecommendation(
        overduePayments: overduePayments,
        overdueTasks: overdueTasks,
        pendingRequests: pendingRequests,
        activeToday: activeToday,
      ),
      timestamp: current,
      priority: overduePayments.isNotEmpty || overdueTasks.isNotEmpty
          ? BusinessFeedPriority.attention
          : BusinessFeedPriority.normal,
      sourceType: BusinessFeedSourceType.system,
      actionLabel: overduePayments.isNotEmpty
          ? 'Open Money'
          : overdueTasks.isNotEmpty
          ? 'Open Tasks'
          : activeToday.isNotEmpty
          ? 'Review bookings'
          : null,
      routeTarget: overduePayments.isNotEmpty
          ? '/payments'
          : overdueTasks.isNotEmpty
          ? '/tasks'
          : activeToday.isNotEmpty
          ? '/work'
          : null,
      icon: 'sparkles',
      moduleKey: 'home',
    ),
  );

  _addBookingItems(items, typedAppointments, current, today, tomorrow);
  _addPaymentItems(items, payments, current, today, weekAgo);
  _addExpenseItems(items, expenses, weekAgo);
  _addTaskItems(items, tasks, today);
  _addNoteItems(items, notes, weekAgo);
  _addClientFollowUps(items, clients, upcomingContactIds, current);
  _addBookingRequestItems(items, pendingRequests, current);
  _addQuietDayItem(items, activeToday, current, today);
  _addWeeklyProgressItem(items, finance, current);

  items.sort((a, b) {
    final priority = _priorityRank(
      a.priority,
    ).compareTo(_priorityRank(b.priority));
    if (priority != 0) return priority;
    return b.timestamp.compareTo(a.timestamp);
  });
  return _dedupeById(items).take(80).toList();
}

List<BusinessFeedItem> filteredBusinessFeedItems(
  List<BusinessFeedItem> items,
  BusinessFeedFilter filter,
) {
  return items.where((item) => item.matchesFilter(filter)).toList();
}

void _addBookingItems(
  List<BusinessFeedItem> items,
  List<Appointment> appointments,
  DateTime current,
  DateTime today,
  DateTime tomorrow,
) {
  final upcomingLimit = current.add(const Duration(days: 14));
  for (final appointment in appointments) {
    final start = appointment.startTime.toLocal();
    final status = appointment.status.toLowerCase();
    if (_cancelledStatuses.contains(status)) continue;

    final isToday = !start.isBefore(today) && start.isBefore(tomorrow);
    final isUpcoming = start.isAfter(tomorrow) && start.isBefore(upcomingLimit);
    if (!isToday && !isUpcoming) continue;

    items.add(
      BusinessFeedItem(
        id: 'booking-${appointment.id}',
        type: isToday
            ? BusinessFeedItemType.bookingToday
            : BusinessFeedItemType.bookingUpcoming,
        title: isToday
            ? '${appointment.clientName ?? 'Booking'} today'
            : '${appointment.clientName ?? 'Booking'} is coming up',
        subtitle:
            '${_timeLabel(start)} · ${appointment.serviceName ?? appointment.title ?? 'Booking'}',
        timestamp: start,
        priority: isToday
            ? BusinessFeedPriority.normal
            : BusinessFeedPriority.positive,
        sourceType: BusinessFeedSourceType.booking,
        sourceId: appointment.id,
        actionLabel: 'Open bookings',
        routeTarget: '/work',
        icon: 'calendar',
        moduleKey: 'bookings',
      ),
    );
  }
}

void _addPaymentItems(
  List<BusinessFeedItem> items,
  List<Payment> payments,
  DateTime current,
  DateTime today,
  DateTime weekAgo,
) {
  for (final payment in payments) {
    final due = _startOfDay(payment.dueDate ?? payment.issueDate);
    if (payment.status == 'paid') {
      final paidDay = _startOfDay(payment.issueDate);
      if (paidDay.isBefore(weekAgo)) continue;
      items.add(
        BusinessFeedItem(
          id: 'payment-paid-${payment.id}',
          type: BusinessFeedItemType.paymentReceived,
          title:
              '£${payment.total.toStringAsFixed(0)} received${payment.clientName == null ? '' : ' from ${payment.clientName}'}',
          subtitle: 'Paid ${_relativeDay(paidDay, today)}',
          timestamp: payment.issueDate,
          priority: BusinessFeedPriority.positive,
          sourceType: BusinessFeedSourceType.payment,
          sourceId: payment.id,
          actionLabel: 'Open Money',
          routeTarget: '/payments',
          icon: 'banknote',
          moduleKey: 'money',
        ),
      );
      continue;
    }

    if (due.isBefore(today)) {
      final days = today.difference(due).inDays;
      items.add(
        BusinessFeedItem(
          id: 'payment-overdue-${payment.id}',
          type: BusinessFeedItemType.invoiceOverdue,
          title: 'Invoice overdue',
          subtitle:
              '£${payment.total.toStringAsFixed(0)}${payment.clientName == null ? '' : ' from ${payment.clientName}'} was due $days day${days == 1 ? '' : 's'} ago',
          timestamp: due,
          priority: BusinessFeedPriority.attention,
          sourceType: BusinessFeedSourceType.payment,
          sourceId: payment.id,
          actionLabel: 'Send reminder',
          routeTarget: '/payments',
          icon: 'alert',
          moduleKey: 'money',
        ),
      );
    } else if (!due.isAfter(today.add(const Duration(days: 7)))) {
      items.add(
        BusinessFeedItem(
          id: 'payment-unpaid-${payment.id}',
          type: BusinessFeedItemType.invoiceUnpaid,
          title: 'Payment still open',
          subtitle:
              '£${payment.total.toStringAsFixed(0)}${payment.clientName == null ? '' : ' from ${payment.clientName}'} due ${_relativeDay(due, today)}',
          timestamp: due,
          priority: BusinessFeedPriority.normal,
          sourceType: BusinessFeedSourceType.payment,
          sourceId: payment.id,
          actionLabel: 'Open Money',
          routeTarget: '/payments',
          icon: 'clock',
          moduleKey: 'money',
        ),
      );
    }
  }
}

void _addExpenseItems(
  List<BusinessFeedItem> items,
  List<Expense> expenses,
  DateTime weekAgo,
) {
  for (final expense in expenses.take(12)) {
    if (expense.expenseDate.isBefore(weekAgo)) continue;
    items.add(
      BusinessFeedItem(
        id: 'expense-${expense.id}',
        type: BusinessFeedItemType.expenseRecorded,
        title: '£${expense.amount.toStringAsFixed(0)} expense recorded',
        subtitle: expense.category,
        timestamp: expense.expenseDate,
        priority: BusinessFeedPriority.normal,
        sourceType: BusinessFeedSourceType.expense,
        sourceId: expense.id,
        actionLabel: 'Open Money',
        routeTarget: '/payments',
        icon: 'receipt',
        moduleKey: 'money',
      ),
    );
  }
}

void _addTaskItems(
  List<BusinessFeedItem> items,
  List<SlateTask> tasks,
  DateTime today,
) {
  for (final task in tasks) {
    final due = task.dueDate;
    if (task.status == 'done' || due == null) continue;
    final dueDay = _startOfDay(due);
    final isOverdue = dueDay.isBefore(today);
    if (!isOverdue && dueDay.isAfter(today)) continue;

    items.add(
      BusinessFeedItem(
        id: 'task-${task.id}',
        type: isOverdue
            ? BusinessFeedItemType.taskOverdue
            : BusinessFeedItemType.taskDue,
        title: task.title,
        subtitle: isOverdue
            ? 'Overdue${task.clientName == null ? '' : ' · ${task.clientName}'}'
            : 'Due today${task.clientName == null ? '' : ' · ${task.clientName}'}',
        timestamp: dueDay,
        priority: isOverdue
            ? BusinessFeedPriority.attention
            : BusinessFeedPriority.normal,
        sourceType: BusinessFeedSourceType.task,
        sourceId: task.id,
        actionLabel: 'Open Tasks',
        routeTarget: '/tasks',
        icon: isOverdue ? 'alert' : 'check',
        moduleKey: 'tasks',
      ),
    );
  }
}

void _addNoteItems(
  List<BusinessFeedItem> items,
  List<SlateNote> notes,
  DateTime weekAgo,
) {
  for (final note in notes.take(10)) {
    final timestamp = note.updatedAt ?? note.createdAt;
    if (timestamp == null || timestamp.isBefore(weekAgo)) continue;
    items.add(
      BusinessFeedItem(
        id: 'note-${note.id}',
        type: BusinessFeedItemType.noteCreated,
        title: note.pinned ? 'Pinned note: ${note.title}' : note.title,
        subtitle: note.clientName ?? 'Recent note',
        timestamp: timestamp,
        priority: note.pinned
            ? BusinessFeedPriority.positive
            : BusinessFeedPriority.normal,
        sourceType: BusinessFeedSourceType.note,
        sourceId: note.id,
        actionLabel: 'Open Notes',
        routeTarget: '/notes',
        icon: 'note',
        moduleKey: 'notes',
      ),
    );
  }
}

void _addClientFollowUps(
  List<BusinessFeedItem> items,
  List<Client> clients,
  Set<String> upcomingContactIds,
  DateTime current,
) {
  for (final client in clients) {
    final latest = client.lastActivityAt ?? client.createdAt;
    if (latest == null || upcomingContactIds.contains(client.id)) continue;
    final days = current.difference(latest).inDays;
    final isLead = client.status == 'lead';
    if (!isLead && days < 42) continue;
    if (isLead && days < 7) continue;
    items.add(
      BusinessFeedItem(
        id: 'client-follow-up-${client.id}',
        type: BusinessFeedItemType.clientFollowUp,
        title: '${client.name} is due a follow-up',
        subtitle: isLead
            ? 'Lead waiting $days day${days == 1 ? '' : 's'}'
            : 'No booking in ${days ~/ 7} week${days ~/ 7 == 1 ? '' : 's'}',
        timestamp: latest,
        priority: BusinessFeedPriority.attention,
        sourceType: BusinessFeedSourceType.client,
        sourceId: client.id,
        actionLabel: 'Open Clients',
        routeTarget: '/clients',
        icon: 'user',
        moduleKey: 'clients',
      ),
    );
  }
}

void _addBookingRequestItems(
  List<BusinessFeedItem> items,
  List<BookingRequest> requests,
  DateTime current,
) {
  for (final request in requests.take(8)) {
    final timestamp = request.createdAt ?? current;
    items.add(
      BusinessFeedItem(
        id: 'booking-request-${request.id}',
        type: BusinessFeedItemType.bookingRequestNew,
        title: 'New booking request',
        subtitle:
            '${request.name}${request.preferredTimeText == null ? '' : ' requested ${request.preferredTimeText}'}',
        timestamp: timestamp,
        priority: BusinessFeedPriority.attention,
        sourceType: BusinessFeedSourceType.bookingRequest,
        sourceId: request.id,
        actionLabel: 'Review request',
        routeTarget: '/booking-requests',
        icon: 'inbox',
        moduleKey: 'bookings',
      ),
    );
  }
}

void _addQuietDayItem(
  List<BusinessFeedItem> items,
  List<Appointment> activeToday,
  DateTime current,
  DateTime today,
) {
  final afternoonStart = DateTime(today.year, today.month, today.day, 14);
  final hasAfternoonBooking = activeToday.any(
    (item) => item.startTime.toLocal().isAfter(afternoonStart),
  );
  if (current.isAfter(afternoonStart) || hasAfternoonBooking) return;
  items.add(
    BusinessFeedItem(
      id: 'quiet-afternoon-${_dateKey(today)}',
      type: BusinessFeedItemType.quietDayDetected,
      title: 'Quiet afternoon detected',
      subtitle: 'No bookings after 2pm today',
      timestamp: afternoonStart,
      priority: BusinessFeedPriority.normal,
      sourceType: BusinessFeedSourceType.system,
      actionLabel: 'Open Bookings',
      routeTarget: '/work',
      icon: 'clock',
      moduleKey: 'home',
    ),
  );
}

void _addWeeklyProgressItem(
  List<BusinessFeedItem> items,
  FinanceSummary finance,
  DateTime current,
) {
  if (finance.weeklyTarget <= 0) return;
  final percent = (finance.weeklyProgress * 100).round();
  items.add(
    BusinessFeedItem(
      id: 'weekly-target-${_dateKey(_startOfWeek(current))}',
      type: BusinessFeedItemType.weeklyTargetProgress,
      title: '$percent% of weekly target reached',
      subtitle:
          '£${finance.thisWeekPaid.toStringAsFixed(0)} of £${finance.weeklyTarget.toStringAsFixed(0)}',
      timestamp: current,
      priority: finance.weeklyProgress >= 1
          ? BusinessFeedPriority.positive
          : BusinessFeedPriority.normal,
      sourceType: BusinessFeedSourceType.system,
      actionLabel: 'Open Money',
      routeTarget: '/payments',
      icon: 'target',
      moduleKey: 'money',
    ),
  );
}

String _dailySummaryTitle({
  required int appointmentCount,
  required double expectedToday,
  required int dueTaskCount,
  required int overduePaymentCount,
}) {
  final parts = <String>[
    '$appointmentCount booking${appointmentCount == 1 ? '' : 's'}',
    '£${expectedToday.toStringAsFixed(0)} expected',
    '$dueTaskCount task${dueTaskCount == 1 ? '' : 's'} due',
  ];
  if (overduePaymentCount > 0) {
    parts.add(
      '$overduePaymentCount payment${overduePaymentCount == 1 ? '' : 's'} overdue',
    );
  }
  return 'Today: ${parts.join(', ')}.';
}

String _primaryRecommendation({
  required List<Payment> overduePayments,
  required List<SlateTask> overdueTasks,
  required List<BookingRequest> pendingRequests,
  required List<Appointment> activeToday,
}) {
  if (overduePayments.isNotEmpty) return 'Send overdue payment reminder';
  if (pendingRequests.isNotEmpty) return 'Review new booking request';
  if (overdueTasks.isNotEmpty) return 'Clear overdue tasks';
  if (activeToday.isNotEmpty) return 'Review today\'s bookings';
  return 'No urgent actions today';
}

List<BusinessFeedItem> _dedupeById(List<BusinessFeedItem> items) {
  final seen = <String>{};
  return items.where((item) => seen.add(item.id)).toList();
}

DateTime _startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime _startOfWeek(DateTime now) {
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _relativeDay(DateTime date, DateTime today) {
  final day = _startOfDay(date);
  if (day == today) return 'today';
  if (day == today.subtract(const Duration(days: 1))) return 'yesterday';
  if (day == today.add(const Duration(days: 1))) return 'tomorrow';
  return _dateKey(day);
}

int _priorityRank(BusinessFeedPriority priority) {
  return switch (priority) {
    BusinessFeedPriority.attention => 0,
    BusinessFeedPriority.positive => 1,
    BusinessFeedPriority.normal => 2,
  };
}

const _cancelledStatuses = {'cancelled', 'no_show'};
