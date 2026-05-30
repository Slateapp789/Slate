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

  Future<List<Map<String, dynamic>>> conflicts({
    required String workspaceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final rows = await _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .neq('status', 'cancelled')
        .lt('start_time', endTime.toUtc().toIso8601String())
        .gt('end_time', startTime.toUtc().toIso8601String())
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

  Future<List<String>> create({
    required String workspaceId,
    required String contactId,
    String? serviceId,
    required DateTime startTime,
    required DateTime endTime,
    required double price,
    String? title,
    String? notes,
    String? location,
    String? recurrenceRule,
    int repeatOccurrences = 1,
  }) async {
    final duration = endTime.difference(startTime);
    final safeTitle = title?.trim().isEmpty ?? true ? 'Booking' : title!.trim();
    final rows = List.generate(repeatOccurrences.clamp(1, 24), (index) {
      final occurrenceStart = _occurrenceStart(
        startTime,
        recurrenceRule,
        index,
      );
      return {
        'workspace_id': workspaceId,
        'contact_id': contactId,
        'service_id': serviceId,
        'title': safeTitle,
        'start_time': occurrenceStart.toIso8601String(),
        'end_time': occurrenceStart.add(duration).toIso8601String(),
        'price': price,
        'status': 'scheduled',
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'location': location?.trim().isEmpty ?? true ? null : location!.trim(),
        if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      };
    });

    try {
      final inserted = await _client
          .from('appointments')
          .insert(rows)
          .select('id');
      return List<Map<String, dynamic>>.from(
        inserted,
      ).map((row) => row['id'] as String).toList();
    } catch (_) {
      final fallbackRows = rows
          .map(
            (row) => Map<String, dynamic>.from(row)
              ..remove('recurrence_rule')
              ..remove('recurrence_parent_id')
              ..remove('location'),
          )
          .toList();
      final inserted = await _client
          .from('appointments')
          .insert(fallbackRows)
          .select('id');
      return List<Map<String, dynamic>>.from(
        inserted,
      ).map((row) => row['id'] as String).toList();
    }
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

  DateTime _occurrenceStart(DateTime startTime, String? rule, int index) {
    if (index == 0 || rule == null) return startTime;
    if (rule.contains('FREQ=MONTHLY')) {
      return DateTime.utc(
        startTime.year,
        startTime.month + index,
        startTime.day,
        startTime.hour,
        startTime.minute,
        startTime.second,
        startTime.millisecond,
        startTime.microsecond,
      );
    }
    final interval = rule.contains('INTERVAL=2') ? 2 : 1;
    return startTime.add(Duration(days: 7 * interval * index));
  }
}
