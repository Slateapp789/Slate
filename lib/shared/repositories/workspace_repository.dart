import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository(ref.watch(supabaseClientProvider));
});

class WorkspaceRepository {
  final SupabaseClient _client;
  const WorkspaceRepository(this._client);

  Future<Workspace?> currentWorkspace() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final member = await _client
        .from('workspace_members')
        .select('workspace_id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (member == null) return null;

    final workspace = await _client
        .from('workspaces')
        .select()
        .eq('id', member['workspace_id'])
        .maybeSingle();
    if (workspace == null) return null;
    return Workspace.fromMap(Map<String, dynamic>.from(workspace));
  }

  Future<void> update(String workspaceId, Map<String, dynamic> values) async {
    await _client.from('workspaces').update(values).eq('id', workspaceId);
  }
}
