import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/appointments/appointments_screen.dart';

void main() {
  test('selectNextBooking returns the soonest active booking from now', () {
    final now = DateTime.utc(2026, 6, 4, 9);
    final bookings = [
      {
        'id': 'later',
        'start_time': '2026-06-04T12:00:00Z',
        'status': 'scheduled',
      },
      {
        'id': 'cancelled-first',
        'start_time': '2026-06-04T08:30:00Z',
        'status': 'cancelled',
      },
      {
        'id': 'first-at-nine',
        'start_time': '2026-06-04T09:00:00Z',
        'status': 'scheduled',
      },
      {
        'id': 'second-at-nine',
        'start_time': '2026-06-04T09:00:00Z',
        'status': 'scheduled',
      },
    ];

    final next = selectNextBooking(bookings, now: now);

    expect(next?['id'], 'first-at-nine');
  });
}
