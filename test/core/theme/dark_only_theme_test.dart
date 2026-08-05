import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/settings/settings_screen.dart';
import 'package:workloop/shared/providers/theme_mode_provider.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';

class _MemoryThemeModeStore implements ThemeModeStore {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }
}

void main() {
  test('Workloop ships coordinated light and dark theme contracts', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(WorkloopThemeTokens.light.background.toARGB32(), 0xFFEEEDE8);
    expect(WorkloopThemeTokens.dark.background.toARGB32(), 0xFF151A16);
    expect(WorkloopThemeTokens.light.accent.toARGB32(), 0xFFC1FF72);
    expect(WorkloopThemeTokens.dark.accent.toARGB32(), 0xFFC1FF72);
  });

  test('native startup windows allow the operating-system appearance', () {
    final androidStyles = File(
      'android/app/src/main/res/values/styles.xml',
    ).readAsStringSync();
    final androidNightStyles = File(
      'android/app/src/main/res/values-night/styles.xml',
    ).readAsStringSync();
    final androidColors = File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsStringSync();
    final androidNightColors = File(
      'android/app/src/main/res/values-night/colors.xml',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    expect(androidStyles, contains('Theme.Light.NoTitleBar'));
    expect(androidNightStyles, contains('Theme.Black.NoTitleBar'));
    expect(androidColors, contains('#EEEDE8'));
    expect(androidNightColors, contains('#151A16'));
    expect(iosInfo, isNot(contains('<key>UIUserInterfaceStyle</key>')));
  });

  testWidgets('Settings exposes persisted System, Light, and Dark choices', (
    tester,
  ) async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final store = _MemoryThemeModeStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(client)),
          themeModeStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('App appearance'), findsOneWidget);
    await tester.tap(find.text('App appearance'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('appearance-system')), findsOneWidget);
    expect(find.byKey(const ValueKey('appearance-light')), findsOneWidget);
    expect(find.byKey(const ValueKey('appearance-dark')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('appearance-light')));
    await tester.pumpAndSettle();

    expect(store.value, WorkloopAppearance.light.name);
  });
}
