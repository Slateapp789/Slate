import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds - layered charcoal / graphite
  static const bg = Color(0xFF1B1F23);
  static const bgCard = Color(0xFF252A2F);
  static const bgRaised = Color(0xFF30363D);
  static const bgInteract = Color(0xFF3A424A);
  static const border = Color(0xFF4C5660);
  static const borderStrong = Color(0xFF66717C);

  // Text
  static const t1 = Color(0xFFF0F2F3);
  static const t2 = Color(0xBFEFF2F4);
  static const t3 = Color(0x73EFF2F4);
  static const t4 = Color(0x36EFF2F4);

  // Accent — Slate steel. Kept as green aliases during migration.
  static const slate = Color(0xFF9AA8B6);
  static const slateLight = Color(0xFFC3CBD2);
  static const slateDim = Color(0x268FA3B8);
  static const slateGlow = Color(0x668FA3B8);
  static const green = slate;
  static const greenLight = slateLight;
  static const greenDim = slateDim;
  static const greenGlow = slateGlow;

  // Aliases so existing code doesn't break
  static const violet = slate;
  static const violetDim = slateDim;
  static const violetGlow = slateGlow;

  // Semantic
  static const success = Color(0xFF79A887);
  static const successDim = Color(0x1F79A887);
  static const warning = Color(0xFFC2A36B);
  static const warningDim = Color(0x1FC2A36B);
  static const error = Color(0xFFD16F6F);
  static const errorDim = Color(0x1FD16F6F);

  // Module colours — slate monotone
  static const modClients = Color(0xDDE4E8EC);
  static const modCalendar = Color(0xCCCAD2D9);
  static const modFinance = Color(0xCCB4C0CC);
  static const modTasks = Color(0xCCA1ADB8);

  // Module icon backgrounds — subtle grey
  static const modBg = bgInteract;

  // Soft light panels used sparingly inside the dark grey app shell.
  static const panelSoft = Color(0xFFD3D7DB);
  static const panelSoftRaised = Color(0xFFC2C8CE);
  static const panelInk = Color(0xFF252A2F);
  static const panelMuted = Color(0x99252A2F);
  static const panelFaint = Color(0x26252A2F);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.green,
        surface: AppColors.bgCard,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: -3.0,
            color: AppColors.t1,
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: AppColors.t1,
          ),
          headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: AppColors.t1,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.t1,
          ),
          titleLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.t1,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.t1,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.t1,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.t2,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.t1,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.t3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInteract,
        hintStyle: const TextStyle(color: AppColors.t3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
