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
  if (field.isNotEmpty || record.isNotEmpty) finishRecord();
  if (records.isEmpty) {
    return CsvTable(headers: const [], rows: const [], delimiter: delimiter);
  }
  final width = records.first.length;
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
  final counts = <String, int>{
    ',': ','.allMatches(firstLine).length,
    ';': ';'.allMatches(firstLine).length,
    '\t': '\t'.allMatches(firstLine).length,
  };
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
