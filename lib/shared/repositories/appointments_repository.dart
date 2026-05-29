import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(supabaseClientProvider));
});

class AppointmentsRepository {
  final SupabaseClient _client;
  const AppointmentsRepository(this._client);

  Future<List<Appointment>> list(String workspaceId) async {
    final rows = await _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .order('start_time', ascending: true);
    return rows
        .map<Appointment>(
          (row) => Appointment.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> listRows(String workspaceId) async {
    final rows = await _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> forClientRows(String clientId) async {
    final rows = await _client
        .from('appointments')
        .select('*, services(name), contacts(name)')
        .eq('contact_id', clientId)
        .order('start_time', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Appointment>> upcoming(
    String workspaceId, {
    int limit = 5,
  }) async {
    final rows = await _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .gte('start_time', DateTime.now().toUtc().toIso8601String())
        .neq('status', 'cancelled')
        .order('start_time', ascending: true)
        .limit(limit);
    return rows
        .map<Appointment>(
          (row) => Appointment.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> create({
    required String workspaceId,
    required String contactId,
    required String serviceId,
    required DateTime startTime,
    required DateTime endTime,
    required double price,
    String? notes,
  }) async {
    await _client.from('appointments').insert({
      'workspace_id': workspaceId,
      'contact_id': contactId,
      'service_id': serviceId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'price': price,
      'status': 'scheduled',
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    });
  }

  Future<void> update(String appointmentId, Map<String, dynamic> values) async {
    await _client.from('appointments').update(values).eq('id', appointmentId);
  }

  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? notes,
  }) async {
    await update(appointmentId, {
      'status': status,
      if (notes != null) 'notes': notes,
    });
  }
}
