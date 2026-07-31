import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/public_profile/booking_requests_screen.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';

SupabaseClient _testClient() {
  return SupabaseClient(
    'https://example.supabase.co',
    'test-anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

class _RetryingConfirmationRepository extends ProfileRepository {
  _RetryingConfirmationRepository() : super(_testClient());

  int attempts = 0;
  final submittedNames = <String?>[];

  @override
  Future<void> confirmBookingRequest({
    required BookingRequest request,
    required DateTime startTime,
    required int durationMins,
    required double price,
    String? clientName,
    String? clientPhone,
    String? serviceTitle,
    String? location,
    String? extraNotes,
    bool createPaymentDue = false,
    bool enforceWorkingHours = true,
  }) async {
    attempts += 1;
    submittedNames.add(clientName);
    if (attempts == 1) throw StateError('offline');
  }
}

void main() {
  const request = BookingRequest(
    id: 'request-1',
    workspaceId: 'workspace-1',
    name: 'Alex Smith',
    phone: '07123 456789',
    serviceName: 'Window clean',
    serviceDurationMins: 60,
    servicePrice: 45,
  );

  testWidgets('failed booking conversion keeps the draft and can retry', (
    tester,
  ) async {
    final repository = _RetryingConfirmationRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const BookingRequestDetailScreen(request: request),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Book'));
    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Client name'),
      'Alex Smith Updated',
    );

    await tester.ensureVisible(find.text('Create booking').last);
    await tester.tap(find.text('Create booking').last);
    await tester.pumpAndSettle();

    expect(repository.attempts, 1);
    expect(
      find.text(
        'The booking was not created. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Alex Smith Updated'), findsOneWidget);

    await tester.ensureVisible(find.text('Create booking').last);
    await tester.tap(find.text('Create booking').last);
    await tester.pumpAndSettle();

    expect(repository.attempts, 2);
    expect(repository.submittedNames, [
      'Alex Smith Updated',
      'Alex Smith Updated',
    ]);
    expect(find.text('Confirm booking'), findsNothing);
  });

  testWidgets('conversion fields stack safely on a small phone at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            _RetryingConfirmationRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
              viewPadding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: BookingRequestDetailScreen(request: request),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Book'));
    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Duration mins'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
  });
}
