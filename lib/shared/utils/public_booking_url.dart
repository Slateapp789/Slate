const _bookingPageOrigin = String.fromEnvironment(
  'BOOKING_PAGE_ORIGIN',
  defaultValue: 'https://workloop.uk',
);

Uri publicBookingPageUri(String handle) {
  final origin = Uri.parse(_bookingPageOrigin);
  return origin.replace(pathSegments: [handle.trim().toLowerCase()]);
}

String get publicBookingPageHost => Uri.parse(_bookingPageOrigin).host;

String publicBookingPageDisplayUrl(String handle) {
  final uri = publicBookingPageUri(handle);
  final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
  return '${uri.host}/$path';
}
