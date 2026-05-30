String buildSlateIcs(List<Map<String, dynamic>> appointments) {
  final now = _icsDate(DateTime.now().toUtc());
  final events = appointments
      .where((row) => row['start_time'] != null)
      .map((row) => _event(row, now))
      .where((event) => event.isNotEmpty)
      .join('\r\n');

  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Slate//Appointments//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    if (events.isNotEmpty) events,
    'END:VCALENDAR',
  ].join('\r\n');
}

String _event(Map<String, dynamic> row, String stamp) {
  final start = DateTime.tryParse(row['start_time'].toString())?.toUtc();
  if (start == null) return '';
  final end =
      DateTime.tryParse(row['end_time']?.toString() ?? '')?.toUtc() ??
      start.add(const Duration(hours: 1));
  final title = _clean(row['title']?.toString() ?? 'Slate appointment');
  final contact = _nestedName(row['contacts']);
  final service = _nestedName(row['services']);
  final description = _clean(
    [
      if (contact != null) 'Client: $contact',
      if (service != null) 'Service: $service',
      if (row['notes']?.toString().trim().isNotEmpty == true)
        row['notes'].toString(),
    ].join('\\n'),
  );
  final uid = _clean('${row['id'] ?? start.toIso8601String()}@slate');

  return [
    'BEGIN:VEVENT',
    'UID:$uid',
    'DTSTAMP:$stamp',
    'DTSTART:${_icsDate(start)}',
    'DTEND:${_icsDate(end)}',
    'SUMMARY:$title',
    if (description.isNotEmpty) 'DESCRIPTION:$description',
    'END:VEVENT',
  ].join('\r\n');
}

String _icsDate(DateTime date) {
  final utc = date.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}'
      '${utc.month.toString().padLeft(2, '0')}'
      '${utc.day.toString().padLeft(2, '0')}T'
      '${utc.hour.toString().padLeft(2, '0')}'
      '${utc.minute.toString().padLeft(2, '0')}'
      '${utc.second.toString().padLeft(2, '0')}Z';
}

String _clean(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', '')
    .replaceAll(',', r'\,')
    .replaceAll(';', r'\;');

String? _nestedName(dynamic value) {
  if (value is Map && value['name'] != null) return value['name'].toString();
  return null;
}
