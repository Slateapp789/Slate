class NoteDraft {
  final String title;
  final String body;

  const NoteDraft({required this.title, required this.body});

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;
}

NoteDraft parseNoteDraft(String text) {
  final normalized = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .trimRight();
  final lines = normalized.split('\n');
  final titleIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
  if (titleIndex == -1) return const NoteDraft(title: '', body: '');

  return NoteDraft(
    title: lines[titleIndex].trim(),
    body: lines.skip(titleIndex + 1).join('\n').trim(),
  );
}
