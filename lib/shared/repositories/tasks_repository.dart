import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(supabaseClientProvider));
});

class TasksRepository {
  final SupabaseClient _client;
  const TasksRepository(this._client);

  Future<List<SlateTask>> list(String workspaceId) async {
    final rows = await _client
        .from('tasks')
        .select('*, contacts(name)')
        .eq('workspace_id', workspaceId)
        .order('due_date', ascending: true);
    return rows
        .map<SlateTask>(
          (row) => SlateTask.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<SlateTask>> dueOpen(String workspaceId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await _client
        .from('tasks')
        .select('*, contacts(name)')
        .eq('workspace_id', workspaceId)
        .eq('status', 'open')
        .lte('due_date', today)
        .order('due_date', ascending: true);
    return rows
        .map<SlateTask>(
          (row) => SlateTask.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> forClientRows(String clientId) async {
    final rows = await _client
        .from('tasks')
        .select('*, contacts(name)')
        .eq('contact_id', clientId)
        .order('due_date', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<SlateTask>> forClient(String clientId) async {
    final rows = await forClientRows(clientId);
    return rows.map<SlateTask>((row) => SlateTask.fromMap(row)).toList();
  }

  Future<void> create({
    required String workspaceId,
    required String title,
    required String priority,
    DateTime? dueDate,
    String? contactId,
  }) async {
    await _client.from('tasks').insert({
      'workspace_id': workspaceId,
      'title': title.trim(),
      'priority': priority,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'status': 'open',
      'contact_id': contactId,
    });
  }

  Future<void> updateStatus(String taskId, String status) async {
    await _client.from('tasks').update({'status': status}).eq('id', taskId);
  }

  Future<void> update({
    required String taskId,
    required String title,
    required String priority,
    DateTime? dueDate,
    String? contactId,
  }) async {
    await _client
        .from('tasks')
        .update({
          'title': title.trim(),
          'priority': priority,
          'due_date': dueDate?.toIso8601String().split('T').first,
          'contact_id': contactId,
        })
        .eq('id', taskId);
  }

  Future<void> delete(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }
}
