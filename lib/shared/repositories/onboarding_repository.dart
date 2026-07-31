import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(supabaseClientProvider));
});

class OnboardingRepository {
  final SupabaseClient _client;
  const OnboardingRepository(this._client);

  Future<String?> complete({
    required String firstName,
    required String businessName,
    required String industry,
    required String handle,
    required List<Map<String, dynamic>> services,
    required Map<String, dynamic> workingHours,
    required double revenueTarget,
    Map<String, dynamic>? firstBooking,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final workspaceId = await _client.rpc(
      'complete_onboarding',
      params: buildOnboardingRpcParams(
        businessName: businessName,
        industry: industry,
        handle: handle,
        services: services,
        workingHours: workingHours,
        revenueTarget: revenueTarget,
        firstBooking: firstBooking,
      ),
    );

    if (workspaceId == null || workspaceId.toString().trim().isEmpty) {
      throw StateError('Workspace was not created');
    }

    // Profile metadata is outside the workspace transaction. Perform it after
    // the idempotent RPC so a transient auth failure can safely be retried
    // without creating another workspace.
    await _client.auth.updateUser(
      UserAttributes(data: {'first_name': firstName.trim()}),
    );

    return workspaceId.toString();
  }
}

Map<String, dynamic> buildOnboardingRpcParams({
  required String businessName,
  required String industry,
  required String handle,
  required List<Map<String, dynamic>> services,
  required Map<String, dynamic> workingHours,
  required double revenueTarget,
  Map<String, dynamic>? firstBooking,
}) {
  final serviceRows = services
      .map(
        (service) => <String, dynamic>{
          'name': service['name']?.toString().trim(),
          'duration_mins': (service['duration'] as num?)?.toInt() ?? 60,
          'price': (service['price'] as num?)?.toDouble() ?? 0,
        },
      )
      .toList(growable: false);

  Map<String, dynamic>? firstBookingValue;
  if (firstBooking != null) {
    final dateParts = (firstBooking['date'] as String).split('-');
    final serviceName = firstBooking['serviceName']?.toString().trim();
    final matchingService = serviceRows
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (service) => service?['name'] == serviceName,
          orElse: () => null,
        );
    final durationMins =
        (matchingService?['duration_mins'] as num?)?.toInt() ?? 60;
    final start = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      (firstBooking['hour'] as num).toInt(),
      (firstBooking['minute'] as num).toInt(),
    );
    firstBookingValue = {
      'client_name': firstBooking['clientName']?.toString().trim(),
      'service_name': serviceName,
      'start_time': start.toUtc().toIso8601String(),
      'end_time': start
          .add(Duration(minutes: durationMins))
          .toUtc()
          .toIso8601String(),
    };
  }

  return {
    'business_name': businessName.trim(),
    'industry_name': industry.trim(),
    'profile_handle': handle.trim().toLowerCase(),
    'service_rows': serviceRows,
    'working_hours_value': workingHours,
    'revenue_target_value': revenueTarget,
    'first_booking_value': firstBookingValue,
  };
}
