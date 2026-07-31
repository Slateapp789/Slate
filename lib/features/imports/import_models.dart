import 'dart:convert';

class ImportCandidate {
  final String sourceId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final bool likelyDuplicate;

  const ImportCandidate({
    required this.sourceId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.likelyDuplicate = false,
  });

  ImportCandidate copyWith({bool? likelyDuplicate}) => ImportCandidate(
    sourceId: sourceId,
    name: name,
    phone: phone,
    email: email,
    address: address,
    likelyDuplicate: likelyDuplicate ?? this.likelyDuplicate,
  );
}

/// The deterministic result of one import attempt.
///
/// Import screens use this to remove completed source items while leaving
/// anything that was not completed in the retry set. This prevents a partial
/// retry from creating the same successful item twice.
class ImportAttemptResult<T> {
  final Set<T> completed;
  final Set<T> retryable;

  const ImportAttemptResult({required this.completed, required this.retryable});
}

ImportAttemptResult<T> reconcileImportAttempt<T>({
  required Iterable<T> attempted,
  required Iterable<T> completed,
}) {
  final attemptedItems = attempted.toSet();
  final completedItems = completed.where(attemptedItems.contains).toSet();
  return ImportAttemptResult(
    completed: completedItems,
    retryable: attemptedItems.difference(completedItems),
  );
}

/// Returns the retry-stable workflow key for one device-calendar event.
///
/// Calendar and event identifiers are preferred so editing an event's title or
/// time does not create a second Workloop booking on retry. Some providers do
/// not expose an event identifier, so the fallback uses the reviewed event
/// details instead.
String calendarImportIdempotencyKey({
  required String calendarId,
  required DateTime startTime,
  String? eventId,
  DateTime? endTime,
  String? title,
  String? location,
}) {
  final safeCalendarId = calendarId.trim().isEmpty
      ? 'unknown-calendar'
      : calendarId.trim();
  final safeEventId = eventId?.trim();
  final identity = safeEventId?.isNotEmpty == true
      ? 'calendar=$safeCalendarId|event=$safeEventId'
      : [
          'calendar=$safeCalendarId',
          'title=${normaliseImportValue(title)}',
          'start=${startTime.toUtc().toIso8601String()}',
          'end=${endTime?.toUtc().toIso8601String() ?? ''}',
          'location=${normaliseImportValue(location)}',
        ].join('|');
  return 'calendar-import-v1-${_stableImportFingerprint(identity)}';
}

String _stableImportFingerprint(String value) {
  final bytes = utf8.encode(value);
  const seeds = [0x811c9dc5, 0x9e3779b9, 0x85ebca6b, 0xc2b2ae35];
  return seeds.map((seed) {
    var hash = seed;
    for (final byte in bytes) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }).join();
}

List<String> taskTitlesFromImportText(String content) {
  return content
      .split(RegExp(r'\r\n?|\n'))
      .map((line) => line.replaceFirst(RegExp(r'^\s*[-*\d.)]+\s*'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

String normaliseImportValue(String? value) {
  return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String normalisePhone(String? value) {
  return (value ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
}

bool isLikelyDuplicate({
  required ImportCandidate candidate,
  required Iterable<({String name, String? phone, String? email})> existing,
}) {
  final candidateName = normaliseImportValue(candidate.name);
  final candidatePhone = normalisePhone(candidate.phone);
  final candidateEmail = normaliseImportValue(candidate.email);
  return existing.any((item) {
    final sameEmail =
        candidateEmail.isNotEmpty &&
        candidateEmail == normaliseImportValue(item.email);
    final samePhone =
        candidatePhone.isNotEmpty &&
        candidatePhone == normalisePhone(item.phone);
    final sameName =
        candidateName.isNotEmpty &&
        candidateName == normaliseImportValue(item.name);
    return sameEmail || samePhone || sameName;
  });
}

class CsvTable {
  final List<String> headers;
  final List<List<String>> rows;
  final String delimiter;

  const CsvTable({
    required this.headers,
    required this.rows,
    required this.delimiter,
  });
}

CsvTable parseCsv(String source) {
  final text = source.replaceFirst('\ufeff', '');
  final firstLine = text.split(RegExp(r'\r?\n')).firstOrNull ?? '';
  final delimiter = _detectDelimiter(firstLine);
  final records = <List<String>>[];
  var record = <String>[];
  var field = StringBuffer();
  var quoted = false;

  void finishField() {
    record.add(field.toString().trim());
    field = StringBuffer();
  }

  void finishRecord() {
    finishField();
    if (record.any((value) => value.isNotEmpty)) records.add(record);
    record = <String>[];
  }

  for (var index = 0; index < text.length; index++) {
    final char = text[index];
    if (char == '"') {
      if (quoted && index + 1 < text.length && text[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
      continue;
    }
    if (!quoted && char == delimiter) {
      finishField();
    } else if (!quoted && (char == '\n' || char == '\r')) {
      if (char == '\r' && index + 1 < text.length && text[index + 1] == '\n') {
        index++;
      }
      finishRecord();
    } else {
      field.write(char);
    }
  }
  if (quoted) {
    throw const FormatException('CSV contains an unclosed quoted field.');
  }
  if (field.isNotEmpty || record.isNotEmpty) finishRecord();
  if (records.isEmpty) {
    return CsvTable(headers: const [], rows: const [], delimiter: delimiter);
  }
  final width = records.first.length;
  if (records.skip(1).any((row) => row.length > width)) {
    throw const FormatException(
      'CSV contains a row with more columns than its header.',
    );
  }
  final rows = records
      .skip(1)
      .map(
        (row) => [
          ...row,
          ...List.filled((width - row.length).clamp(0, width), ''),
        ],
      )
      .map((row) => row.take(width).toList())
      .toList();
  return CsvTable(headers: records.first, rows: rows, delimiter: delimiter);
}

String _detectDelimiter(String firstLine) {
  final counts = <String, int>{',': 0, ';': 0, '\t': 0};
  var quoted = false;
  for (var index = 0; index < firstLine.length; index++) {
    final character = firstLine[index];
    if (character == '"') {
      if (quoted &&
          index + 1 < firstLine.length &&
          firstLine[index + 1] == '"') {
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted && counts.containsKey(character)) {
      counts[character] = counts[character]! + 1;
    }
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
