import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String _legacyAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static String get supabasePublishableKey => _supabasePublishableKey.isNotEmpty
      ? _supabasePublishableKey
      : _legacyAnonKey;

  static SupabaseClient get client => Supabase.instance.client;

  static void validate() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Run Flutter with '
        '--dart-define-from-file=.env or provide SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY as dart-defines. SUPABASE_ANON_KEY is '
        'accepted temporarily for legacy environments.',
      );
    }
  }
}
