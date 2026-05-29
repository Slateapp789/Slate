import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Run Flutter with '
        '--dart-define-from-file=.env or provide SUPABASE_URL and '
        'SUPABASE_ANON_KEY as dart-defines.',
      );
    }
  }
}
