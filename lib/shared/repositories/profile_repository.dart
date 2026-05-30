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
    final profile = await _client
        .from('business_profiles')
        .select(
          '*, workspaces(name, industry), workspace_settings(working_hours)',
        )
        .eq('handle', handle)
        .maybeSingle();
    if (profile == null) return null;

    final profileMap = Map<String, dynamic>.from(profile);
    final businessProfile = BusinessProfile.fromMap(profileMap);
    final workspace = Map<String, dynamic>.from(
      profileMap['workspaces'] as Map,
    );
    final settings = profileMap['workspace_settings'] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(profileMap['workspace_settings'] as Map);
    final services = await _client
        .from('services')
        .select()
        .eq('workspace_id', businessProfile.workspaceId)
        .eq('show_on_profile', true)
        .order('name', ascending: true);

    return PublicProfile(
      profile: businessProfile,
      businessName: workspace['name'] as String? ?? 'Business',
      industry: workspace['industry'] as String?,
      workingHours: Map<String, dynamic>.from(
        settings['working_hours'] as Map? ?? {},
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
    required String workspaceId,
    required String name,
    required String phone,
    String? serviceId,
    String? preferredTimeText,
    String? message,
  }) async {
    final row = {
      'workspace_id': workspaceId,
      'name': name,
      'phone': phone,
      'service_id': serviceId,
      'preferred_time_text': preferredTimeText,
      'message': message,
      'status': 'pending',
    };

    try {
      await _client.from('booking_requests').insert(row);
    } on PostgrestException catch (error) {
      if (!error.message.contains('preferred_time_text')) rethrow;
      final preferred = preferredTimeText == null || preferredTimeText.isEmpty
          ? ''
          : 'Preferred time: $preferredTimeText\n\n';
      final fallbackRow = Map<String, dynamic>.from(row)
        ..remove('preferred_time_text');
      await _client.from('booking_requests').insert({
        ...fallbackRow,
        'message': '$preferred${message ?? ''}'.trim().isEmpty
            ? null
            : '$preferred${message ?? ''}'.trim(),
      });
    }

    try {
      await _client.from('notifications').insert({
        'workspace_id': workspaceId,
        'type': 'booking_request',
        'title': 'New booking request',
        'body': '$name requested a booking.',
        'deep_link': '/booking-requests',
      });
    } catch (_) {
      // Booking requests should still work in environments before notifications are migrated.
    }
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
  }) async {
    final contactId = await _findOrCreateRequestContact(request);
    final endTime = startTime.add(Duration(minutes: durationMins));
    final title = request.serviceName?.trim().isNotEmpty == true
        ? request.serviceName!.trim()
        : 'Booking request';
    final notes = [
      if (request.preferredTimeText?.trim().isNotEmpty == true)
        'Requested time: ${request.preferredTimeText!.trim()}',
      if (request.message?.trim().isNotEmpty == true) request.message!.trim(),
    ].join('\n\n');

    await _client.from('appointments').insert({
      'workspace_id': request.workspaceId,
      'contact_id': contactId,
      if (request.serviceId != null) 'service_id': request.serviceId,
      'title': title,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'price': price,
      'status': 'scheduled',
      'notes': notes.isEmpty ? null : notes,
    });

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

  Future<String> _findOrCreateRequestContact(BookingRequest request) async {
    final existing = await _client
        .from('contacts')
        .select('id')
        .eq('workspace_id', request.workspaceId)
        .eq('phone', request.phone)
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
          'name': request.name.trim().isEmpty ? 'New client' : request.name,
          'phone': request.phone.trim(),
          'notes': notes,
          'status': 'active',
        })
        .select('id')
        .single();
    return inserted['id'] as String;
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
