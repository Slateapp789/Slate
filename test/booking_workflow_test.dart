import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/public_profile/booking_requests_screen.dart';
import 'package:workloop/shared/repositories/appointments_repository.dart';
import 'package:workloop/shared/repositories/profile_repository.dart';
import 'package:workloop/shared/utils/workflow_idempotency.dart';

void main() {
  test('booking workflow payload carries every recurrence as UTC', () {
    final payload = buildBookingWorkflowPayload(
      workspaceId: 'workspace-1',
      idempotencyKey: 'workflow-key-1234567890',
      contactId: 'contact-1',
      serviceId: 'service-1',
      startTime: DateTime(2027, 1, 31, 9).toUtc(),
      endTime: DateTime(2027, 1, 31, 10).toUtc(),
      price: 80,
      title: 'Consultation',
      recurrenceRule: 'FREQ=MONTHLY;INTERVAL=1',
      repeatOccurrences: 3,
      taskTitles: const ['Prepare notes'],
      taskDueDate: DateTime(2027, 1, 31),
      createPaymentDue: true,
      notificationTitle: 'Repeating booking created',
      notificationBody: 'Created 3 bookings.',
    );

    final appointments = List<Map<String, dynamic>>.from(
      payload['appointments'] as List,
    );
    expect(appointments, hasLength(3));
    expect(
      DateTime.parse(appointments[1]['start_time'] as String).toLocal().day,
      28,
    );
    expect(
      DateTime.parse(appointments[2]['start_time'] as String).toLocal().day,
      31,
    );
    expect(payload['contact_id'], 'contact-1');
    expect(payload['create_payment_due'], isTrue);
  });

  test('new request client context is carried into the atomic workflow', () {
    final payload = buildBookingWorkflowPayload(
      workspaceId: 'workspace-1',
      idempotencyKey: 'booking-request-confirm:1234567890',
      newContactName: 'Ada Lovelace',
      newContactPhone: '07123456789',
      newContactNotes: 'Created from public booking request.',
      reuseContactByPhone: true,
      bookingRequestId: 'request-1',
      startTime: DateTime.utc(2027, 2, 1, 9),
      endTime: DateTime.utc(2027, 2, 1, 10),
      price: 80,
      notificationTitle: 'Booking request confirmed',
      notificationBody: 'Ada has been added to your calendar.',
    );

    expect(
      (payload['new_contact'] as Map)['notes'],
      'Created from public booking request.',
    );
    expect(payload['booking_request_id'], 'request-1');
    expect(payload['reuse_contact_by_phone'], isTrue);
  });

  test('completion payload keeps one retry key and linked payment', () {
    final payload = buildCompletionWorkflowPayload(
      workspaceId: 'workspace-1',
      appointmentId: 'appointment-1',
      idempotencyKey: 'completion-key-123456',
      paymentMode: 'linked_paid',
      linkedPaymentId: 'payment-1',
      paymentDate: DateTime(2026, 7, 25),
    );

    expect(payload['idempotency_key'], 'completion-key-123456');
    expect(payload['linked_payment_id'], 'payment-1');
    expect(payload['payment_date'], '2026-07-25');
  });

  test('generated workflow keys have sufficient independent entropy', () {
    final first = createWorkflowIdempotencyKey();
    final second = createWorkflowIdempotencyKey();

    expect(first, isNot(second));
    expect(first.length, inInclusiveRange(40, 128));
    expect(second.length, inInclusiveRange(40, 128));
  });

  test('public request tokens are stable-format UUID v4 values', () {
    final first = createPublicRequestToken();
    final second = createPublicRequestToken();
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
      r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(first, isNot(second));
    expect(uuidV4.hasMatch(first), isTrue);
    expect(uuidV4.hasMatch(second), isTrue);
  });

  test('booking request price input preserves meaningful decimals', () {
    expect(bookingRequestEditablePrice(49.99), '49.99');
    expect(bookingRequestEditablePrice(49.90), '49.9');
    expect(bookingRequestEditablePrice(50), '50');
  });

  test('direct request transitions cannot overwrite terminal states', () {
    expect(bookingRequestSourceStatusesFor('contacted'), const [
      'pending',
      'contacted',
    ]);
    expect(bookingRequestSourceStatusesFor('declined'), const [
      'pending',
      'contacted',
    ]);
    expect(
      () => bookingRequestSourceStatusesFor('confirmed'),
      throwsArgumentError,
    );
  });

  test('booking request confirmation retries reuse one stable key', () {
    expect(
      bookingRequestConfirmationIdempotencyKey('request-1'),
      'booking-request-confirm:request-1',
    );
    expect(
      bookingRequestConfirmationIdempotencyKey('request-1'),
      bookingRequestConfirmationIdempotencyKey('request-1'),
    );
    expect(
      bookingRequestConfirmationIdempotencyKey('request-1'),
      isNot(bookingRequestConfirmationIdempotencyKey('request-2')),
    );
  });

  test('booking workflow database conflicts map to schedule feedback', () {
    expect(
      isAppointmentConflictError(
        code: '23P01',
        message: 'exclusion constraint violation',
      ),
      isTrue,
    );
    expect(
      isAppointmentConflictError(
        code: 'P0001',
        message: 'Appointment overlaps an existing booking',
      ),
      isTrue,
    );
    expect(
      isAppointmentConflictError(code: '42501', message: 'Access denied'),
      isFalse,
    );
  });

  test(
    'stale booking request RPC errors map without hiding other failures',
    () {
      expect(
        isBookingRequestStateError(
          code: '23505',
          message: 'Booking request can no longer be confirmed',
        ),
        isTrue,
      );
      expect(
        isBookingRequestStateError(
          code: 'P0002',
          message: 'Booking request was not found',
        ),
        isTrue,
      );
      expect(
        isBookingRequestStateError(
          code: '23505',
          message: 'unrelated unique constraint',
        ),
        isFalse,
      );
    },
  );

  test('workflow migration keeps privileged logic private', () {
    final migration = File(
      'supabase/migrations/'
      '20260726000118_transactional_booking_workflows.sql',
    ).readAsStringSync();

    expect(migration, contains('app_private.create_booking_workflow'));
    expect(migration, contains('app_private.complete_booking_workflow'));
    expect(migration, contains('security invoker'));
    expect(migration, contains('Workspace access denied'));
    expect(migration, contains('pg_advisory_xact_lock'));
    expect(migration, contains('from public, anon'));
    expect(migration, isNot(contains('to anon')));
  });
}
