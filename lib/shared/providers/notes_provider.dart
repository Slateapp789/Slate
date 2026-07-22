import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/slate_models.dart';
import '../repositories/notes_repository.dart';
import 'workspace_provider.dart';

final allNotesProvider = FutureProvider<List<SlateNote>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(notesRepositoryProvider).list(workspaceId);
});
