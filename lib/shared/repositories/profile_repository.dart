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
    String? message,
  }) async {
    await _client.from('booking_requests').insert({
      'workspace_id': workspaceId,
      'name': name,
      'phone': phone,
      'service_id': serviceId,
      'message': message,
      'status': 'pending',
    });
  }

  Future<List<BookingRequest>> bookingRequests(String workspaceId) async {
    final rows = await _client
        .from('booking_requests')
        .select()
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
