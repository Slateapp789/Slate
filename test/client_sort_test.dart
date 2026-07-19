import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/clients/client_sort.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/providers/clients_provider.dart';

void main() {
  test('client sorting supports alphabetical and next booking order', () {
    final records = [
      _record(name: 'Zara Lane', nextBooking: DateTime(2026, 7, 20)),
      _record(name: 'Alice Stone', nextBooking: DateTime(2026, 7, 18)),
      _record(name: 'No Booking'),
    ];

    expect(
      sortClientRecords(
        records,
        ClientSortOrder.alphabetical,
      ).map((item) => item.client.name),
      ['Alice Stone', 'No Booking', 'Zara Lane'],
    );
    expect(
      sortClientRecords(
        records,
        ClientSortOrder.nextBooking,
      ).map((item) => item.client.name),
      ['Alice Stone', 'Zara Lane', 'No Booking'],
    );
  });

  test('recently booked and recently added keep missing dates last', () {
    final records = [
      _record(
        name: 'Older Work',
        lastBooking: DateTime(2026, 6, 10),
        createdAt: DateTime(2026, 5, 1),
      ),
      _record(
        name: 'Newer Work',
        lastBooking: DateTime(2026, 7, 10),
        createdAt: DateTime(2026, 7, 1),
      ),
      _record(name: 'No Dates'),
    ];

    expect(
      sortClientRecords(
        records,
        ClientSortOrder.recentlyBooked,
      ).map((item) => item.client.name),
      ['Newer Work', 'Older Work', 'No Dates'],
    );
    expect(
      sortClientRecords(
        records,
        ClientSortOrder.recentlyAdded,
      ).map((item) => item.client.name),
      ['Newer Work', 'Older Work', 'No Dates'],
    );
  });

  test('most booked uses client name as a stable tie breaker', () {
    final records = [
      _record(name: 'Zed', bookingCount: 2),
      _record(name: 'Amy', bookingCount: 5),
      _record(name: 'Ben', bookingCount: 5),
    ];

    expect(
      sortClientRecords(
        records,
        ClientSortOrder.mostBooked,
      ).map((item) => item.client.name),
      ['Amy', 'Ben', 'Zed'],
    );
  });
}

ClientCrmRecord _record({
  required String name,
  DateTime? nextBooking,
  DateTime? lastBooking,
  DateTime? createdAt,
  int bookingCount = 0,
}) {
  Appointment? appointment(DateTime? date, String suffix) {
    if (date == null) return null;
    return Appointment(
      id: '$name-$suffix',
      workspaceId: 'workspace-1',
      startTime: date,
      status: suffix == 'last' ? 'completed' : 'scheduled',
    );
  }

  return ClientCrmRecord(
    client: Client(
      id: name,
      workspaceId: 'workspace-1',
      name: name,
      createdAt: createdAt,
    ),
    bookingCount: bookingCount,
    completedBookingCount: 0,
    nextBooking: appointment(nextBooking, 'next'),
    lastBooking: appointment(lastBooking, 'last'),
    lifetimeValue: 0,
    outstandingBalance: 0,
    openTaskCount: 0,
    overdueTaskCount: 0,
  );
}
