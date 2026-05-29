import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/repositories/slate_repositories.dart';

final settingsServicesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(servicesRepositoryProvider).listRows(workspaceId);
});

final settingsBusinessProfileProvider = FutureProvider<BusinessProfile?>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return null;
  return ref.watch(profileRepositoryProvider).getWorkspaceProfile(workspaceId);
});

final settingsWorkspaceSettingsProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) async {
    final workspaceId = await ref.watch(workspaceIdProvider.future);
    if (workspaceId == null) return null;
    return ref.watch(workspaceSettingsRepositoryProvider).get(workspaceId);
  },
);
