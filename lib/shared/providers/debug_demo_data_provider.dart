import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../repositories/slate_repositories.dart';
import 'clients_provider.dart';
import 'dashboard_provider.dart';
import 'finance_provider.dart';
import 'tasks_provider.dart';
import 'workspace_provider.dart';

final debugDemoSeedProvider = FutureProvider<void>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return;

  try {
    await ref.watch(debugDemoDataRepositoryProvider).seed(workspaceId);
  } catch (error, stackTrace) {
    debugPrint('Slate demo seed failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  ref.invalidate(clientsProvider);
  ref.invalidate(dashboardRevenueProvider);
  ref.invalidate(dashboardFocusProvider);
  ref.invalidate(todayAppointmentsProvider);
  ref.invalidate(allTasksProvider);
  ref.invalidate(tasksProvider);
  ref.invalidate(invoicesProvider);
});
