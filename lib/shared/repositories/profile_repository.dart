import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'appointments_repository.dart';
import 'repository_pagination.dart';
import 'supabase_client_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

class ProfileRepository {
  final SupabaseClient _client;
  const ProfileRepository(this._client);

  Future<bool> isHandleAvailable(String handle) async {
    return await getPublicProfile(handle.trim().toLowerCase()) == null;
  }

  Future<PublicProfile?> getPublicProfile(String handle) async {
    late final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'get-public-profile',
        body: {'handle': handle},
      );
    } on FunctionException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final profileMap = Map<String, dynamic>.from(data['profile'] as Map);
    final businessProfile = BusinessProfile.fromMap(profileMap);
    final services = List<dynamic>.from(data['services'] as List? ?? []);

    return PublicProfile(
      profile: businessProfile,
      businessName: data['businessName'] as String? ?? 'Business',
      industry: data['industry'] as String?,
      workingHours: Map<String, dynamic>.from(
        data['workingHours'] as Map? ?? {},
      ),
      services: services
          .map<Service>(
            (row) => Service.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList(),
    );
  }

  Future<BusinessProfile?> getWorkspaceProfile(String workspaceId) async {
    final profile = await _client
        .from('business_profiles')
        .select()
        .eq('workspace_id', workspaceId)
        .maybeSingle();
    if (profile == null) return null;
    return BusinessProfile.fromMap(Map<String, dynamic>.from(profile));
  }

  Future<void> updateWorkspaceProfile({
    required String workspaceId,
    required Map<String, dynamic> values,
  }) async {
    await _client.from('business_profiles').upsert({
      'workspace_id': workspaceId,
      ...values,
    }, onConflict: 'workspace_id');
  }

  Future<void> createBookingRequest({
    required String handle,
    required String name,
    required String phone,
    required String email,
    required String requestToken,
    String? serviceId,
    String? preferredTimeText,
    String? message,
  }) async {
    await _client.functions.invoke(
      'create-booking-request',
      body: buildPublicBookingRequestPayload(
        handle: handle,
        name: name,
        phone: phone,
        email: email,
        requestToken: requestToken,
        serviceId: serviceId,
        preferredTimeText: preferredTimeText,
        message: message,
      ),
    );
  }

  Future<List<BookingRequest>> bookingRequests(String workspaceId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('booking_requests')
            .select('*, services(name, duration_mins, price)')
            .eq('workspace_id', workspaceId)
            .order('created_at', ascending: false)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<BookingRequest>(BookingRequest.fromMap).toList();
  }

  Future<List<BookingRequest>> pendingBookingRequestsForBusinessFeed(
    String workspaceId, {
    int limit = 8,
  }) async {
    final rows = await _client
        .from('booking_requests')
        .select('*, services(name, duration_mins, price)')
        .eq('workspace_id', workspaceId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .order('id', ascending: true)
        .limit(limit);
    return rows
        .map<BookingRequest>(
          (row) => BookingRequest.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> updateBookingRequestStatus({
    required String requestId,
    required String workspaceId,
    required String status,
  }) async {
    final sourceStatuses = bookingRequestSourceStatusesFor(status);
    final updated = await _client
        .from('booking_requests')
        .update({'status': status})
        .eq('id', requestId)
        .eq('workspace_id', workspaceId)
        .inFilter('status', sourceStatuses)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw const BookingRequestStateException(
        'This request changed elsewhere. Refresh it before trying again.',
      );
    }
  }

  Future<BookingRequestConfirmationOutcome> confirmBookingRequest({
    required BookingRequest request,
    required DateTime startTime,
    required int durationMins,
    required double price,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? serviceTitle,
    String? location,
    String? extraNotes,
    bool createPaymentDue = false,
    bool enforceWorkingHours = true,
  }) async {
    final endTime = startTime.add(Duration(minutes: durationMins));
    final title = serviceTitle?.trim().isNotEmpty == true
        ? serviceTitle!.trim()
        : request.serviceName?.trim().isNotEmpty == true
        ? request.serviceName!.trim()
        : 'Booking request';
    final notes = [
      if (request.preferredTimeText?.trim().isNotEmpty == true)
        'Requested time: ${request.preferredTimeText!.trim()}',
      if (request.message?.trim().isNotEmpty == true) request.message!.trim(),
      if (extraNotes?.trim().isNotEmpty == true) extraNotes!.trim(),
    ].join('\n\n');
    final serviceId = await _validServiceIdForRequest(request);
    final settings = await _client
        .from('workspace_settings')
        .select('working_hours')
        .eq('workspace_id', request.workspaceId)
        .maybeSingle();
    final workingHours = settings?['working_hours'] is Map
        ? Map<String, dynamic>.from(settings!['working_hours'] as Map)
        : <String, dynamic>{};
    final startUtc = startTime.toUtc();
    final endUtc = endTime.toUtc();

    await AppointmentsRepository(_client).ensureScheduleAvailable(
      workspaceId: request.workspaceId,
      startTime: startUtc,
      endTime: endUtc,
      workingHours: workingHours,
      enforceWorkingHours: enforceWorkingHours,
    );

    final phone = clientPhone?.trim().isNotEmpty == true
        ? clientPhone!.trim()
        : request.phone.trim();
    final name = clientName?.trim().isNotEmpty == true
        ? clientName!.trim()
        : request.name.trim();
    final email = clientEmail?.trim().isNotEmpty == true
        ? clientEmail!.trim()
        : request.email.trim();
    final contactNotes = [
      'Created from public booking request.',
      if (request.preferredTimeText?.trim().isNotEmpty == true)
        'Requested time: ${request.preferredTimeText!.trim()}',
      if (request.message?.trim().isNotEmpty == true) request.message!.trim(),
    ].join('\n\n');

    final payload = buildBookingWorkflowPayload(
      workspaceId: request.workspaceId,
      idempotencyKey: bookingRequestConfirmationIdempotencyKey(request.id),
      newContactName: name.isEmpty ? 'New client' : name,
      newContactPhone: phone,
      newContactEmail: email.isEmpty ? null : email,
      newContactNotes: contactNotes,
      reuseContactByPhone: true,
      bookingRequestId: request.id,
      serviceId: serviceId,
      startTime: startUtc,
      endTime: endUtc,
      price: price,
      title: title,
      notes: notes.isEmpty ? null : notes,
      location: location?.trim().isNotEmpty == true ? location!.trim() : null,
      createPaymentDue: createPaymentDue,
      paymentNote: createPaymentDue ? 'Payment due for $title' : null,
      notificationTitle: 'Booking request confirmed',
      notificationBody: '${request.name} has been added to your calendar.',
    );
    try {
      final response = await _client.functions.invoke(
        'confirm-booking-request',
        body: {'payload': payload},
      );
      return BookingRequestConfirmationOutcome.fromResponse(response.data);
    } on FunctionException catch (error) {
      final details = error.details is Map
          ? Map<String, dynamic>.from(error.details as Map)
          : const <String, dynamic>{};
      final code = details['code']?.toString();
      final message = details['error']?.toString() ?? '';
      if (isAppointmentConflictError(code: code, message: message)) {
        throw const AppointmentScheduleException(
          'This time now overlaps an existing booking. Choose another time.',
          issue: AppointmentScheduleIssue.conflict,
        );
      }
      if (isBookingRequestStateError(code: code, message: message)) {
        throw const BookingRequestStateException(
          'This request was already handled or is no longer available.',
        );
      }
      rethrow;
    }
  }

  Future<String?> _validServiceIdForRequest(BookingRequest request) async {
    final serviceId = request.serviceId;
    if (serviceId == null || serviceId.trim().isEmpty) return null;
    final service = await _client
        .from('services')
        .select('id')
        .eq('id', serviceId)
        .eq('workspace_id', request.workspaceId)
        .maybeSingle();
    return service == null ? null : serviceId;
  }
}

Map<String, dynamic> buildPublicBookingRequestPayload({
  required String handle,
  required String name,
  required String phone,
  required String email,
  required String requestToken,
  String? serviceId,
  String? preferredTimeText,
  String? message,
}) => {
  'handle': handle,
  'name': name,
  'phone': phone,
  'email': email,
  'requestToken': requestToken,
  'serviceId': serviceId,
  'preferredTimeText': preferredTimeText,
  'message': message,
};

bool isValidBookingRequestEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > 254) return false;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}

