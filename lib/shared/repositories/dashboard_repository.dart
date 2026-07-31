import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_pagination.dart';
import 'supabase_client_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

class DashboardRepository {
  final SupabaseClient _client;
  const DashboardRepository(this._client);

  Future<List<Map<String, dynamic>>> todayAppointments({
    required String workspaceId,
    required DateTime start,
    required DateTime end,
  }) async {
    return fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('appointments')
            .select('*, contacts(name), services(name)')
            .eq('workspace_id', workspaceId)
            .gte('start_time', start.toUtc().toIso8601String())
            .lt('start_time', end.toUtc().toIso8601String())
            .order('start_time', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
  }

  Future<Map<String, dynamic>?> nextAppointment({
    required String workspaceId,
    required DateTime from,
  }) async {
    final row = await _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .gte('start_time', from.toUtc().toIso8601String())
        .neq('status', 'cancelled')
        .order('start_time', ascending: true)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<int> pendingBookingRequests(String workspaceId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('booking_requests')
            .select('id')
            .eq('workspace_id', workspaceId)
            .eq('status', 'pending')
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.length;
  }
}
