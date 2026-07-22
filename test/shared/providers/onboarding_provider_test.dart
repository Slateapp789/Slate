import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/providers/onboarding_provider.dart';

void main() {
  test('onboarding draft round-trips setup data and progress', () {
    const draft = OnboardingState(
      firstName: 'Ash',
      businessName: 'Ash Services',
      industry: 'Cleaning & Home Services',
      handle: 'ash-services',
      services: [
        {'name': 'Standard clean', 'duration': 90, 'price': 55.0},
      ],
      workingHours: {
        'Mon': {'enabled': true, 'open': '09:00', 'close': '17:00'},
      },
      revenueTarget: 3000,
      firstBooking: {
        'clientName': 'Maya Lewis',
        'serviceName': 'Standard clean',
        'date': '2026-07-20',
        'hour': 9,
        'minute': 30,
      },
      importAfterSetup: true,
      notificationPreferences: {
        'all_notifications': true,
        'new_booking': false,
        'payment_received': true,
      },
      currentStep: 6,
    );

    final restored = OnboardingState.fromJson(draft.toJson());

    expect(restored.firstName, draft.firstName);
    expect(restored.services, draft.services);
    expect(restored.workingHours, draft.workingHours);
    expect(restored.firstBooking, draft.firstBooking);
    expect(restored.importAfterSetup, isTrue);
    expect(restored.notificationPreferences, draft.notificationPreferences);
    expect(restored.currentStep, 6);
  });
}
