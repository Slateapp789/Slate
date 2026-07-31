/// Returns the start of a recurring appointment while preserving the local
/// wall-clock time selected by the business owner.
///
/// Appointment timestamps are persisted as UTC, but a weekly booking at 09:00
/// must remain at 09:00 locally when daylight-saving time changes. Calendar
/// construction is used instead of adding a fixed 7-day duration for that
/// reason.
DateTime appointmentOccurrenceStart(
  DateTime startTime,
  String? rule,
  int index,
) {
  if (index < 0) {
    throw ArgumentError.value(index, 'index', 'Must not be negative.');
  }
  if (rule == null) return startTime;

  final frequency = _ruleValue(rule, 'FREQ');
  if (frequency != 'WEEKLY' && frequency != 'MONTHLY') {
    throw ArgumentError.value(
      rule,
      'rule',
      'Only weekly and monthly recurrence rules are supported.',
    );
  }

  final rawInterval = _ruleValue(rule, 'INTERVAL');
  final interval = rawInterval == null ? 1 : int.tryParse(rawInterval);
  if (interval == null) {
    throw ArgumentError.value(
      rule,
      'rule',
      'The recurrence interval must be a whole number.',
    );
  }
  if (interval < 1 || interval > 52) {
    throw ArgumentError.value(
      rule,
      'rule',
      'The recurrence interval must be between 1 and 52.',
    );
  }
  if (index == 0) return startTime;

  final local = startTime.toLocal();
  final DateTime occurrence;
  if (frequency == 'MONTHLY') {
    final targetMonth = local.month + (index * interval);
    final targetYear = local.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    occurrence = DateTime(
      targetYear,
      normalizedMonth,
      local.day.clamp(1, lastDay),
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    );
  } else {
    occurrence = DateTime(
      local.year,
      local.month,
      local.day + (7 * interval * index),
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    );
  }

  return startTime.isUtc ? occurrence.toUtc() : occurrence;
}

String? _ruleValue(String rule, String key) {
  for (final component in rule.split(';')) {
    final separator = component.indexOf('=');
    if (separator <= 0) continue;
    if (component.substring(0, separator).trim().toUpperCase() == key) {
      return component.substring(separator + 1).trim().toUpperCase();
    }
  }
  return null;
}
