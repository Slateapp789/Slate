import 'package:flutter_test/flutter_test.dart';
import 'package:slate/shared/utils/date_format.dart';

void main() {
  test('slate date labels are relative then explicit', () {
    final now = DateTime(2026, 6, 4);

    expect(slateShortDate(DateTime(2026, 6, 4), now: now), 'Today');
    expect(slateShortDate(DateTime(2026, 6, 5), now: now), 'Tomorrow');
    expect(slateShortDate(DateTime(2026, 6, 8), now: now), 'Mon 8 Jun');
  });

  test('slateTimeRange formats inline ranges', () {
    expect(
      slateTimeRange(DateTime(2026, 6, 4, 9), DateTime(2026, 6, 4, 9, 45)),
      '09:00-09:45',
    );
  });
}
