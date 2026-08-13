import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/shared/repositories/appointments_repository.dart';
import 'package:workloop/shared/repositories/payments_repository.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';

import 'staging_test_config.dart';

const _ownerEmail = String.fromEnvironment('E2E_USER_A_EMAIL');
const _ownerPassword = String.fromEnvironment('E2E_USER_A_PASSWORD');
const _publicHandle = String.fromEnvironment('E2E_PUBLIC_HANDLE');
const _requesterEmail = String.fromEnvironment('E2E_REQUESTER_EMAIL');

final _configured =
    stagingWritesAllowed &&
    stagingUrl.isNotEmpty &&
    stagingAnonKey.isNotEmpty &&
    _ownerEmail.isNotEmpty &&
    _ownerPassword.isNotEmpty &&
    _publicHandle.isNotEmpty &&
    _requesterEmail.isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  requireSafeStagingWriteTarget();

  testWidgets(
    'public request is idempotent, owner-visible, and converts atomically',
    (tester) async {
      final publicClient = _client();
      final ownerClient = _client();
      final publicProfiles = ProfileRepository(publicClient);
      final ownerProfiles = ProfileRepository(ownerClient);
      final runId = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
      final requesterName = 'E2E Request $runId';
      final phone = '+44 7700 ${runId.substring(runId.length - 6)}';
      final requestToken = _uuidFor(runId);
      final bookingTitle = 'E2E Public Booking $runId';

      String? workspaceId;
      String? requestId;
      String? appointmentId;
      String? contactId;
      String? paymentId;

      try {
        final publicProfile = await publicProfiles.getPublicProfile(
          _publicHandle,
        );
        expect(
          publicProfile,
          isNotNull,
          reason: 'E2E_PUBLIC_HANDLE must be published in staging.',
        );
        final service = publicProfile!.services.firstOrNull;

        final honeypot = await publicClient.functions.invoke(
          'create-booking-request',
          body: {
            'handle': _publicHandle,
            'name': 'Bot $runId',
            'phone': phone,
            'requestToken': _uuidFor('bot$runId'),
            'website': 'https://spam.invalid',
          },
        );
        expect(honeypot.status, 202);

        await publicProfiles.createBookingRequest(
          handle: _publicHandle,
          name: requesterName,
          phone: phone,
          email: _requesterEmail,
          requestToken: requestToken,
          serviceId: service?.id,
          preferredTimeText: 'A weekday morning',
          message: 'Created by the disposable staging E2E journey.',
        );
        final duplicate = await publicClient.functions.invoke(
          'create-booking-request',
          body: {
            'handle': _publicHandle,
            'name': requesterName,
            'phone': phone,
            'email': _requesterEmail,
            'requestToken': requestToken,
            'serviceId': service?.id,
            'preferredTimeText': 'A weekday morning',
            'message': 'Created by the disposable staging E2E journey.',
          },
        );
        expect(duplicate.status, 200);
        expect(
          Map<String, dynamic>.from(duplicate.data as Map)['duplicate'],
          isTrue,
        );

        await expectLater(
          () => publicClient.functions.invoke(
            'create-booking-request',
            body: {
              'handle': _publicHandle,
              'name': 'Invalid service $runId',
              'phone': '+44 7700 800000',
              'email': 'invalid-service-$runId@example.com',
              'requestToken': _uuidFor('${runId}invalid'),
              'serviceId': '00000000-0000-4000-8000-000000000000',
            },
          ),
          throwsA(
            isA<FunctionException>().having(
              (error) => error.status,
              'status',
              400,
            ),
          ),
        );

        final ownerAuth = await ownerClient.auth.signInWithPassword(
          email: _ownerEmail,
          password: _ownerPassword,
        );
        expect(ownerAuth.user, isNotNull);
        workspaceId = await _workspaceId(ownerClient, ownerAuth.user!.id);

        var requests = await ownerProfiles.bookingRequests(workspaceId);
        final matching = requests
            .where((item) => item.name == requesterName && item.phone == phone)
            .toList();
        expect(matching, hasLength(1));
        final request = matching.single;
        requestId = request.id;
        expect(request.status, 'pending');
        expect(requests.any((item) => item.name == 'Bot $runId'), isFalse);

        final start = DateTime.now().toUtc().add(const Duration(days: 60));
        final bookingStart = DateTime.utc(
          start.year,
          start.month,
          start.day,
          10,
        );
        final confirmation = await ownerProfiles.confirmBookingRequest(
          request: request,
          startTime: bookingStart,
          durationMins: service?.durationMins ?? 60,
          price: service?.price ?? 85,
          serviceTitle: bookingTitle,
          createPaymentDue: true,
          enforceWorkingHours: false,
        );
        expect(
          confirmation.confirmationEmailStatus,
          BookingRequestConfirmationEmailStatus.sent,
          reason: 'The controlled staging recipient must be provider-accepted.',
        );

        requests = await ownerProfiles.bookingRequests(workspaceId);
        expect(
          requests.singleWhere((item) => item.id == requestId).status,
          'confirmed',
        );

        final appointment = (await AppointmentsRepository(
          ownerClient,
        ).list(workspaceId)).singleWhere((item) => item.title == bookingTitle);
        appointmentId = appointment.id;
        contactId = appointment.contactId;
        expect(appointment.status, 'scheduled');

        final payments = await PaymentsRepository(
          ownerClient,
        ).forAppointment(appointmentId);
        expect(payments, hasLength(1));
        paymentId = payments.single.id;
        expect(payments.single.outstandingAmount, greaterThan(0));
      } finally {
        if (paymentId != null) {
          await _ignoreCleanup(
            () => PaymentsRepository(ownerClient).delete(paymentId!),
          );
        }
        if (appointmentId != null) {
          await _ignoreCleanup(
            () => ownerClient
                .from('appointments')
                .delete()
                .eq('id', appointmentId!),
          );
        }
        if (contactId != null) {
          await _ignoreCleanup(
            () => ownerClient.from('contacts').delete().eq('id', contactId!),
          );
        }
        if (requestId != null) {
          await _ignoreCleanup(
            () => ownerClient
                .from('booking_requests')
                .delete()
                .eq('id', requestId!),
          );
        }
        if (workspaceId != null) {
          await _ignoreCleanup(
            () => ownerClient
                .from('notifications')
                .delete()
                .eq('workspace_id', workspaceId!)
                .ilike('body', '%$requesterName%'),
          );
        }
        await _ignoreCleanup(ownerClient.auth.signOut);
        publicClient.dispose();
        ownerClient.dispose();
      }
    },
    skip: !_configured,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

SupabaseClient _client() => SupabaseClient(
  stagingUrl,
  stagingAnonKey,
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

String _uuidFor(String seed) {
  final hex = seed.codeUnits
      .fold<BigInt>(
        BigInt.zero,
        (value, unit) => (value << 5) ^ BigInt.from(unit),
      )
      .toRadixString(16)
      .padLeft(32, '0');
  final tail = hex.substring(hex.length - 12);
  return '00000000-0000-4000-8000-$tail';
}

Future<String> _workspaceId(SupabaseClient client, String userId) async {
  final membership = await client
      .from('workspace_members')
      .select('workspace_id')
      .eq('user_id', userId)
      .limit(1)
      .maybeSingle();
  expect(membership, isNotNull, reason: 'The E2E owner needs a workspace.');
  return membership!['workspace_id'] as String;
}

Future<void> _ignoreCleanup(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    // Cleanup is best effort so the workflow failure stays visible.
  }
}
