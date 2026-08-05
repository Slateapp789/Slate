import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';

void main() {
  test('brand accent remains exact and readable in both appearances', () {
    expect(AppColors.brandAccent.toARGB32(), 0xFFC1FF72);
    expect(WorkloopThemeTokens.light.accent.toARGB32(), 0xFFC1FF72);
    expect(WorkloopThemeTokens.dark.accent.toARGB32(), 0xFFC1FF72);
    expect(WorkloopThemeTokens.dark.accentStrong.toARGB32(), 0xFFC1FF72);
    expect(
      _contrastRatio(AppColors.onBrandAccent, AppColors.brandAccent),
      greaterThanOrEqualTo(4.5),
    );
  });

  test(
    'dark graphite layers stay distinct without returning to near-black',
    () {
      const tokens = WorkloopThemeTokens.dark;

      expect(tokens.background.toARGB32(), 0xFF151A16);
      expect(tokens.surface.toARGB32(), 0xFF1C231D);
      expect(tokens.surfaceRaised.toARGB32(), 0xFF252E26);
      expect(tokens.surfaceSubtle.toARGB32(), 0xFF2C372D);
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
    },
  );

  test('light layers are warm, low-glare, and visibly distinct', () {
    const tokens = WorkloopThemeTokens.light;

    expect(tokens.background.computeLuminance(), lessThan(0.9));
    expect(tokens.background, isNot(tokens.surface));
    expect(tokens.surface, isNot(tokens.surfaceRaised));
    expect(tokens.surfaceRaised, isNot(tokens.surfaceSubtle));
    expect(
      _contrastRatio(tokens.surface, tokens.background),
      greaterThanOrEqualTo(1.15),
    );
    expect(
      _contrastRatio(tokens.surfaceRaised, tokens.background),
      greaterThanOrEqualTo(1.08),
    );
    expect(_contrastRatio(tokens.divider, tokens.surface), greaterThan(1.5));
    expect(
      _contrastRatio(tokens.dividerStrong, tokens.surface),
      greaterThanOrEqualTo(2.5),
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

  test('semantic text roles meet contrast targets in both appearances', () {
    for (final tokens in [
      WorkloopThemeTokens.light,
      WorkloopThemeTokens.dark,
    ]) {
      for (final color in [
        tokens.textPrimary,
        tokens.textSecondary,
        tokens.textTertiary,
        tokens.accentInk,
      ]) {
        expect(
          _contrastRatio(color, tokens.background),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        _contrastRatio(tokens.textDisabled, tokens.background),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrastRatio(tokens.onAccent, tokens.accentStrong),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('focus indicators remain visible without diluting the neon fill', () {
    for (final entry in [
      (AppTheme.light, WorkloopThemeTokens.light),
      (AppTheme.dark, WorkloopThemeTokens.dark),
    ]) {
      final border =
          entry.$1.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(border.borderSide.color, entry.$2.accentInk);
      expect(
        _contrastRatio(border.borderSide.color, entry.$2.surface),
        greaterThanOrEqualTo(3),
      );
    }
  });

  test('accent fills use a visible one-pixel semantic border', () {
    for (final entry in [
      (AppTheme.light, WorkloopThemeTokens.light),
      (AppTheme.dark, WorkloopThemeTokens.dark),
    ]) {
      if (entry.$1.brightness == Brightness.light) {
        expect(
          _contrastRatio(entry.$2.accentBorder, entry.$2.accentStrong),
          greaterThanOrEqualTo(1.5),
        );
      }
      final elevatedSide = entry.$1.elevatedButtonTheme.style?.side?.resolve(
        {},
      );
      final filledSide = entry.$1.filledButtonTheme.style?.side?.resolve({});
      expect(elevatedSide?.color, entry.$2.accentBorder);
      expect(elevatedSide?.width, 1);
      expect(filledSide?.color, entry.$2.accentBorder);
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

  test('interactive controls keep the Workloop typeface', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final styles = [
        theme.elevatedButtonTheme.style,
        theme.filledButtonTheme.style,
        theme.textButtonTheme.style,
        theme.outlinedButtonTheme.style,
      ];
      for (final style in styles) {
        expect(style?.textStyle?.resolve({})?.fontFamily, 'Instrument Sans');
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
