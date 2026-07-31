import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/appointments/appointments_screen.dart';
import 'package:workloop/features/notes/note_logic.dart';
import 'package:workloop/features/tasks/task_filters.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/utils/appointment_recurrence.dart';
import 'package:workloop/shared/utils/working_hours.dart';

void main() {
  group('core audit booking and recurrence rules', () {
    test(
      'next booking excludes terminal states and includes a start at now',
      () {
        final now = DateTime.utc(2026, 7, 26, 10);
        final next = selectNextBooking([
          {
            'id': 'no-show',
            'start_time': now.toIso8601String(),
            'status': 'no_show',
          },
          {
            'id': 'completed',
            'start_time': now.toIso8601String(),
            'status': 'completed',
          },
          {
            'id': 'scheduled',
            'start_time': now.toIso8601String(),
            'status': 'scheduled',
          },
        ], now: now);

        expect(next?['id'], 'scheduled');
        expect(isUpcomingBookingStatus('CANCELLED'), isFalse);
        expect(isUpcomingBookingStatus('pending'), isTrue);
      },
    );

    test('booking day boundaries remain local midnights across DST', () {
      final day = DateTime(2026, 10, 25);
      final nextDay = nextBookingCalendarDay(day);

      expect(nextDay, DateTime(2026, 10, 26));
      expect(nextDay.hour, 0);
      if (day.timeZoneOffset != nextDay.timeZoneOffset) {
        expect(nextDay.difference(day), isNot(const Duration(days: 1)));
      }
    });

    test('malformed recurrence rules fail even for the first occurrence', () {
      for (final rule in [
        'FREQ=DAILY;INTERVAL=1',
        'FREQ=WEEKLY;INTERVAL=abc',
        'INTERVAL=1',
      ]) {
        expect(
          () => appointmentOccurrenceStart(DateTime(2026, 7, 26, 9), rule, 0),
          throwsArgumentError,
          reason: rule,
        );
      }
    });
  });

  group('core audit working-hours parsing', () {
    test('malformed JSON values are closed rather than crashing', () {
      expect(
        workingHourBlocks({
          'enabled': 'true',
          'start': '09:00',
          'end': '17:00',
        }),
        isEmpty,
      );
      expect(
        isWithinWorkingHours(
          hours: {
            'Monday': {'enabled': true, 'start': 900, 'end': '17:00'},
          },
          start: DateTime(2026, 7, 27, 10),
          end: DateTime(2026, 7, 27, 11),
        ),
        isFalse,
      );
    });

    test('a booking cannot bridge a break between valid blocks', () {
      final hours = {
        'Mon': {
          'enabled': true,
          'blocks': [
            {'start': '09:00', 'end': '12:00'},
            {'start': '13:00', 'end': '17:00'},
          ],
        },
      };

      expect(
        isWithinWorkingHours(
          hours: hours,
          start: DateTime(2026, 7, 27, 11, 30),
          end: DateTime(2026, 7, 27, 13, 30),
        ),
        isFalse,
      );
    });
  });

  group('core audit task and note logic', () {
    final now = DateTime(2026, 7, 26, 15);

    test('task buckets are deterministic at business-day boundaries', () {
      expect(
        taskDateBucketFor(_task('overdue', DateTime(2026, 7, 25)), now: now),
        TaskDateBucket.overdue,
      );
      expect(
        taskDateBucketFor(_task('today', DateTime(2026, 7, 26)), now: now),
        TaskDateBucket.today,
      );
      expect(
        taskDateBucketFor(_task('future', DateTime(2026, 8, 2)), now: now),
        TaskDateBucket.upcoming,
      );
      expect(
        taskIsWithinNextSevenDays(
          _task('seven-days', DateTime(2026, 8, 2)),
          now: now,
        ),
        isTrue,
      );
      expect(
        taskIsWithinNextSevenDays(
          _task('eight-days', DateTime(2026, 8, 3)),
          now: now,
        ),
        isFalse,
      );
    });

    test('task sorting is stable after due date and priority ties', () {
      final tasks = [
        _task('Zulu', null, priority: 'medium'),
        _task('done', DateTime(2026, 7, 20), status: 'done'),
        _task('Alpha', null, priority: 'medium'),
        _task('Urgent', null, priority: 'high'),
      ]..sort(compareTasksForDisplay);

      expect(tasks.map((task) => task.id), ['Urgent', 'Alpha', 'Zulu', 'done']);
    });

    test('note draft parsing handles leading blanks and legacy newlines', () {
      final draft = parseNoteDraft(
        '\r\rClient context\rCalled about next booking\rSend quote\r',
      );

      expect(draft.title, 'Client context');
      expect(draft.body, 'Called about next booking\nSend quote');
      expect(parseNoteDraft(' \n\t ').isEmpty, isTrue);
    });
  });

  group('core audit scheduled public notice', () {
    final start = DateTime.utc(2026, 7, 26, 9);
    final end = DateTime.utc(2026, 7, 26, 17);
    final profile = BusinessProfile(
      id: 'profile-1',
      workspaceId: 'workspace-1',
      handle: 'studio',
      noticeText: 'Closed for maintenance',
      noticeStart: start,
      noticeEnd: end,
    );

    test('start and end instants are inclusive', () {
      expect(profile.isNoticeActive(now: start), isTrue);
      expect(profile.isNoticeActive(now: end), isTrue);
    });

    test('notice is hidden outside its window or without useful copy', () {
      expect(
        profile.isNoticeActive(
          now: start.subtract(const Duration(microseconds: 1)),
        ),
        isFalse,
      );
      expect(
        profile.isNoticeActive(now: end.add(const Duration(microseconds: 1))),
        isFalse,
      );
      expect(
        const BusinessProfile(
          id: 'blank',
          workspaceId: 'workspace-1',
          handle: 'blank',
          noticeText: '   ',
        ).isNoticeActive(now: start),
        isFalse,
      );
    });
  });
}

SlateTask _task(
  String id,
  DateTime? dueDate, {
  String status = 'open',
  String priority = 'medium',
}) {
  return SlateTask(
    id: id,
    workspaceId: 'workspace-1',
    title: id,
    status: status,
    priority: priority,
    dueDate: dueDate,
  );
}
