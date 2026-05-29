import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';

final typedWorkspaceProvider = FutureProvider<Workspace?>((ref) async {
  return ref.watch(workspaceRepositoryProvider).currentWorkspace();
});

final typedClientsProvider = FutureProvider<List<Client>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(clientsRepositoryProvider).list(workspaceId);
});

final typedAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(appointmentsRepositoryProvider).list(workspaceId);
});

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(appointmentsRepositoryProvider).upcoming(workspaceId);
});

final typedPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(paymentsRepositoryProvider).list(workspaceId);
});

final outstandingPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(paymentsRepositoryProvider).outstanding(workspaceId);
});

final typedTasksProvider = FutureProvider<List<SlateTask>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(tasksRepositoryProvider).list(workspaceId);
});
