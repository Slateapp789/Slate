import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/utils/working_hours.dart';

void main() {
  final standardHours = <String, dynamic>{
    'Monday': {
      'enabled': true,
      'blocks': [
        {'start': '09:00', 'end': '17:00'},
      ],
    },
  };

  test('accepts a same-day booking fully inside a valid block', () {
    expect(
      isWithinWorkingHours(
        hours: standardHours,
        start: DateTime(2026, 7, 27, 9),
        end: DateTime(2026, 7, 27, 17),
      ),
      isTrue,
    );
  });

  test('rejects cross-midnight bookings', () {
    expect(
      isWithinWorkingHours(
        hours: standardHours,
        start: DateTime(2026, 7, 27, 23),
        end: DateTime(2026, 7, 28, 1),
      ),
      isFalse,
    );
  });

  test('rejects zero, negative, and boundary-overrun durations', () {
    expect(
      isWithinWorkingHours(
        hours: standardHours,
        start: DateTime(2026, 7, 27, 10),
        end: DateTime(2026, 7, 27, 10),
      ),
      isFalse,
    );
    expect(
      isWithinWorkingHours(
        hours: standardHours,
        start: DateTime(2026, 7, 27, 11),
        end: DateTime(2026, 7, 27, 10),
      ),
      isFalse,
    );
    expect(
      isWithinWorkingHours(
        hours: standardHours,
        start: DateTime(2026, 7, 27, 16, 30),
        end: DateTime(2026, 7, 27, 17, 0, 1),
      ),
      isFalse,
    );
  });

  test('rejects malformed, out-of-range, and overnight blocks', () {
    for (final block in [
      {'start': 'nine', 'end': '17:00'},
      {'start': '09:70', 'end': '17:00'},
      {'start': '25:00', 'end': '17:00'},
      {'start': 900, 'end': '17:00'},
      {'end': '17:00'},
      {'start': '17:00', 'end': '09:00'},
      {'start': '09:00', 'end': '09:00'},
    ]) {
      expect(
        isWithinWorkingHours(
          hours: {
            'Monday': {
              'enabled': true,
              'blocks': [block],
            },
          },
          start: DateTime(2026, 7, 27, 10),
          end: DateTime(2026, 7, 27, 11),
        ),
        isFalse,
      );
    }
  });
}
