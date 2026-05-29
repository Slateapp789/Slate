import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';

final appointmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(appointmentsRepositoryProvider).listRows(workspaceId);
});

final servicesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(servicesRepositoryProvider).listRows(workspaceId);
});
