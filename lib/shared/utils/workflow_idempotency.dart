import 'dart:math';

/// Creates a client-held key that stays stable while one workflow is retried.
///
/// The database stores this key with the authenticated workspace and returns
/// the original result when a response is lost after the transaction commits.
String createWorkflowIdempotencyKey() {
  final random = Random.secure();
  final entropy = List<int>.generate(
    18,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$entropy';
}

/// Creates a UUID v4 suitable for retry-safe public Edge requests.
String createPublicRequestToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
