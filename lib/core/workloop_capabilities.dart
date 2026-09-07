import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class WorkloopCapabilities {
  // Native acceptance requires separate entitlement and real-device approval.
  static const tapToPayEnabled = bool.fromEnvironment(
    'TAP_TO_PAY_ENABLED',
    defaultValue: false,
  );

  static const paymentCollectionEnabled = bool.fromEnvironment(
    'PAYMENT_COLLECTION_ENABLED',
    defaultValue: false,
  );
}

final paymentCollectionEnabledProvider = Provider<bool>(
  (ref) => WorkloopCapabilities.paymentCollectionEnabled,
);
