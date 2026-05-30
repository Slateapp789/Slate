import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(supabaseClientProvider));
});

class OnboardingRepository {
  final SupabaseClient _client;
  const OnboardingRepository(this._client);

  Future<void> complete({
    required String businessName,
    required String industry,
    required String handle,
    required List<Map<String, dynamic>> services,
    required Map<String, dynamic> workingHours,
    required double revenueTarget,
    Map<String, dynamic>? firstBooking,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final workspace = await _client
        .from('workspaces')
        .insert({'name': businessName, 'industry': industry})
        .select()
        .single();
    final workspaceId = workspace['id'] as String;

    await _client.from('workspace_members').insert({
      'workspace_id': workspaceId,
      'user_id': user.id,
    });

    await _client.from('workspace_settings').insert({
      'workspace_id': workspaceId,
      'working_hours': workingHours,
      'revenue_target': revenueTarget,
    });

    await _client.from('business_profiles').insert({
      'workspace_id': workspaceId,
      'handle': handle,
    });

    var insertedServices = <Map<String, dynamic>>[];
    if (services.isNotEmpty) {
      final result = await _client
          .from('services')
          .insert(
            services
                .map(
                  (service) => {
                    'workspace_id': workspaceId,
                    'name': service['name'],
                    'duration_mins': service['duration'],
                    'price': service['price'],
                  },
                )
                .toList(),
          )
          .select();
      insertedServices = List<Map<String, dynamic>>.from(result);
    }

    if (firstBooking == null) return;

    final contactResult = await _client
        .from('contacts')
        .insert({
          'workspace_id': workspaceId,
          'name': firstBooking['clientName'] as String,
          'status': 'active',
        })
        .select()
        .single();
    final contactId = contactResult['id'] as String;

    final serviceName = firstBooking['serviceName'] as String?;
    final matchedService = insertedServices.firstWhere(
      (service) => service['name'] == serviceName,
      orElse: () => <String, dynamic>{},
    );
    final serviceId = matchedService['id'] as String?;
    final durationMins =
        (matchedService['duration_mins'] as num?)?.toInt() ?? 60;
    final price = (matchedService['price'] as num?)?.toDouble() ?? 0;

    final dateStr = firstBooking['date'] as String;
    final dateParts = dateStr.split('-');
    final startTime = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      firstBooking['hour'] as int,
      firstBooking['minute'] as int,
    );
    final endTime = startTime.add(Duration(minutes: durationMins));

    await _client.from('appointments').insert({
      'workspace_id': workspaceId,
      'contact_id': contactId,
      if (serviceId != null) 'service_id': serviceId,
      'title': serviceName ?? 'Booking',
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'price': price,
      'status': 'scheduled',
    });
  }
}
