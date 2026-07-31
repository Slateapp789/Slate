import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'repository_pagination.dart';
import 'supabase_client_provider.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(supabaseClientProvider));
});

class NotesRepository {
  final SupabaseClient _client;
  const NotesRepository(this._client);

  Future<List<SlateNote>> list(String workspaceId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('notes')
            .select('*, contacts(name)')
            .eq('workspace_id', workspaceId)
            .order('pinned', ascending: false)
            .order('updated_at', ascending: false)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );

    return rows.map<SlateNote>(SlateNote.fromMap).toList();
  }

  Future<String> create({
    required String workspaceId,
    required String title,
    required String body,
    String? contactId,
    String? appointmentId,
    bool pinned = false,
  }) async {
    final row = await _client
        .from('notes')
        .insert({
          'workspace_id': workspaceId,
          'title': title.trim(),
          'body': body.trim(),
          'contact_id': contactId,
          'appointment_id': appointmentId,
          'pinned': pinned,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> update({
    required String noteId,
    required String title,
    required String body,
    String? contactId,
    String? appointmentId,
    required bool pinned,
  }) async {
    await _client
        .from('notes')
        .update({
          'title': title.trim(),
          'body': body.trim(),
          'contact_id': contactId,
          'appointment_id': appointmentId,
          'pinned': pinned,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', noteId);
  }

  Future<void> setPinned({required String noteId, required bool pinned}) async {
    await _client
        .from('notes')
        .update({
          'pinned': pinned,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', noteId);
  }

  Future<void> delete(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }
}
