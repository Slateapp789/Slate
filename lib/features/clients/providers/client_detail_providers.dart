import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/slate_models.dart';
import '../../../shared/repositories/slate_repositories.dart';

final clientAppointmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      clientId,
    ) async {
      return ref.watch(appointmentsRepositoryProvider).forClientRows(clientId);
    });

final clientTasksProvider = FutureProvider.family<List<SlateTask>, String>((
  ref,
  clientId,
) async {
  return ref.watch(tasksRepositoryProvider).forClient(clientId);
});

final clientPaymentsProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  clientId,
) async {
  return ref.watch(paymentsRepositoryProvider).forClient(clientId);
});
