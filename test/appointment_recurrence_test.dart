import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/utils/appointment_recurrence.dart';

void main() {
  group('appointmentOccurrenceStart', () {
    test('weekly recurrence preserves local wall-clock fields', () {
      final start = DateTime(2026, 3, 23, 9, 30);
      final occurrence = appointmentOccurrenceStart(
        start,
        'FREQ=WEEKLY;INTERVAL=1',
        1,
      );

      expect(occurrence, DateTime(2026, 3, 30, 9, 30));
    });

    test('UTC input preserves local wall time across a DST transition', () {
      final start = DateTime.utc(2026, 3, 23, 9);
      final localStart = start.toLocal();
      final occurrence = appointmentOccurrenceStart(
        start,
        'FREQ=WEEKLY;INTERVAL=1',
        1,
      );

      expect(occurrence.isUtc, isTrue);
      expect(occurrence.toLocal().hour, localStart.hour);
      expect(occurrence.toLocal().minute, localStart.minute);

      final nextWeekOffset = DateTime(
        localStart.year,
        localStart.month,
        localStart.day + 7,
        localStart.hour,
      ).timeZoneOffset;
      if (nextWeekOffset != localStart.timeZoneOffset) {
        expect(occurrence.difference(start), isNot(const Duration(days: 7)));
      }
    });

    test('monthly recurrence clamps to each target month end', () {
      final start = DateTime(2027, 1, 31, 14, 15);

      expect(
        appointmentOccurrenceStart(start, 'FREQ=MONTHLY;INTERVAL=1', 1),
        DateTime(2027, 2, 28, 14, 15),
      );
      expect(
        appointmentOccurrenceStart(start, 'FREQ=MONTHLY;INTERVAL=1', 2),
        DateTime(2027, 3, 31, 14, 15),
      );
    });

    test('monthly interval and leap years are respected', () {
      final start = DateTime(2028, 1, 31, 8);

      expect(
        appointmentOccurrenceStart(start, 'FREQ=MONTHLY;INTERVAL=1', 1),
        DateTime(2028, 2, 29, 8),
      );
      expect(
        appointmentOccurrenceStart(start, 'FREQ=MONTHLY;INTERVAL=2', 1),
        DateTime(2028, 3, 31, 8),
      );
    });

    test('rejects unsupported and malformed recurrence rules', () {
      expect(
        () => appointmentOccurrenceStart(DateTime(2026, 1, 1), 'FREQ=DAILY', 1),
        throwsArgumentError,
      );
      expect(
        () => appointmentOccurrenceStart(
          DateTime(2026, 1, 1),
          'FREQ=WEEKLY;INTERVAL=0',
          1,
        ),
        throwsArgumentError,
      );
    });
  });
}
