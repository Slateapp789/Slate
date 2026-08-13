import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
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
    expect(WorkloopThemeTokens.light.background.toARGB32(), 0xFFF6F4EF);
    expect(WorkloopThemeTokens.dark.background.toARGB32(), 0xFF111318);
    expect(WorkloopThemeTokens.light.accent.toARGB32(), 0xFF4F46E5);
    expect(WorkloopThemeTokens.dark.accent.toARGB32(), 0xFF9496E8);
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
    expect(androidColors, contains('#F6F4EF'));
    expect(androidColors, contains('#6362EB'));
    expect(androidNightColors, contains('#111318'));
    expect(androidNightColors, contains('#6362EB'));
    expect(
      File(
        'android/app/src/main/res/drawable/launch_background.xml',
      ).readAsStringSync(),
      contains('@drawable/launch_image'),
    );
    expect(
      File('ios/Runner/Base.lproj/LaunchScreen.storyboard').readAsStringSync(),
      contains('image="LaunchImage"'),
    );
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      ).lengthSync(),
      greaterThan(1000),
    );
    for (final path in [
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
      'android/app/src/main/res/drawable-mdpi/launch_image.png',
    ]) {
      final bytes = File(path).readAsBytesSync();
      expect(
        bytes[25],
        anyOf(4, 6),
        reason: '$path must use PNG alpha over one native splash background',
      );
    }
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

  testWidgets('Settings icon surfaces change appearance in the first frame', (
    tester,
  ) async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final store = _MemoryThemeModeStore();
    var themeMode = ThemeMode.light;
    late StateSetter setThemeMode;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(client)),
          themeModeStoreProvider.overrideWithValue(store),
        ],
        child: StatefulBuilder(
          builder: (context, setState) {
            setThemeMode = setState;
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              themeAnimationDuration: Duration.zero,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color iconSurface(String key) {
      final container = tester.widget<Container>(find.byKey(ValueKey(key)));
      return (container.decoration! as BoxDecoration).color!;
    }

    final appearanceIconKey =
        'settings-row-icon-${LucideIcons.sunMoon.codePoint}';
    expect(
      iconSurface(appearanceIconKey),
      WorkloopThemeTokens.light.surfaceRaised,
    );
    expect(
      iconSurface('settings-account-avatar'),
      WorkloopThemeTokens.light.surfaceRaised,
    );

    setThemeMode(() => themeMode = ThemeMode.dark);
    await tester.pump();

    expect(
      iconSurface(appearanceIconKey),
      WorkloopThemeTokens.dark.surfaceRaised,
    );
    expect(
      iconSurface('settings-account-avatar'),
      WorkloopThemeTokens.dark.surfaceRaised,
    );
  });
}
