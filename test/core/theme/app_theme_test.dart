import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';

void main() {
  test('brand accent remains exact and readable in the dark-only theme', () {
    expect(AppColors.brandAccent.toARGB32(), 0xFFC1FF72);
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

  test('legacy colour aliases resolve to the one shipped palette', () {
    const tokens = WorkloopThemeTokens.dark;

    expect(AppColors.bg, tokens.background);
    expect(AppColors.bgCard, tokens.surface);
    expect(AppColors.bgRaised, tokens.surfaceRaised);
    expect(AppColors.bgInteract, tokens.surfaceSubtle);
    expect(AppColors.t1, tokens.textPrimary);
    expect(AppColors.accentInk, tokens.accentInk);
    expect(AppColors.panelInk, AppColors.onBrandAccent);
  });

  test('dark semantic text roles meet contrast targets', () {
    const tokens = WorkloopThemeTokens.dark;
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
  });

  test('focus indicators remain visible without diluting the neon fill', () {
    final border =
        AppTheme.dark.inputDecorationTheme.focusedBorder as OutlineInputBorder;

    expect(border.borderSide.color, WorkloopThemeTokens.dark.accentInk);
    expect(
      _contrastRatio(border.borderSide.color, WorkloopThemeTokens.dark.surface),
      greaterThanOrEqualTo(3),
    );
  });

  test('interactive controls keep the Workloop typeface', () {
    final theme = AppTheme.dark;
    final styles = [
      theme.elevatedButtonTheme.style,
      theme.filledButtonTheme.style,
      theme.textButtonTheme.style,
      theme.outlinedButtonTheme.style,
    ];
    for (final style in styles) {
      expect(style?.textStyle?.resolve({})?.fontFamily, 'Instrument Sans');
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
