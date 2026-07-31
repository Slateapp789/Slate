import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'repository_pagination.dart';
import 'supabase_client_provider.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(supabaseClientProvider));
});

class TasksRepository {
  final SupabaseClient _client;
  const TasksRepository(this._client);

  Future<List<SlateTask>> list(String workspaceId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('tasks')
            .select('*, contacts(name)')
            .eq('workspace_id', workspaceId)
            .order('due_date', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<SlateTask>(SlateTask.fromMap).toList();
  }

  Future<List<SlateTask>> dueOpen(String workspaceId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('tasks')
            .select('*, contacts(name)')
            .eq('workspace_id', workspaceId)
            .eq('status', 'open')
            .lte('due_date', today)
            .order('due_date', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<SlateTask>(SlateTask.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> forClientRows(String clientId) async {
    return fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('tasks')
            .select('*, contacts(name)')
            .eq('contact_id', clientId)
            .order('due_date', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
  }

  Future<List<SlateTask>> forAppointment(String appointmentId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('tasks')
            .select('*, contacts(name)')
            .eq('appointment_id', appointmentId)
            .order('due_date', ascending: true)
            .order('created_at', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<SlateTask>(SlateTask.fromMap).toList();
  }

  Future<List<SlateTask>> forClient(String clientId) async {
    final rows = await forClientRows(clientId);
    return rows.map<SlateTask>((row) => SlateTask.fromMap(row)).toList();
  }

  Future<String> create({
    required String workspaceId,
    required String title,
    required String priority,
    String reminderTiming = 'none',
    DateTime? dueDate,
    String? contactId,
    String? appointmentId,
  }) async {
    final row = await _client
        .from('tasks')
        .insert({
          'workspace_id': workspaceId,
          'title': title.trim(),
          'priority': priority,
          'reminder_timing': reminderTiming,
          'due_date': dueDate?.toIso8601String().split('T').first,
          'status': 'open',
          'contact_id': contactId,
          'appointment_id': appointmentId,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<String> createWithChecklist({
    required String workspaceId,
    required String title,
    required String priority,
    required String reminderTiming,
    required List<String> checklistTitles,
    required String idempotencyKey,
    DateTime? dueDate,
    String? contactId,
    String? appointmentId,
  }) async {
    final response = await _client.rpc(
      'create_task_workflow',
      params: {
        'p_payload': buildCreateTaskWorkflowPayload(
          workspaceId: workspaceId,
          title: title,
          priority: priority,
          reminderTiming: reminderTiming,
          checklistTitles: checklistTitles,
          idempotencyKey: idempotencyKey,
          dueDate: dueDate,
          contactId: contactId,
          appointmentId: appointmentId,
        ),
      },
    );
    final result = Map<String, dynamic>.from(response as Map);
    final taskId = result['task_id'] as String?;
    if (taskId == null || taskId.isEmpty) {
      throw const FormatException('Task workflow returned no task identifier.');
    }
    return taskId;
  }

  Future<void> updateStatus(String taskId, String status) async {
    await _client
        .from('tasks')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', taskId)
        .select('id')
        .single();
  }

  Future<void> update({
    required String taskId,
    required String title,
    required String priority,
    String reminderTiming = 'none',
    DateTime? dueDate,
    String? contactId,
    String? appointmentId,
  }) async {
    await _client
        .from('tasks')
        .update({
          'title': title.trim(),
          'priority': priority,
          'reminder_timing': reminderTiming,
          'due_date': dueDate?.toIso8601String().split('T').first,
          'contact_id': contactId,
          'appointment_id': appointmentId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', taskId)
        .select('id')
        .single();
  }

  Future<void> delete(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId).select('id').single();
  }

  Future<List<TaskChecklistItem>> checklistItems(String taskId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('task_checklist_items')
            .select()
            .eq('task_id', taskId)
            .order('position', ascending: true)
            .order('created_at', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<TaskChecklistItem>(TaskChecklistItem.fromMap).toList();
  }

  Future<void> addChecklistItem({
    required String workspaceId,
    required String taskId,
    required String title,
    required int position,
  }) async {
    await _client.from('task_checklist_items').insert({
      'workspace_id': workspaceId,
      'task_id': taskId,
      'title': title.trim(),
      'position': position,
    });
  }

  Future<void> addChecklistItems({
    required String workspaceId,
    required String taskId,
    required List<String> titles,
  }) async {
    final cleaned = titles
        .map((title) => title.trim())
        .where((title) => title.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return;

    await _client
        .from('task_checklist_items')
        .insert(
          List.generate(cleaned.length, (index) {
            return {
              'workspace_id': workspaceId,
              'task_id': taskId,
              'title': cleaned[index],
              'position': index,
            };
          }),
        );
  }

  Future<void> updateChecklistItem({
    required String itemId,
    required String title,
  }) async {
    await _client
        .from('task_checklist_items')
        .update({
          'title': title.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', itemId)
        .select('id')
        .single();
  }

  Future<void> updateChecklistItemStatus({
    required String itemId,
    required bool completed,
  }) async {
    await _client
        .from('task_checklist_items')
        .update({
          'completed': completed,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', itemId)
        .select('id')
        .single();
  }

  Future<void> deleteChecklistItem(String itemId) async {
    await _client
        .from('task_checklist_items')
        .delete()
        .eq('id', itemId)
        .select('id')
        .single();
  }
}

Map<String, dynamic> buildCreateTaskWorkflowPayload({
  required String workspaceId,
  required String title,
  required String priority,
  required String reminderTiming,
  required List<String> checklistTitles,
  required String idempotencyKey,
  DateTime? dueDate,
  String? contactId,
  String? appointmentId,
}) {
  return {
    'workspace_id': workspaceId,
    'title': title.trim(),
    'priority': priority,
    'reminder_timing': reminderTiming,
    'due_date': dueDate?.toIso8601String().split('T').first,
    'contact_id': contactId,
    'appointment_id': appointmentId,
    'checklist_titles': checklistTitles
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false),
    'idempotency_key': idempotencyKey,
  };
}
