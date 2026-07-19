import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/profile/profile_screen.dart';

void main() {
  group('Profile overview summaries', () {
    test('working hours count only enabled business days', () {
      expect(
        profileWorkingHoursSummary({
          'monday': {'enabled': true},
          'tuesday': {'enabled': true},
          'wednesday': {'enabled': false},
        }),
        '2 working days',
      );
      expect(profileWorkingHoursSummary({}), 'Working hours not set');
    });

    test('services and requests use calm singular and empty copy', () {
      expect(profileServicesSummary(0), 'No services added');
      expect(profileServicesSummary(1), '1 service available');
      expect(profileServicesSummary(4), '4 services available');
      expect(profileRequestSummary(0), 'No requests waiting');
      expect(profileRequestSummary(1), '1 request waiting');
      expect(profileRequestSummary(3), '3 requests waiting');
    });
  });
}
