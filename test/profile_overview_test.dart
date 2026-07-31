import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:workloop/features/profile/profile_screen.dart';
import 'package:workloop/features/public_profile/public_profile_screen.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';

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

  testWidgets('owner preview renders loaded profile and can return', (
    tester,
  ) async {
    const preview = PublicProfile(
      profile: BusinessProfile(
        id: 'profile-1',
        workspaceId: 'workspace-1',
        handle: 'clearview',
        bio: 'Calm, reliable window cleaning.',
      ),
      businessName: 'Clearview Window Care',
      industry: 'Window cleaning',
      workingHours: {},
      services: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const PublicProfileScreen(
                    handle: 'clearview',
                    previewProfile: preview,
                  ),
                ),
              ),
              child: const Text('Preview'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    final businessName = find.text(
      'Clearview Window Care',
      skipOffstage: false,
    );
    expect(businessName, findsOneWidget);
    expect(
      find.text('Calm, reliable window cleaning.', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.getTopLeft(businessName).dy, greaterThanOrEqualTo(0));
    expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
  });
}