enum BookingRequestConfirmationEmailStatus {
  sent,
  pending,
  failed,
  notApplicable,
}

class BookingRequestConfirmationOutcome {
  final BookingRequestConfirmationEmailStatus confirmationEmailStatus;

  const BookingRequestConfirmationOutcome({
    required this.confirmationEmailStatus,
  });

  factory BookingRequestConfirmationOutcome.fromResponse(Object? value) {
    final response = value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final confirmationEmail = response['confirmationEmail'] is Map
        ? Map<String, dynamic>.from(response['confirmationEmail'] as Map)
        : const <String, dynamic>{};
    final status = switch (confirmationEmail['status']) {
      'sent' => BookingRequestConfirmationEmailStatus.sent,
      'pending' => BookingRequestConfirmationEmailStatus.pending,
      'failed' => BookingRequestConfirmationEmailStatus.failed,
      'not_applicable' => BookingRequestConfirmationEmailStatus.notApplicable,
      _ => throw const FormatException(
        'Booking confirmation returned an invalid email status.',
      ),
    };
    return BookingRequestConfirmationOutcome(confirmationEmailStatus: status);
  }
}

List<String> bookingRequestSourceStatusesFor(String targetStatus) {
  return switch (targetStatus) {
    'contacted' => const ['pending', 'contacted'],
    'declined' => const ['pending', 'contacted'],
    _ => throw ArgumentError.value(
      targetStatus,
      'targetStatus',
      'Only contacted and declined are direct request transitions.',
    ),
  };
}

String bookingRequestConfirmationIdempotencyKey(String requestId) =>
    'booking-request-confirm:$requestId';

bool isBookingRequestStateError({
  required String? code,
  required String message,
}) {
  final normalizedMessage = message.toLowerCase();
  return (code == '23505' &&
          normalizedMessage.contains('booking request') &&
          normalizedMessage.contains('no longer')) ||
      (code == 'P0002' &&
          normalizedMessage.contains('booking request') &&
          normalizedMessage.contains('not found'));
}

class BookingRequestStateException implements Exception {
  final String message;

  const BookingRequestStateException(this.message);

  @override
  String toString() => message;
}

class PublicProfile {
  final BusinessProfile profile;
  final String businessName;
  final String? industry;
  final Map<String, dynamic> workingHours;
  final List<Service> services;

  const PublicProfile({
    required this.profile,
    required this.businessName,
    required this.workingHours,
    required this.services,
    this.industry,
  });
}
