import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';

final workspaceSettingsProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return null;
  return ref.watch(workspaceSettingsRepositoryProvider).get(workspaceId);
});
