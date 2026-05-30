import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds - warm chalk / soft slate.
  static const bg = Color(0xFFF3F1EC);
  static const bgCard = Color(0xFFFBFAF7);
  static const bgRaised = Color(0xFFFFFFFF);
  static const bgInteract = Color(0xFFE9ECEB);
  static const border = Color(0xFFD8DCD9);
  static const borderStrong = Color(0xFFBDC5C0);

  // Text
  static const t1 = Color(0xFF202629);
  static const t2 = Color(0xBF202629);
  static const t3 = Color(0x73202629);
  static const t4 = Color(0x33202629);

  // Accent - pastel Slate palette. Green aliases remain for existing code.
  static const slate = Color(0xFF5F8EA3);
  static const slateLight = Color(0xFFB9D8E6);
  static const slateDim = Color(0x667DB7CE);
  static const slateGlow = Color(0x998FC7DA);
  static const green = Color(0xFF82B99A);
  static const greenLight = Color(0xFFCBE7D4);
  static const greenDim = Color(0x66CBE7D4);
  static const greenGlow = Color(0x99B6DFC4);

  // Aliases so existing code doesn't break
  static const violet = Color(0xFFA993D4);
  static const violetDim = Color(0x66D9CFF1);
  static const violetGlow = Color(0x99D9CFF1);

  // Semantic
  static const success = Color(0xFF6FAE86);
  static const successDim = Color(0x3DCBE7D4);
  static const warning = Color(0xFFD9915F);
  static const warningDim = Color(0x40F4CBA5);
  static const error = Color(0xFFD87070);
  static const errorDim = Color(0x3DF3B9B4);

  // Module colours - soft but distinct.
  static const modClients = Color(0xFFA993D4);
  static const modCalendar = Color(0xFF7DB7CE);
  static const modFinance = Color(0xFF82B99A);
  static const modTasks = Color(0xFFE4BE6E);

  // Module icon backgrounds.
  static const modBg = Color(0xFFF0EDE7);

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = Color(0xFFE3F1E8);
  static const panelSoftRaised = Color(0xFFCBE7D4);
  static const panelInk = Color(0xFF202629);
  static const panelMuted = Color(0x99202629);
  static const panelFaint = Color(0x26202629);
}

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pageX = 24;
  static const double pageTop = 60;
  static const double minTouch = 44;
}

class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 240);
  static const deliberate = Duration(milliseconds: 360);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
}

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: const Color(0xFF6B716D).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get glass => [
    BoxShadow(
      color: const Color(0xFF6B716D).withValues(alpha: 0.16),
      blurRadius: 34,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: AppColors.slateGlow.withValues(alpha: 0.10),
      blurRadius: 36,
      offset: const Offset(0, 5),
    ),
  ];
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        surface: AppColors.bgCard,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: AppColors.t1,
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: AppColors.t1,
          ),
          headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: AppColors.t1,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
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
            letterSpacing: 0,
            color: AppColors.t3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInteract,
        hintStyle: const TextStyle(color: AppColors.t3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
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
          foregroundColor: AppColors.panelInk,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
