import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import '../utils/working_hours.dart';
import 'supabase_client_provider.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(supabaseClientProvider));
});

class AppointmentsRepository {
  final SupabaseClient _client;
  const AppointmentsRepository(this._client);

  Future<void> ensureScheduleAvailable({
    required String workspaceId,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, dynamic>? workingHours,
    String? excludeAppointmentId,
    String? recurrenceRule,
    int repeatOccurrences = 1,
    bool enforceWorkingHours = true,
  }) async {
    final duration = endTime.difference(startTime);
    for (var index = 0; index < repeatOccurrences.clamp(1, 24); index++) {
      final occurrenceStart = _occurrenceStart(
        startTime,
        recurrenceRule,
        index,
      );
      final occurrenceEnd = occurrenceStart.add(duration);
      if (enforceWorkingHours &&
          workingHours != null &&
          workingHours.isNotEmpty) {
        final localStart = occurrenceStart.toLocal();
        final localEnd = occurrenceEnd.toLocal();
        if (!isWithinWorkingHours(
          hours: workingHours,
          start: localStart,
          end: localEnd,
        )) {
          throw AppointmentScheduleException(
            '${weekdayName(localStart)} is outside your working hours.',
            issue: AppointmentScheduleIssue.workingHours,
          );
        }
      }

      final rows = await conflicts(
        workspaceId: workspaceId,
        startTime: occurrenceStart,
        endTime: occurrenceEnd,
        excludeAppointmentId: excludeAppointmentId,
      );
      if (rows.isNotEmpty) {
        throw AppointmentScheduleException(
          rows.length == 1
              ? 'This overlaps an existing booking.'
              : 'This overlaps ${rows.length} existing bookings.',
          issue: AppointmentScheduleIssue.conflict,
        );
      }
    }
  }

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
    String? excludeAppointmentId,
  }) async {
    var query = _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .neq('status', 'cancelled')
        .lt('start_time', endTime.toUtc().toIso8601String())
        .gt('end_time', startTime.toUtc().toIso8601String());
    if (excludeAppointmentId != null) {
      query = query.neq('id', excludeAppointmentId);
    }
    final rows = await query.order('start_time', ascending: true);
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

enum AppointmentScheduleIssue { workingHours, conflict, other }

class AppointmentScheduleException implements Exception {
  final String message;
  final AppointmentScheduleIssue issue;

  const AppointmentScheduleException(
    this.message, {
    this.issue = AppointmentScheduleIssue.other,
  });

  @override
  String toString() => message;
}
