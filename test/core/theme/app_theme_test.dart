import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';

void main() {
  tearDown(() => WorkloopLegacyPalette.sync(Brightness.light));

  test('brand accent is the approved Workloop lime in both themes', () {
    expect(AppColors.brandAccent.toARGB32(), 0xFFC1FF72);
    expect(WorkloopThemeTokens.light.accent.toARGB32(), 0xFFC1FF72);
    expect(WorkloopThemeTokens.dark.accent.toARGB32(), 0xFFC1FF72);
  });

  test('legacy semantic colours resolve against the active brightness', () {
    WorkloopLegacyPalette.sync(Brightness.light);
    expect(AppColors.bg.toARGB32(), 0xFFFFFFFF);
    expect(AppColors.t1.toARGB32(), 0xFF11130F);

    WorkloopLegacyPalette.sync(Brightness.dark);
    expect(AppColors.bg.toARGB32(), 0xFF050604);
    expect(AppColors.t1.toARGB32(), 0xFFF7F8F3);
    expect(AppColors.accentInk.toARGB32(), 0xFFC1FF72);
  });
}
