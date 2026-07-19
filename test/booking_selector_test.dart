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

  test('selectNextBooking ignores past and cancelled bookings', () {
    final now = DateTime.utc(2026, 7, 19, 10);
    final bookings = [
      {
        'id': 'past',
        'start_time': '2026-07-19T09:30:00Z',
        'status': 'scheduled',
      },
      {
        'id': 'cancelled',
        'start_time': '2026-07-19T10:30:00Z',
        'status': 'cancelled',
      },
    ];

    expect(selectNextBooking(bookings, now: now), isNull);
  });

  test('selectNextBooking treats a booking starting now as upcoming', () {
    final now = DateTime.utc(2026, 7, 19, 10);
    final booking = {
      'id': 'now',
      'start_time': '2026-07-19T10:00:00Z',
      'status': 'scheduled',
    };

    expect(selectNextBooking([booking], now: now)?['id'], 'now');
  });
}
