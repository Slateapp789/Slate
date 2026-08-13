import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

const workloopPasswordRecoveryRedirect = 'workloop://reset-password';
const workloopOAuthRedirect = 'workloop://auth-callback';

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
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: kIsWeb ? null : workloopOAuthRedirect,
    );
  }

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : workloopOAuthRedirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('Apple did not return an identity token.');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    final nameParts = <String>[
      if (credential.givenName?.trim().isNotEmpty ?? false)
        credential.givenName!.trim(),
      if (credential.familyName?.trim().isNotEmpty ?? false)
        credential.familyName!.trim(),
    ];
    if (nameParts.isNotEmpty) {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'first_name': nameParts.first,
            'full_name': nameParts.join(' '),
            'given_name': credential.givenName?.trim(),
            'family_name': credential.familyName?.trim(),
          },
        ),
      );
    }
    return response;
  }

  Future<MfaSecurityState> getMfaSecurityState() async {
    final factors = await _client.auth.mfa.listFactors();
    final assurance = _client.auth.mfa.getAuthenticatorAssuranceLevel();
    return MfaSecurityState(
      factors: factors.totp,
      currentLevel: assurance.currentLevel,
      nextLevel: assurance.nextLevel,
    );
  }

  Future<AuthMFAEnrollResponse> enrollTotp() {
    return _client.auth.mfa.enroll(
      factorType: FactorType.totp,
      issuer: 'Workloop',
      friendlyName: 'Authenticator app',
    );
  }

  Future<void> verifyTotp({
    required String factorId,
    required String code,
  }) async {
    await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code);
  }

  Future<void> removeMfaFactor(String factorId) async {
    await _client.auth.mfa.unenroll(factorId);
    await _client.auth.refreshSession();
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: workloopPasswordRecoveryRedirect,
    );
  }

  Future<void> requestPasswordReauthentication() {
    return _client.auth.reauthenticate();
  }

  Future<void> updatePassword(String password, {String? nonce}) async {
    await _client.auth.updateUser(
      UserAttributes(password: password, nonce: nonce),
    );
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

class MfaSecurityState {
  final List<Factor> factors;
  final AuthenticatorAssuranceLevels? currentLevel;
  final AuthenticatorAssuranceLevels? nextLevel;

  const MfaSecurityState({
    required this.factors,
    required this.currentLevel,
    required this.nextLevel,
  });

  bool get isEnabled => factors.isNotEmpty;

  bool get needsChallenge =>
      currentLevel == AuthenticatorAssuranceLevels.aal1 &&
      nextLevel == AuthenticatorAssuranceLevels.aal2;
}
