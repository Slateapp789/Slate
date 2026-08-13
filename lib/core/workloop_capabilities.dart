import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class WorkloopCapabilities {
  static const paymentCollectionEnabled = bool.fromEnvironment(
    'PAYMENT_COLLECTION_ENABLED',
    defaultValue: false,
  );
}

final paymentCollectionEnabledProvider = Provider<bool>(
  (ref) => WorkloopCapabilities.paymentCollectionEnabled,
);
