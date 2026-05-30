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
    String? address,
    String? notes,
    String? importantNotes,
    String status = 'active',
    String preferredContactMethod = 'phone',
    String? source,
    DateTime? birthday,
    List<String> tags = const [],
  }) async {
    final row = await _client
        .from('contacts')
        .insert({
          'workspace_id': workspaceId,
          'name': name.trim(),
          'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
          'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
          'address': address?.trim().isEmpty ?? true ? null : address!.trim(),
          'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
          'important_notes': importantNotes?.trim().isEmpty ?? true
              ? null
              : importantNotes!.trim(),
          'status': status,
          'preferred_contact_method': preferredContactMethod,
          'source': source?.trim().isEmpty ?? true ? null : source!.trim(),
          'birthday': birthday?.toIso8601String().split('T').first,
          'tags': tags
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList(),
          'last_activity_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> update(String clientId, Map<String, dynamic> values) async {
    await _client
        .from('contacts')
        .update({
          ...values,
          'last_activity_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', clientId);
  }

  Future<void> delete(String clientId) async {
    await _client.from('contacts').delete().eq('id', clientId);
  }
}
