const List<String> workingHourDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const Map<String, String> shortToLongDay = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
  'Sat': 'Saturday',
  'Sun': 'Sunday',
};

class WorkingHourBlock {
  final String start;
  final String end;

  const WorkingHourBlock({required this.start, required this.end});

  Map<String, dynamic> toMap() => {'start': start, 'end': end};
}

List<WorkingHourBlock> workingHourBlocks(dynamic value) {
  final map = value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};
  final enabled = map['enabled'] as bool? ?? false;
  if (!enabled) return const [];

  final blocks = map['blocks'];
  if (blocks is List) {
    return blocks
        .whereType<Map>()
        .map((block) {
          final data = Map<String, dynamic>.from(block);
          return WorkingHourBlock(
            start: data['start'] as String? ?? '09:00',
            end: data['end'] as String? ?? '17:00',
          );
        })
        .where(
          (block) =>
              block.start.trim().isNotEmpty && block.end.trim().isNotEmpty,
        )
        .toList();
  }

  final start = map['start'] as String? ?? map['open'] as String? ?? '09:00';
  final end = map['end'] as String? ?? map['close'] as String? ?? '17:00';
  return [WorkingHourBlock(start: start, end: end)];
}

String formatWorkingHourValue(dynamic value) {
  final blocks = workingHourBlocks(value);
  if (blocks.isEmpty) return 'Closed';
  return blocks.map((block) => '${block.start} - ${block.end}').join(', ');
}

String weekdayName(DateTime date) => workingHourDays[date.weekday - 1];

dynamic workingHoursValueForDate(Map<String, dynamic> hours, DateTime date) {
  final longName = weekdayName(date);
  final shortName = shortToLongDay.entries
      .firstWhere((entry) => entry.value == longName)
      .key;
  return hours[longName] ?? hours[shortName];
}

bool isWithinWorkingHours({
  required Map<String, dynamic> hours,
  required DateTime start,
  required DateTime end,
}) {
  final value = workingHoursValueForDate(hours, start);
  final blocks = workingHourBlocks(value);
  if (blocks.isEmpty) return false;

  final startMins = start.hour * 60 + start.minute;
  final endMins = end.hour * 60 + end.minute;
  return blocks.any((block) {
    final blockStart = _timeToMinutes(block.start);
    final blockEnd = _timeToMinutes(block.end);
    if (blockStart == null || blockEnd == null) return false;
    return startMins >= blockStart && endMins <= blockEnd;
  });
}

Map<String, dynamic> defaultWorkingHours() => {
  for (final day in workingHourDays)
    day: {
      'enabled': day != 'Sunday',
      'blocks': [
        {
          'start': day == 'Saturday' ? '09:00' : '08:00',
          'end': day == 'Saturday' ? '14:00' : '14:00',
        },
        if (day != 'Saturday' && day != 'Sunday')
          {'start': '16:00', 'end': '21:00'},
      ],
    },
};

int? _timeToMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}
