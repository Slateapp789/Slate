import '../../shared/providers/clients_provider.dart';

enum ClientSortOrder {
  nextBooking,
  alphabetical,
  recentlyBooked,
  recentlyAdded,
  mostBooked,
}

extension ClientSortOrderLabel on ClientSortOrder {
  String get label => switch (this) {
    ClientSortOrder.nextBooking => 'Next booking',
    ClientSortOrder.alphabetical => 'A–Z',
    ClientSortOrder.recentlyBooked => 'Recently booked',
    ClientSortOrder.recentlyAdded => 'Recently added',
    ClientSortOrder.mostBooked => 'Most booked',
  };
}

List<ClientCrmRecord> sortClientRecords(
  Iterable<ClientCrmRecord> records,
  ClientSortOrder order,
) {
  final sorted = records.toList();
  sorted.sort((a, b) {
    final comparison = switch (order) {
      ClientSortOrder.nextBooking => _compareNullableDates(
        a.nextBooking?.startTime,
        b.nextBooking?.startTime,
      ),
      ClientSortOrder.alphabetical => _compareNames(a, b),
      ClientSortOrder.recentlyBooked => _compareNullableDatesDescending(
        a.lastBooking?.startTime,
        b.lastBooking?.startTime,
      ),
      ClientSortOrder.recentlyAdded => _compareNullableDatesDescending(
        a.client.createdAt,
        b.client.createdAt,
      ),
      ClientSortOrder.mostBooked => b.bookingCount.compareTo(a.bookingCount),
    };
    return comparison != 0 ? comparison : _compareNames(a, b);
  });
  return sorted;
}

int _compareNames(ClientCrmRecord a, ClientCrmRecord b) {
  return a.client.name.toLowerCase().compareTo(b.client.name.toLowerCase());
}

int _compareNullableDates(DateTime? first, DateTime? second) {
  if (first == null && second == null) return 0;
  if (first == null) return 1;
  if (second == null) return -1;
  return first.compareTo(second);
}

int _compareNullableDatesDescending(DateTime? first, DateTime? second) {
  if (first == null && second == null) return 0;
  if (first == null) return 1;
  if (second == null) return -1;
  return second.compareTo(first);
}
