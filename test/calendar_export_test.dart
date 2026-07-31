import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/utils/calendar_export.dart';

void main() {
  test('exports valid, deterministic Workloop calendar data', () {
    final ics = buildWorkloopIcs([
      {
        'id': 'booking-1',
        'title': 'Cut, colour & finish',
        'start_time': '2026-07-25T09:30:00Z',
        'end_time': '2026-07-25T10:45:00Z',
        'notes': 'Bring reference\nphoto',
        'contacts': {'name': 'Alex'},
        'services': {'name': 'Colour'},
      },
    ], generatedAt: DateTime.utc(2026, 7, 25, 8));

    expect(ics, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0'));
    expect(ics, contains('PRODID:-//Workloop//Appointments//EN'));
    expect(ics, contains('DTSTAMP:20260725T080000Z'));
    expect(ics, contains('DTSTART:20260725T093000Z'));
    expect(ics, contains('DTEND:20260725T104500Z'));
    expect(ics, contains(r'SUMMARY:Cut\, colour & finish'));
    expect(
      ics,
      contains(
        r'DESCRIPTION:Client: Alex\nService: Colour\nBring reference\nphoto',
      ),
    );
    expect(ics, endsWith('END:VCALENDAR'));
  });

  test('skips rows without a valid start time', () {
    final ics = buildWorkloopIcs([
      {'id': 'missing-start'},
      {'id': 'invalid-start', 'start_time': 'not-a-date'},
    ], generatedAt: DateTime.utc(2026));

    expect(ics, isNot(contains('BEGIN:VEVENT')));
  });
}
