import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

class DashboardRepository {
  final SupabaseClient _client;
  const DashboardRepository(this._client);

  Future<List<Map<String, dynamic>>> invoiceTotals({
    required String workspaceId,
    required String status,
    String? issueDateFrom,
    List<String>? statuses,
  }) async {
    var query = _client
        .from('invoices')
        .select('total')
        .eq('workspace_id', workspaceId);
    if (statuses != null) {
      query = query.inFilter('status', statuses);
    } else {
      query = query.eq('status', status);
    }
    if (issueDateFrom != null) {
      query = query.gte('issue_date', issueDateFrom);
    }
    final rows = await query;
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<double> revenueTarget(String workspaceId) async {
    final settings = await _client
        .from('workspace_settings')
        .select('revenue_target')
        .eq('workspace_id', workspaceId)
        .maybeSingle();
    return (settings?['revenue_target'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> todayAppointments({
    required String workspaceId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _client
        .from('appointments')
        .select('*, contacts(name), services(name)')
        .eq('workspace_id', workspaceId)
        .gte('start_time', start.toUtc().toIso8601String())
        .lt('start_time', end.toUtc().toIso8601String())
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> upcomingAppointmentIds({
    required String workspaceId,
    required DateTime from,
  }) async {
    final rows = await _client
        .from('appointments')
        .select('id')
        .eq('workspace_id', workspaceId)
        .gte('start_time', from.toUtc().toIso8601String())
        .neq('status', 'cancelled');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> overduePaymentIds(
    String workspaceId,
  ) async {
    final rows = await _client
        .from('invoices')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('status', 'overdue');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> monthlyAppointmentSignals({
    required String workspaceId,
    required String monthStart,
  }) async {
    final rows = await _client
        .from('appointments')
        .select('contact_id,start_time')
        .eq('workspace_id', workspaceId)
        .gte('start_time', monthStart)
        .neq('status', 'cancelled');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<int> pendingBookingRequests(String workspaceId) async {
    final rows = await _client
        .from('booking_requests')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('status', 'pending');
    return List<Map<String, dynamic>>.from(rows).length;
  }
}
