import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

class NotificationsRepository {
  final SupabaseClient _client;
  const NotificationsRepository(this._client);

  Future<List<SlateNotification>> list(String workspaceId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows
        .map<SlateNotification>(
          (row) => SlateNotification.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> preferences(String workspaceId) async {
    final prefs = await _client
        .from('notification_preferences')
        .select()
        .eq('workspace_id', workspaceId)
        .maybeSingle();
    return prefs == null ? null : Map<String, dynamic>.from(prefs);
  }

  Future<void> upsertPreferences(
    String workspaceId,
    Map<String, dynamic> values,
  ) async {
    await _client.from('notification_preferences').upsert({
      'workspace_id': workspaceId,
      ...values,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'workspace_id');
  }

  Future<void> markRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }
}
