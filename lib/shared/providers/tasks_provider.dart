import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';

// Used on dashboard — only open tasks due today or earlier
final tasksProvider = FutureProvider<List<SlateTask>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(tasksRepositoryProvider).dueOpen(workspaceId);
});

// Used on tasks screen — all tasks open and done
final allTasksProvider = FutureProvider<List<SlateTask>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(tasksRepositoryProvider).list(workspaceId);
});

final taskChecklistProvider =
    FutureProvider.family<List<TaskChecklistItem>, String>((ref, taskId) {
      return ref.watch(tasksRepositoryProvider).checklistItems(taskId);
    });

final appointmentTasksProvider = FutureProvider.family<List<SlateTask>, String>(
  (ref, appointmentId) {
    return ref.watch(tasksRepositoryProvider).forAppointment(appointmentId);
  },
);
