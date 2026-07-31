import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/imports/calendar_import_screen.dart';
import 'package:workloop/shared/repositories/appointments_repository.dart';

void main() {
  test(
    'validated import runs schedule validation before atomic creation',
    () async {
      final calls = <String>[];

      await executeCalendarImportBooking(
        validateSchedule: () async => calls.add('validate'),
        createBookingWorkflow: () async => calls.add('create-workflow'),
      );

      expect(calls, ['validate', 'create-workflow']);
    },
  );

  test(
    'preflight conflict still reaches idempotent workflow arbitration',
    () async {
      var workflowCalled = false;

      await executeCalendarImportBooking(
        validateSchedule: () async => throw const AppointmentScheduleException(
          'This overlaps an existing booking.',
          issue: AppointmentScheduleIssue.conflict,
        ),
        createBookingWorkflow: () async => workflowCalled = true,
      );

      expect(workflowCalled, isTrue);
    },
  );

  test('outside-hours validation blocks atomic creation', () async {
    var workflowCalled = false;

    await expectLater(
      executeCalendarImportBooking(
        validateSchedule: () async => throw const AppointmentScheduleException(
          'Monday is outside your working hours.',
          issue: AppointmentScheduleIssue.workingHours,
        ),
        createBookingWorkflow: () async => workflowCalled = true,
      ),
      throwsA(
        isA<AppointmentScheduleException>().having(
          (error) => error.issue,
          'issue',
          AppointmentScheduleIssue.workingHours,
        ),
      ),
    );
    expect(workflowCalled, isFalse);
  });

  test('calendar conflicts retain an actionable retry message', () {
    const error = AppointmentScheduleException(
      'This overlaps an existing booking.',
      issue: AppointmentScheduleIssue.conflict,
    );

    final message = calendarImportFailureMessage(error);

    expect(message, contains('overlaps an existing booking'));
    expect(message, contains('change the source event time'));
  });

  test('outside-hours imports explain the intentional fallback', () {
    const error = AppointmentScheduleException(
      'Monday is outside your working hours.',
      issue: AppointmentScheduleIssue.workingHours,
    );

    final message = calendarImportFailureMessage(error);

    expect(message, contains('outside your working hours'));
    expect(message, contains('Create it manually'));
  });

  test('unknown failures keep a safe retry action', () {
    final message = calendarImportFailureMessage(Exception('secret detail'));

    expect(message, contains('Check your connection'));
    expect(message, isNot(contains('secret detail')));
  });
}
