import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

class ProfileRepository {
  final SupabaseClient _client;
  const ProfileRepository(this._client);

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
    String? serviceId,
    String? preferredTimeText,
    String? message,
  }) async {
    await _client.functions.invoke(
      'create-booking-request',
      body: {
        'handle': handle,
        'name': name,
        'phone': phone,
        'serviceId': serviceId,
        'preferredTimeText': preferredTimeText,
        'message': message,
      },
    );
  }

  Future<List<BookingRequest>> bookingRequests(String workspaceId) async {
    final rows = await _client
        .from('booking_requests')
        .select('*, services(name, duration_mins, price)')
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);
    return rows
        .map<BookingRequest>(
          (row) => BookingRequest.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> updateBookingRequestStatus(
    String requestId,
    String status,
  ) async {
    await _client
        .from('booking_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  Future<void> confirmBookingRequest({
    required BookingRequest request,
    required DateTime startTime,
    required int durationMins,
    required double price,
    String? clientName,
    String? clientPhone,
    String? serviceTitle,
    String? location,
    String? extraNotes,
    bool createPaymentDue = false,
  }) async {
    final contactId = await _findOrCreateRequestContact(
      request,
      clientName: clientName,
      clientPhone: clientPhone,
    );
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

    final appointment = await _client
        .from('appointments')
        .insert({
          'workspace_id': request.workspaceId,
          'contact_id': contactId,
          if (serviceId != null) 'service_id': serviceId,
          'title': title,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'price': price,
          'status': 'scheduled',
          'notes': notes.isEmpty ? null : notes,
          if (location?.trim().isNotEmpty == true) 'location': location!.trim(),
        })
        .select('id')
        .single();

    if (createPaymentDue && price > 0) {
      final existing = await _client
          .from('invoices')
          .select('id')
          .eq('workspace_id', request.workspaceId);
      final count = List<dynamic>.from(existing).length + 1;
      final paymentNumber = 'PAY-${count.toString().padLeft(3, '0')}';
      final dateString = startTime.toIso8601String().split('T').first;
      await _client.from('invoices').insert({
        'workspace_id': request.workspaceId,
        'contact_id': contactId,
        'appointment_id': appointment['id'] as String,
        'invoice_number': paymentNumber,
        'type': 'invoice',
        'status': 'sent',
        'issue_date': dateString,
        'due_date': dateString,
        'subtotal': price,
        'tax_rate': 0,
        'tax_amount': 0,
        'discount_value': 0,
        'total': price,
        'amount_paid': 0,
        'notes': 'Payment due for $title',
      });
    }

    await updateBookingRequestStatus(request.id, 'confirmed');

    try {
      await _client.from('notifications').insert({
        'workspace_id': request.workspaceId,
        'type': 'new_booking',
        'title': 'Booking request confirmed',
        'body': '${request.name} has been added to your calendar.',
        'deep_link': '/work',
      });
    } catch (_) {
      // Confirmation should still succeed before notification tables exist.
    }
  }

  Future<String> _findOrCreateRequestContact(
    BookingRequest request, {
    String? clientName,
    String? clientPhone,
  }) async {
    final phone = clientPhone?.trim().isNotEmpty == true
        ? clientPhone!.trim()
        : request.phone.trim();
    final name = clientName?.trim().isNotEmpty == true
        ? clientName!.trim()
        : request.name.trim();
    final existing = await _client
        .from('contacts')
        .select('id')
        .eq('workspace_id', request.workspaceId)
        .eq('phone', phone)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final notes = [
      'Created from public booking request.',
      if (request.preferredTimeText?.trim().isNotEmpty == true)
        'Requested time: ${request.preferredTimeText!.trim()}',
      if (request.message?.trim().isNotEmpty == true) request.message!.trim(),
    ].join('\n\n');

    final inserted = await _client
        .from('contacts')
        .insert({
          'workspace_id': request.workspaceId,
          'name': name.isEmpty ? 'New client' : name,
          'phone': phone,
          'notes': notes,
          'status': 'active',
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<String?> _validServiceIdForRequest(BookingRequest request) async {
    final serviceId = request.serviceId;
    if (serviceId == null || serviceId.trim().isEmpty) return null;
    try {
      final service = await _client
          .from('services')
          .select('id')
          .eq('id', serviceId)
          .eq('workspace_id', request.workspaceId)
          .maybeSingle();
      return service == null ? null : serviceId;
    } catch (_) {
      return null;
    }
  }
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
