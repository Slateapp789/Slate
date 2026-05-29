import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(ref.watch(supabaseClientProvider));
});

class ServicesRepository {
  final SupabaseClient _client;
  const ServicesRepository(this._client);

  Future<List<Map<String, dynamic>>> listRows(String workspaceId) async {
    final rows = await _client
        .from('services')
        .select()
        .eq('workspace_id', workspaceId)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> create({
    required String workspaceId,
    required String name,
    required double price,
    required int durationMins,
    String? description,
    bool showOnProfile = true,
    bool active = true,
  }) async {
    await _client.from('services').insert({
      'workspace_id': workspaceId,
      'name': name.trim(),
      'price': price,
      'duration_mins': durationMins,
      'description': description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      'show_on_profile': showOnProfile,
      'active': active,
    });
  }

  Future<void> update(String serviceId, Map<String, dynamic> values) async {
    await _client.from('services').update(values).eq('id', serviceId);
  }

  Future<void> delete(String serviceId) async {
    await _client.from('services').delete().eq('id', serviceId);
  }
}
