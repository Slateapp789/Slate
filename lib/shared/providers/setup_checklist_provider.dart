import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final setupChecklistDismissedProvider = FutureProvider<bool>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;
  return await SharedPreferencesAsync().getBool(_key(userId)) ?? false;
});

Future<void> dismissSetupChecklist(WidgetRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  await SharedPreferencesAsync().setBool(_key(userId), true);
  ref.invalidate(setupChecklistDismissedProvider);
}

String _key(String userId) => 'workloop.setup-checklist.dismissed.$userId';
