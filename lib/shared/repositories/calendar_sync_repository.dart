import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final calendarSyncRepositoryProvider = Provider<CalendarSyncRepository>((ref) {
  return CalendarSyncRepository(ref.watch(supabaseClientProvider));
});

class CalendarSyncRepository {
  final SupabaseClient _client;
  const CalendarSyncRepository(this._client);

  Future<Map<String, dynamic>?> account(String workspaceId) async {
    try {
      final row = await _client
          .from('calendar_sync_accounts')
          .select()
          .eq('workspace_id', workspaceId)
          .eq('sync_enabled', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> connect({
    required String workspaceId,
    required String provider,
  }) async {
    await _client
        .from('workspace_settings')
        .update({'calendar_sync_enabled': true})
        .eq('workspace_id', workspaceId);

    try {
      await _client.from('calendar_sync_accounts').insert({
        'workspace_id': workspaceId,
        'provider': provider,
        'provider_account_id': 'demo-$provider',
        'sync_enabled': true,
        'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // The settings flag is enough for current V1 UI if account table is absent.
    }
  }

  Future<void> disconnect(String workspaceId) async {
    await _client
        .from('workspace_settings')
        .update({'calendar_sync_enabled': false})
        .eq('workspace_id', workspaceId);

    try {
      await _client
          .from('calendar_sync_accounts')
          .update({'sync_enabled': false})
          .eq('workspace_id', workspaceId);
    } catch (_) {}
  }
}
