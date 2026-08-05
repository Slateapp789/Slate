import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/stripe_payments_repository.dart';

final stripeAccountStatusProvider = FutureProvider.autoDispose
    .family<StripeAccountStatus, String>((ref, workspaceId) {
      return ref
          .watch(stripePaymentsRepositoryProvider)
          .accountStatus(workspaceId);
    });
