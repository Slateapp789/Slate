import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';

void main() {
  test('Studio indigo remains exact and readable in both appearances', () {
    WorkloopLegacyPalette.sync(Brightness.light);
    expect(AppColors.brandAccent.toARGB32(), 0xFF4F46E5);
    expect(WorkloopThemeTokens.light.accent.toARGB32(), 0xFF4F46E5);
    WorkloopLegacyPalette.sync(Brightness.dark);
    expect(AppColors.brandAccent.toARGB32(), 0xFF9496E8);
    expect(WorkloopThemeTokens.dark.accent.toARGB32(), 0xFF9496E8);
    expect(WorkloopThemeTokens.dark.accentStrong.toARGB32(), 0xFF7D80D4);
    expect(
      _contrastRatio(AppColors.onBrandAccent, AppColors.brandAccent),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('dark midnight layers stay distinct', () {
    const tokens = WorkloopThemeTokens.dark;

    expect(tokens.background.toARGB32(), 0xFF111318);
    expect(tokens.surface.toARGB32(), 0xFF1C2027);
    expect(tokens.surfaceRaised.toARGB32(), 0xFF252A33);
    expect(tokens.surfaceSubtle.toARGB32(), 0xFF2E343F);
    expect(
      tokens.background.computeLuminance(),
      lessThan(tokens.surface.computeLuminance()),
    );
    expect(
      tokens.surface.computeLuminance(),
      lessThan(tokens.surfaceRaised.computeLuminance()),
    );
    expect(
      tokens.surfaceRaised.computeLuminance(),
      lessThan(tokens.surfaceSubtle.computeLuminance()),
    );
  });

  test('light layers are crisp, low-glare, and quietly distinct', () {
    const tokens = WorkloopThemeTokens.light;

    expect(tokens.background.computeLuminance(), lessThan(0.95));
    expect(tokens.background, isNot(tokens.surface));
    expect(tokens.surface, isNot(tokens.surfaceRaised));
    expect(tokens.surfaceRaised, isNot(tokens.surfaceSubtle));
    expect(
      _contrastRatio(tokens.surface, tokens.background),
      greaterThanOrEqualTo(1.05),
    );
    expect(
      _contrastRatio(tokens.surfaceRaised, tokens.background),
      greaterThanOrEqualTo(1.04),
    );
    expect(_contrastRatio(tokens.divider, tokens.surface), greaterThan(1.25));
    expect(
      _contrastRatio(tokens.dividerStrong, tokens.surface),
      greaterThanOrEqualTo(1.5),
    );
  });

  test('legacy colour aliases follow the effective appearance', () {
    WorkloopLegacyPalette.sync(Brightness.dark);
    expect(
      AppColors.bg.toARGB32(),
      WorkloopThemeTokens.dark.background.toARGB32(),
    );
    expect(
      AppColors.t1.toARGB32(),
      WorkloopThemeTokens.dark.textPrimary.toARGB32(),
    );

    WorkloopLegacyPalette.sync(Brightness.light);
    expect(
      AppColors.bg.toARGB32(),
      WorkloopThemeTokens.light.background.toARGB32(),
    );
    expect(
      AppColors.accentInk.toARGB32(),
      WorkloopThemeTokens.light.accentInk.toARGB32(),
    );
    expect(
      AppColors.accentBorder.toARGB32(),
      WorkloopThemeTokens.light.accentBorder.toARGB32(),
    );
    expect(AppColors.panelInk, AppColors.onBrandAccent);

    addTearDown(() => WorkloopLegacyPalette.sync(Brightness.dark));
  });

  test('legacy colours resolve manual and system appearance atomically', () {
    const cases = <(ThemeMode, Brightness, Brightness)>[
      (ThemeMode.light, Brightness.dark, Brightness.light),
      (ThemeMode.dark, Brightness.light, Brightness.dark),
      (ThemeMode.system, Brightness.light, Brightness.light),
      (ThemeMode.system, Brightness.dark, Brightness.dark),
    ];

    for (final entry in cases) {
      final effectiveBrightness = WorkloopLegacyPalette.resolve(
        themeMode: entry.$1,
        platformBrightness: entry.$2,
      );
      WorkloopLegacyPalette.sync(effectiveBrightness);

      expect(effectiveBrightness, entry.$3);
      expect(
        AppColors.modBg.toARGB32(),
        (entry.$3 == Brightness.dark
                ? WorkloopThemeTokens.dark.surfaceRaised
                : WorkloopThemeTokens.light.surfaceRaised)
            .toARGB32(),
      );
      expect(
        AppColors.t2.toARGB32(),
        (entry.$3 == Brightness.dark
                ? WorkloopThemeTokens.dark.textSecondary
                : WorkloopThemeTokens.light.textSecondary)
            .toARGB32(),
      );
    }

    addTearDown(() => WorkloopLegacyPalette.sync(Brightness.dark));
  });

  test('semantic text roles meet contrast targets in both appearances', () {
    for (final tokens in [
      WorkloopThemeTokens.light,
      WorkloopThemeTokens.dark,
    ]) {
      for (final color in [
        tokens.textPrimary,
        tokens.textSecondary,
        tokens.accentInk,
      ]) {
        expect(
          _contrastRatio(color, tokens.background),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        _contrastRatio(tokens.textTertiary, tokens.background),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrastRatio(tokens.textDisabled, tokens.background),
        greaterThan(2),
      );
      expect(
        _contrastRatio(tokens.onAccent, tokens.accentStrong),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('feature surfaces stay readable in both appearances', () {
    for (final tokens in [
      WorkloopThemeTokens.light,
      WorkloopThemeTokens.dark,
    ]) {
      expect(
        _contrastRatio(tokens.onInk, tokens.inkSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(tokens.onInkMuted, tokens.inkSurface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('focus indicators remain visible against Studio surfaces', () {
    for (final entry in [
      (AppTheme.light, WorkloopThemeTokens.light),
      (AppTheme.dark, WorkloopThemeTokens.dark),
    ]) {
      final border =
          entry.$1.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(border.borderSide.color, entry.$2.accent);
      expect(
        _contrastRatio(border.borderSide.color, entry.$2.surface),
        greaterThanOrEqualTo(3),
      );
    }
  });

  test('primary actions use one readable ink-or-brand treatment', () {
    for (final entry in [
      (AppTheme.light, WorkloopThemeTokens.light),
      (AppTheme.dark, WorkloopThemeTokens.dark),
    ]) {
      expect(
        _contrastRatio(entry.$2.onPrimaryAction, entry.$2.primaryAction),
        greaterThanOrEqualTo(4.5),
      );
      final elevatedSide = entry.$1.elevatedButtonTheme.style?.side?.resolve(
        {},
      );
      final filledSide = entry.$1.filledButtonTheme.style?.side?.resolve({});
      expect(elevatedSide?.color, entry.$2.primaryAction);
      expect(elevatedSide?.width, 1);
      expect(filledSide?.color, entry.$2.primaryAction);
      expect(filledSide?.width, 1);
    }
  });

  test('module and semantic foregrounds stay legible in both appearances', () {
    for (final entry in [
      (Brightness.light, WorkloopThemeTokens.light),
      (Brightness.dark, WorkloopThemeTokens.dark),
    ]) {
      WorkloopLegacyPalette.sync(entry.$1);
      for (final color in [
        AppColors.modHome,
        AppColors.modClients,
        AppColors.modCalendar,
        AppColors.modFinance,
        AppColors.modTasks,
        AppColors.modNotes,
      ]) {
        expect(
          _contrastRatio(color, entry.$2.surface),
          greaterThanOrEqualTo(3),
        );
      }
      for (final color in [
        AppColors.statusSuccess,
        AppColors.warning,
        AppColors.error,
      ]) {
        expect(
          _contrastRatio(color, entry.$2.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
    addTearDown(() => WorkloopLegacyPalette.sync(Brightness.dark));
  });

  test('Home hero roles remain readable across both gradient endpoints', () {
    for (final tokens in [
      WorkloopThemeTokens.light,
      WorkloopThemeTokens.dark,
    ]) {
      for (final background in [
        tokens.heroGradientStart,
        tokens.heroGradientEnd,
      ]) {
        for (final foreground in [
          tokens.onHeroPrimary,
          tokens.onHeroSecondary,
          tokens.onHeroMuted,
        ]) {
          expect(
            _contrastRatio(
              Color.alphaBlend(foreground, background),
              background,
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
      expect(
        _contrastRatio(tokens.heroActionForeground, tokens.onHeroPrimary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets(
    'shell clearance includes navigation, safe area, and breathing room',
    (tester) async {
      late double clearance;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
            child: Builder(
              builder: (context) {
                clearance = AppSpacing.shellBottomClearance(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(clearance, 128);
    },
  );

  test('interactive controls keep the Workloop typeface', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final styles = [
        theme.elevatedButtonTheme.style,
        theme.filledButtonTheme.style,
        theme.textButtonTheme.style,
        theme.outlinedButtonTheme.style,
      ];
      for (final style in styles) {
        expect(style?.textStyle?.resolve({})?.fontFamily, 'Manrope');
      }
    }
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
