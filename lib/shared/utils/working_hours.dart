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
  if (map['enabled'] != true) return const [];

  final blocks = map['blocks'];
  if (blocks is List) {
    return blocks
        .whereType<Map>()
        .map((block) {
          final data = Map<String, dynamic>.from(block);
          final start = data['start'];
          final end = data['end'];
          return WorkingHourBlock(
            start: start is String ? start : '',
            end: end is String ? end : '',
          );
        })
        .where(
          (block) =>
              block.start.trim().isNotEmpty && block.end.trim().isNotEmpty,
        )
        .toList();
  }

  final start = _legacyTimeValue(map, const ['start', 'open'], '09:00');
  final end = _legacyTimeValue(map, const ['end', 'close'], '17:00');
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
  final localStart = start.toLocal();
  final localEnd = end.toLocal();
  if (!localEnd.isAfter(localStart) ||
      localStart.year != localEnd.year ||
      localStart.month != localEnd.month ||
      localStart.day != localEnd.day) {
    return false;
  }

  final value = workingHoursValueForDate(hours, localStart);
  final blocks = workingHourBlocks(value);
  if (blocks.isEmpty) return false;

  final startSeconds =
      localStart.hour * 3600 + localStart.minute * 60 + localStart.second;
  final endSeconds =
      localEnd.hour * 3600 + localEnd.minute * 60 + localEnd.second;
  return blocks.any((block) {
    final blockStart = _timeToMinutes(block.start);
    final blockEnd = _timeToMinutes(block.end);
    if (blockStart == null || blockEnd == null || blockEnd <= blockStart) {
      return false;
    }
    return startSeconds >= blockStart * 60 && endSeconds <= blockEnd * 60;
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
  if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

String _legacyTimeValue(
  Map<String, dynamic> map,
  List<String> keys,
  String fallback,
) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    return value is String ? value : '';
  }
  return fallback;
}
