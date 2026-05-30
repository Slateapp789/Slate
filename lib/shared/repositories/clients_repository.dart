import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepository(ref.watch(supabaseClientProvider));
});

class ClientsRepository {
  final SupabaseClient _client;
  const ClientsRepository(this._client);

  Future<List<Client>> list(String workspaceId) async {
    final rows = await _client
        .from('contacts')
        .select()
        .eq('workspace_id', workspaceId)
        .order('name', ascending: true);
    return rows
        .map<Client>((row) => Client.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Client?> getById(String id) async {
    final row = await _client
        .from('contacts')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Client.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> create({
    required String workspaceId,
    required String name,
    String? phone,
    String? email,
    String? notes,
    String status = 'active',
  }) async {
    final row = await _client
        .from('contacts')
        .insert({
          'workspace_id': workspaceId,
          'name': name.trim(),
          'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
          'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
          'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
          'status': status,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> update(String clientId, Map<String, dynamic> values) async {
    await _client.from('contacts').update(values).eq('id', clientId);
  }

  Future<void> delete(String clientId) async {
    await _client.from('contacts').delete().eq('id', clientId);
  }
}
