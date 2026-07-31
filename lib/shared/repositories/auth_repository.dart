import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

const workloopPasswordRecoveryRedirect = 'workloop://reset-password';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

String? firstNameFromUserMetadata(Map<String, dynamic>? metadata) {
  for (final key in const ['first_name', 'full_name', 'display_name', 'name']) {
    final value = metadata?[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value.split(RegExp(r'\s+')).first;
    }
  }
  return null;
}

class AuthRepository {
  final SupabaseClient _client;
  const AuthRepository(this._client);

  String get currentEmail => _client.auth.currentUser?.email ?? '—';

  String? get currentFirstName =>
      firstNameFromUserMetadata(_client.auth.currentUser?.userMetadata);

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: workloopPasswordRecoveryRedirect,
    );
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> updateFirstName(String firstName) async {
    final value = firstName.trim();
    if (value.isEmpty) return;
    await _client.auth.updateUser(UserAttributes(data: {'first_name': value}));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
