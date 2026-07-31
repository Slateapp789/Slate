import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/imports/import_models.dart';

void main() {
  group('parseCsv', () {
    test('parses quoted commas and escaped quotes', () {
      final table = parseCsv(
        'Name,Notes,Email\n"Ava Mitchell","Said ""hello"", then left",ava@example.com',
      );

      expect(table.headers, ['Name', 'Notes', 'Email']);
      expect(table.rows, hasLength(1));
      expect(table.rows.single[0], 'Ava Mitchell');
      expect(table.rows.single[1], 'Said "hello", then left');
      expect(table.rows.single[2], 'ava@example.com');
    });

    test('detects semicolon-delimited files and ignores empty rows', () {
      final table = parseCsv('Name;Phone\r\nAva;07123\r\n\r\n');

      expect(table.delimiter, ';');
      expect(table.rows, [
        ['Ava', '07123'],
      ]);
    });
  });

  group('duplicate detection', () {
    final existing = [
      (name: 'Ava Mitchell', phone: '07123 456 789', email: 'ava@example.com'),
    ];

    test('matches normalised email', () {
      const candidate = ImportCandidate(
        sourceId: '1',
        name: 'Different name',
        email: ' AVA@example.com ',
      );

      expect(
        isLikelyDuplicate(candidate: candidate, existing: existing),
        isTrue,
      );
    });

    test('matches formatted phone numbers', () {
      const candidate = ImportCandidate(
        sourceId: '2',
        name: 'Different name',
        phone: '07123-456-789',
      );

      expect(
        isLikelyDuplicate(candidate: candidate, existing: existing),
        isTrue,
      );
    });

    test('does not match unrelated records', () {
      const candidate = ImportCandidate(
        sourceId: '3',
        name: 'Maya Lewis',
        phone: '07999 111 222',
      );

      expect(
        isLikelyDuplicate(candidate: candidate, existing: existing),
        isFalse,
      );
    });
  });

  group('partial import reconciliation', () {
    test('removes completed items and leaves failures retryable', () {
      final result = reconcileImportAttempt(
        attempted: const {'calendar-1', 'calendar-2', 'calendar-3'},
        completed: const {'calendar-1', 'calendar-3'},
      );

      expect(result.completed, {'calendar-1', 'calendar-3'});
      expect(result.retryable, {'calendar-2'});
    });

    test('does not mark an item outside the attempt as completed', () {
      final result = reconcileImportAttempt(
        attempted: const {1, 2},
        completed: const {1, 99},
      );

      expect(result.completed, {1});
      expect(result.retryable, {2});
    });
  });

  group('calendar import idempotency', () {
    test('is stable for the same calendar event identity', () {
      final first = calendarImportIdempotencyKey(
        calendarId: 'calendar-1',
        eventId: 'event-42',
        startTime: DateTime.utc(2026, 8, 1, 9),
        title: 'Original title',
      );
      final edited = calendarImportIdempotencyKey(
        calendarId: 'calendar-1',
        eventId: 'event-42',
        startTime: DateTime.utc(2026, 8, 2, 11),
        title: 'Edited title',
      );

      expect(edited, first);
      expect(first, startsWith('calendar-import-v1-'));
      expect(first.length, inInclusiveRange(16, 128));
    });

    test('separates events and has a deterministic provider fallback', () {
      final firstEvent = calendarImportIdempotencyKey(
        calendarId: 'calendar-1',
        eventId: 'event-1',
        startTime: DateTime.utc(2026, 8, 1, 9),
      );
      final secondEvent = calendarImportIdempotencyKey(
        calendarId: 'calendar-1',
        eventId: 'event-2',
        startTime: DateTime.utc(2026, 8, 1, 9),
      );
      final fallback = calendarImportIdempotencyKey(
        calendarId: 'calendar-1',
        startTime: DateTime.utc(2026, 8, 1, 9),
        endTime: DateTime.utc(2026, 8, 1, 10),
        title: 'Consultation',
        location: 'Studio',
      );
      final sameFallback = calendarImportIdempotencyKey(
        calendarId: 'calendar-1',
        startTime: DateTime.utc(2026, 8, 1, 9),
        endTime: DateTime.utc(2026, 8, 1, 10),
        title: ' Consultation ',
        location: ' studio ',
      );

      expect(secondEvent, isNot(firstEvent));
      expect(sameFallback, fallback);
    });
  });

  group('task text import', () {
    test(
      'normalises list markers into independently retryable task titles',
      () {
        final titles = taskTitlesFromImportText(
          '- Confirm booking\n* Send invoice\n3. Follow up\n\n',
        );

        expect(titles, ['Confirm booking', 'Send invoice', 'Follow up']);
      },
    );

    test('keeps unbulleted lines and drops empty lines', () {
      expect(taskTitlesFromImportText('Call Maya\r\n\r\n  Email quote  '), [
        'Call Maya',
        'Email quote',
      ]);
    });
  });
}
