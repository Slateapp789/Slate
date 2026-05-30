import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  return PrivacyRepository(ref.watch(supabaseClientProvider));
});

class PrivacyRepository {
  final SupabaseClient _client;
  const PrivacyRepository(this._client);

  Future<String> exportWorkspaceData(String workspaceId) async {
    final data = <String, dynamic>{
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'workspace_id': workspaceId,
      'workspace': await _maybeSingle('workspaces', 'id', workspaceId),
      'workspace_settings': await _maybeSingle(
        'workspace_settings',
        'workspace_id',
        workspaceId,
      ),
      'business_profile': await _maybeSingle(
        'business_profiles',
        'workspace_id',
        workspaceId,
      ),
      'contacts': await _list('contacts', workspaceId),
      'services': await _list('services', workspaceId),
      'appointments': await _list('appointments', workspaceId),
      'payments': await _list('invoices', workspaceId),
      'tasks': await _list('tasks', workspaceId),
      'booking_requests': await _list('booking_requests', workspaceId),
      'notification_preferences': await _maybeSingle(
        'notification_preferences',
        'workspace_id',
        workspaceId,
      ),
      'notifications': await _list('notifications', workspaceId),
      'calendar_sync_accounts': await _list(
        'calendar_sync_accounts',
        workspaceId,
      ),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> requestAccountDeletion({
    required String workspaceId,
    required String email,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('account_deletion_requests').insert({
      'workspace_id': workspaceId,
      'user_id': userId,
      'email': email,
      'status': 'requested',
      'requested_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> _maybeSingle(
    String table,
    String column,
    String value,
  ) async {
    try {
      final row = await _client
          .from(table)
          .select()
          .eq(column, value)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _list(
    String table,
    String workspaceId,
  ) async {
    try {
      final rows = await _client
          .from(table)
          .select()
          .eq('workspace_id', workspaceId);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }
}
