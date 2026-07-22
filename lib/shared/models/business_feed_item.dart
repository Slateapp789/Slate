enum BusinessFeedItemType {
  bookingToday,
  bookingUpcoming,
  paymentReceived,
  invoiceUnpaid,
  invoiceOverdue,
  expenseRecorded,
  taskDue,
  taskOverdue,
  noteCreated,
  clientFollowUp,
  bookingRequestNew,
  quietDayDetected,
  dailySummary,
  weeklyTargetProgress,
}

enum BusinessFeedPriority { normal, attention, positive }

enum BusinessFeedSourceType {
  client,
  booking,
  payment,
  expense,
  task,
  note,
  bookingRequest,
  system,
}

enum BusinessFeedFilter { all, attention, money, bookings, tasks, clients }

class BusinessFeedItem {
  final String id;
  final BusinessFeedItemType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final BusinessFeedPriority priority;
  final BusinessFeedSourceType sourceType;
  final String? sourceId;
  final String? actionLabel;
  final String? routeTarget;
  final String icon;
  final String moduleKey;

  const BusinessFeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.priority,
    required this.sourceType,
    this.sourceId,
    this.actionLabel,
    this.routeTarget,
    required this.icon,
    required this.moduleKey,
  });

  bool matchesFilter(BusinessFeedFilter filter) {
    return switch (filter) {
      BusinessFeedFilter.all => true,
      BusinessFeedFilter.attention =>
        priority == BusinessFeedPriority.attention,
      BusinessFeedFilter.money =>
        sourceType == BusinessFeedSourceType.payment ||
            sourceType == BusinessFeedSourceType.expense,
      BusinessFeedFilter.bookings =>
        sourceType == BusinessFeedSourceType.booking ||
            sourceType == BusinessFeedSourceType.bookingRequest,
      BusinessFeedFilter.tasks => sourceType == BusinessFeedSourceType.task,
      BusinessFeedFilter.clients => sourceType == BusinessFeedSourceType.client,
    };
  }
}
