import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import '../utils/appointment_recurrence.dart';
import '../utils/working_hours.dart';
import 'repository_pagination.dart';
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
      final occurrenceStart = appointmentOccurrenceStart(
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
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('appointments')
            .select('*, contacts(name), services(name)')
            .eq('workspace_id', workspaceId)
            .order('start_time', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<Appointment>(Appointment.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> listRows(String workspaceId) async {
    return fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('appointments')
            .select('*, contacts(name), services(name)')
            .eq('workspace_id', workspaceId)
            .order('start_time', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
  }

  Future<List<Map<String, dynamic>>> listRowsForBusinessFeed(
    String workspaceId, {
    required DateTime from,
    required DateTime to,
    int limit = 80,
  }) async {
    final rows = await _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .gte('start_time', from.toUtc().toIso8601String())
        .lt('start_time', to.toUtc().toIso8601String())
        .neq('status', 'cancelled')
        .neq('status', 'no_show')
        .order('start_time', ascending: true)
        .order('id', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> conflicts({
    required String workspaceId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  }) async {
    return fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
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
        final page = await query
            .order('start_time', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
  }

  Future<List<Map<String, dynamic>>> forClientRows(String clientId) async {
    return fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('appointments')
            .select('*, services(name), contacts(name)')
            .eq('contact_id', clientId)
            .order('start_time', ascending: false)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
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
      final occurrenceStart = appointmentOccurrenceStart(
        startTime,
        recurrenceRule,
        index,
      );
      return {
        'workspace_id': workspaceId,
        'contact_id': contactId,
        'service_id': serviceId,
        'title': safeTitle,
        'start_time': occurrenceStart.toUtc().toIso8601String(),
        'end_time': occurrenceStart.add(duration).toUtc().toIso8601String(),
        'price': price,
        'status': 'scheduled',
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'location': location?.trim().isEmpty ?? true ? null : location!.trim(),
        'recurrence_rule': ?recurrenceRule,
      };
    });

    final inserted = await _client
        .from('appointments')
        .insert(rows)
        .select('id');
    return List<Map<String, dynamic>>.from(
      inserted,
    ).map((row) => row['id'] as String).toList();
  }

  Future<List<String>> createBookingWorkflow({
    required String workspaceId,
    required String idempotencyKey,
    String? contactId,
    String? newContactName,
    String? newContactPhone,
    String? newContactEmail,
    String? newContactAddress,
    String? newContactNotes,
    bool reuseContactByPhone = false,
    String? bookingRequestId,
    String? serviceId,
    required DateTime startTime,
    required DateTime endTime,
    required double price,
    String? title,
    String? notes,
    String? location,
    String? recurrenceRule,
    int repeatOccurrences = 1,
    List<String> taskTitles = const [],
    DateTime? taskDueDate,
    bool createPaymentDue = false,
    String? paymentNote,
    String notificationTitle = 'New booking created',
    String notificationBody = 'A booking was added to your schedule.',
  }) async {
    final payload = buildBookingWorkflowPayload(
      workspaceId: workspaceId,
      idempotencyKey: idempotencyKey,
      contactId: contactId,
      newContactName: newContactName,
      newContactPhone: newContactPhone,
      newContactEmail: newContactEmail,
      newContactAddress: newContactAddress,
      newContactNotes: newContactNotes,
      reuseContactByPhone: reuseContactByPhone,
      bookingRequestId: bookingRequestId,
      serviceId: serviceId,
      startTime: startTime,
      endTime: endTime,
      price: price,
      title: title,
      notes: notes,
      location: location,
      recurrenceRule: recurrenceRule,
      repeatOccurrences: repeatOccurrences,
      taskTitles: taskTitles,
      taskDueDate: taskDueDate,
      createPaymentDue: createPaymentDue,
      paymentNote: paymentNote,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
    );
    late final dynamic response;
    try {
      response = await _client.rpc(
        'create_booking_workflow',
        params: {'p_payload': payload},
      );
    } on PostgrestException catch (error) {
      if (isAppointmentConflictError(
        code: error.code,
        message: error.message,
      )) {
        throw const AppointmentScheduleException(
          'This time now overlaps an existing booking. Choose another time.',
          issue: AppointmentScheduleIssue.conflict,
        );
      }
      rethrow;
    }
    final result = Map<String, dynamic>.from(response as Map);
    final ids = result['appointment_ids'];
    if (ids is! List) {
      throw const FormatException(
        'Booking workflow returned an invalid appointment list.',
      );
    }
    return ids.map((id) => id.toString()).toList(growable: false);
  }

  Future<void> completeBookingWorkflow({
    required String workspaceId,
    required String appointmentId,
    required String idempotencyKey,
    required String paymentMode,
    String? linkedPaymentId,
    DateTime? paymentDate,
  }) async {
    await _client.rpc(
      'complete_booking_workflow',
      params: {
        'p_payload': buildCompletionWorkflowPayload(
          workspaceId: workspaceId,
          appointmentId: appointmentId,
          idempotencyKey: idempotencyKey,
          paymentMode: paymentMode,
          linkedPaymentId: linkedPaymentId,
          paymentDate: paymentDate,
        ),
      },
    );
  }

  Future<void> update(String appointmentId, Map<String, dynamic> values) async {
    await _client.from('appointments').update(values).eq('id', appointmentId);
  }

  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? notes,
  }) async {
    await update(appointmentId, {'status': status, 'notes': ?notes});
  }
}

Map<String, dynamic> buildBookingWorkflowPayload({
  required String workspaceId,
  required String idempotencyKey,
  String? contactId,
  String? newContactName,
  String? newContactPhone,
  String? newContactEmail,
  String? newContactAddress,
  String? newContactNotes,
  bool reuseContactByPhone = false,
  String? bookingRequestId,
  String? serviceId,
  required DateTime startTime,
  required DateTime endTime,
  required double price,
  String? title,
  String? notes,
  String? location,
  String? recurrenceRule,
  int repeatOccurrences = 1,
  List<String> taskTitles = const [],
  DateTime? taskDueDate,
  bool createPaymentDue = false,
  String? paymentNote,
  required String notificationTitle,
  required String notificationBody,
}) {
  final duration = endTime.difference(startTime);
  final occurrences = List.generate(repeatOccurrences.clamp(1, 24), (index) {
    final occurrenceStart = appointmentOccurrenceStart(
      startTime,
      recurrenceRule,
      index,
    );
    return {
      'start_time': occurrenceStart.toUtc().toIso8601String(),
      'end_time': occurrenceStart.add(duration).toUtc().toIso8601String(),
      'payment_date': _dateOnly(occurrenceStart.toLocal()),
    };
  }, growable: false);
  return {
    'workspace_id': workspaceId,
    'idempotency_key': idempotencyKey,
    'contact_id': ?contactId,
    if (contactId == null)
      'new_contact': {
        'name': newContactName,
        'phone': newContactPhone,
        'email': newContactEmail,
        'address': newContactAddress,
        'notes': newContactNotes,
      },
    'reuse_contact_by_phone': reuseContactByPhone,
    'booking_request_id': ?bookingRequestId,
    'service_id': ?serviceId,
    'title': title,
    'price': price,
    'notes': notes,
    'location': location,
    'recurrence_rule': ?recurrenceRule,
    'appointments': occurrences,
    'task_titles': taskTitles,
    if (taskDueDate != null) 'task_due_date': _dateOnly(taskDueDate),
    'create_payment_due': createPaymentDue,
    'payment_note': paymentNote,
    'notification_title': notificationTitle,
    'notification_body': notificationBody,
  };
}

String _dateOnly(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

Map<String, dynamic> buildCompletionWorkflowPayload({
  required String workspaceId,
  required String appointmentId,
  required String idempotencyKey,
  required String paymentMode,
  String? linkedPaymentId,
  DateTime? paymentDate,
}) {
  return {
    'workspace_id': workspaceId,
    'appointment_id': appointmentId,
    'idempotency_key': idempotencyKey,
    'payment_mode': paymentMode,
    'linked_payment_id': ?linkedPaymentId,
    if (paymentDate != null) 'payment_date': _dateOnly(paymentDate),
  };
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

bool isAppointmentConflictError({
  required String? code,
  required String message,
}) {
  return code == '23P01' || message.toLowerCase().contains('overlap');
}
