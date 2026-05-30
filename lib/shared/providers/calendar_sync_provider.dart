import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';
import 'workspace_settings_provider.dart';

class CalendarSyncState {
  final bool enabled;
  final Map<String, dynamic>? account;

  const CalendarSyncState({required this.enabled, required this.account});
}

final calendarSyncProvider = FutureProvider<CalendarSyncState>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) {
    return const CalendarSyncState(enabled: false, account: null);
  }

  final settings = await ref.watch(workspaceSettingsProvider.future);
  final account = await ref
      .watch(calendarSyncRepositoryProvider)
      .account(workspaceId);

  return CalendarSyncState(
    enabled: settings?['calendar_sync_enabled'] as bool? ?? false,
    account: account,
  );
});
