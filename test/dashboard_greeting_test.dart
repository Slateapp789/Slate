import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/dashboard/dashboard_screen.dart';

void main() {
  group('dashboardGreetingForHour', () {
    test('uses morning before midday', () {
      expect(dashboardGreetingForHour(0), 'Good morning');
      expect(dashboardGreetingForHour(11), 'Good morning');
    });

    test('uses afternoon from midday until five', () {
      expect(dashboardGreetingForHour(12), 'Good afternoon');
      expect(dashboardGreetingForHour(16), 'Good afternoon');
    });

    test('uses evening from five onwards', () {
      expect(dashboardGreetingForHour(17), 'Good evening');
      expect(dashboardGreetingForHour(23), 'Good evening');
    });
  });

  test('dashboardDateLabel uses a calm full date', () {
    expect(dashboardDateLabel(DateTime(2026, 7, 15)), 'Wednesday, 15 July');
  });

  test('dashboard booking sections do not duplicate today', () {
    final now = DateTime(2026, 7, 15, 10);
    final rows = [
      {
        'id': 'today',
        'start_time': DateTime(2026, 7, 15, 12).toUtc().toIso8601String(),
        'status': 'scheduled',
      },
      {
        'id': 'tomorrow',
        'start_time': DateTime(2026, 7, 16, 9).toUtc().toIso8601String(),
        'status': 'scheduled',
      },
    ];

    final today = selectDashboardTodayBookings(rows, now: now);
    final comingUp = selectDashboardComingUpBookings(rows, now: now);

    expect(today.map((row) => row['id']), ['today']);
    expect(comingUp.map((row) => row['id']), ['tomorrow']);
  });

  test('dashboard coming up stays intentionally short', () {
    final now = DateTime(2026, 7, 15, 10);
    final rows = List.generate(5, (index) {
      return {
        'id': '$index',
        'start_time': DateTime(
          2026,
          7,
          16 + index,
          9,
        ).toUtc().toIso8601String(),
        'status': 'scheduled',
      };
    });

    expect(selectDashboardComingUpBookings(rows, now: now), hasLength(3));
  });

  test('setup progress reflects the real first-value records', () {
    expect(
      dashboardSetupCompletedCount(
        hasClient: true,
        hasBooking: false,
        hasPayment: true,
      ),
      2,
    );
    expect(
      dashboardSetupCompletedCount(
        hasClient: true,
        hasBooking: true,
        hasPayment: true,
      ),
      3,
    );
  });
}
