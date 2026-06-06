String slateShortDate(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(date);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff > 1 && diff <= 7) {
    return '${_weekday(target)} ${target.day} ${_month(target)}';
  }
  return '${_weekday(target)} ${target.day} ${_month(target)}';
}

String slateTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String slateTimeRange(DateTime start, DateTime? end) {
  if (end == null) return slateTime(start);
  return '${slateTime(start)}-${slateTime(end)}';
}

String slateDueLabel(DateTime dueDate, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final due = _dateOnly(dueDate);
  final diff = due.difference(today).inDays;
  if (diff < 0) return 'Overdue ${-diff}d';
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  return 'Due ${slateShortDate(due, now: today)}';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _weekday(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[date.weekday - 1];
}

String _month(DateTime date) {
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
  return months[date.month - 1];
}
