import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/settings/settings_screen.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';

void main() {
  test('the shipped appearance contract is dark-only', () {
    expect(AppTheme.themeMode, ThemeMode.dark);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(WorkloopThemeTokens.dark.background.toARGB32(), 0xFF151A16);
    expect(WorkloopThemeTokens.dark.surface.toARGB32(), 0xFF1C231D);
    expect(WorkloopThemeTokens.dark.accent.toARGB32(), 0xFFC1FF72);
  });

  test('native startup windows cannot fall back to a light canvas', () {
    final androidStyles = File(
      'android/app/src/main/res/values/styles.xml',
    ).readAsStringSync();
    final androidColors = File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    final iosMain = File(
      'ios/Runner/Base.lproj/Main.storyboard',
    ).readAsStringSync();

    expect(
      androidStyles,
      contains(
        '<style name="NormalTheme" '
        'parent="@android:style/Theme.Black.NoTitleBar">',
      ),
    );
    expect(
      androidStyles,
      contains(
        '<item name="android:windowBackground">'
        '@color/workloop_background</item>',
      ),
    );
    expect(androidColors, contains('#151A16'));
    expect(iosInfo, contains('<key>UIUserInterfaceStyle</key>'));
    expect(iosInfo, contains('<string>Dark</string>'));
    expect(iosMain, isNot(contains('backgroundColor" white="1"')));
  });

  test('obsolete appearance persistence and settings routes are removed', () {
    expect(
      File('lib/shared/providers/theme_mode_provider.dart').existsSync(),
      isFalse,
    );
    expect(
      File(
        'lib/features/settings/widgets/settings_appearance_view.dart',
      ).existsSync(),
      isFalse,
    );
    final settingsSource = File(
      'lib/features/settings/settings_screen.dart',
    ).readAsStringSync();
    expect(settingsSource, isNot(contains('App appearance')));
  });

  testWidgets('Settings does not offer an appearance choice', (tester) async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(client)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: AppTheme.themeMode,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('App appearance'), findsNothing);
    expect(find.text('System'), findsNothing);
    expect(find.text('Light'), findsNothing);
    expect(find.text('App preferences'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
  });
}
