import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_pagination.dart';
import 'supabase_client_provider.dart';

const privacyExportPageSize = 1000;

const workspacePrivacyExportTables = <String>{
  'workspaces',
  'workspace_members',
  'workspace_settings',
  'business_profiles',
  'contacts',
  'services',
  'appointments',
  'invoices',
  'invoice_line_items',
  'expenses',
  'tasks',
  'task_checklist_items',
  'notes',
  'booking_requests',
  'notification_preferences',
  'notifications',
  'push_tokens',
  'calendar_sync_accounts',
  'account_deletion_requests',
};

class PrivacyExportIncompleteException implements Exception {
  final List<String> warnings;
  const PrivacyExportIncompleteException(this.warnings);

  @override
  String toString() => 'Workspace export was incomplete: ${warnings.join(' ')}';
}

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  return PrivacyRepository(ref.watch(supabaseClientProvider));
});

class PrivacyRepository {
  final SupabaseClient _client;
  const PrivacyRepository(this._client);

  Future<String> exportWorkspaceData(String workspaceId) async {
    final warnings = <String>[];
    final user = _client.auth.currentUser;
    final data = <String, dynamic>{
      'format': 'workloop_workspace_export',
      'format_version': 2,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'workspace_id': workspaceId,
      'account': user == null
          ? null
          : {
              'id': user.id,
              'email': user.email,
              'user_metadata': user.userMetadata,
            },
      'workspace': await _maybeSingle(
        'workspaces',
        'id',
        workspaceId,
        warnings,
      ),
      'workspace_settings': await _maybeSingle(
        'workspace_settings',
        'workspace_id',
        workspaceId,
        warnings,
      ),
      'business_profile': await _maybeSingle(
        'business_profiles',
        'workspace_id',
        workspaceId,
        warnings,
      ),
      'workspace_members': await _list(
        'workspace_members',
        workspaceId,
        warnings,
      ),
      'contacts': await _list('contacts', workspaceId, warnings),
      'services': await _list('services', workspaceId, warnings),
      'appointments': await _list('appointments', workspaceId, warnings),
      'payments': await _list('invoices', workspaceId, warnings),
      'payment_line_items': await _list(
        'invoice_line_items',
        workspaceId,
        warnings,
      ),
      'expenses': await _list('expenses', workspaceId, warnings),
      'tasks': await _list('tasks', workspaceId, warnings),
      'task_checklist_items': await _list(
        'task_checklist_items',
        workspaceId,
        warnings,
      ),
      'notes': await _list('notes', workspaceId, warnings),
      'booking_requests': await _list(
        'booking_requests',
        workspaceId,
        warnings,
      ),
      'notification_preferences': await _maybeSingle(
        'notification_preferences',
        'workspace_id',
        workspaceId,
        warnings,
      ),
      'notifications': await _list('notifications', workspaceId, warnings),
      'push_tokens': await _list('push_tokens', workspaceId, warnings),
      'calendar_sync_accounts': await _list(
        'calendar_sync_accounts',
        workspaceId,
        warnings,
      ),
      'account_deletion_requests': await _list(
        'account_deletion_requests',
        workspaceId,
        warnings,
      ),
    };
    if (warnings.isNotEmpty) {
      throw PrivacyExportIncompleteException(List.unmodifiable(warnings));
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> requestAccountDeletion({required String workspaceId}) async {
    await _client.functions.invoke(
      'request-account-deletion',
      body: {'workspaceId': workspaceId},
    );
  }

  Future<Map<String, dynamic>?> _maybeSingle(
    String table,
    String column,
    String value,
    List<String> warnings,
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
      warnings.add('$table could not be included in this export.');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _list(
    String table,
    String workspaceId,
    List<String> warnings,
  ) async {
    try {
      return fetchAllRepositoryPages<Map<String, dynamic>>(
        pageSize: privacyExportPageSize,
        loadPage: (from, to) async {
          final rows = await _client
              .from(table)
              .select()
              .eq('workspace_id', workspaceId)
              .order('id')
              .range(from, to);
          return List<Map<String, dynamic>>.from(rows);
        },
      );
    } catch (_) {
      warnings.add('$table could not be included in this export.');
      return [];
    }
  }
}
