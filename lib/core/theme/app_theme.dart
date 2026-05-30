import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds - Northbound Light neutrals.
  static const bg = Color(0xFFF6F4EF);
  static const bgCard = Color(0xFFFDFBF7);
  static const bgRaised = Color(0xFFFFFFFF);
  static const bgInteract = Color(0xFFE9EAE5);
  static const border = Color(0xFFD9DCD6);
  static const borderStrong = Color(0xFFA8AEA6);

  // Text
  static const t1 = Color(0xFF252A28);
  static const t2 = Color(0xBF252A28);
  static const t3 = Color(0x73252A28);
  static const t4 = Color(0x33252A28);

  // Accent - faded glacier greys. Green aliases remain for existing code.
  static const slate = Color(0xFF6E7771);
  static const slateLight = Color(0xFFD4D8D3);
  static const slateDim = Color(0x66D4D8D3);
  static const slateGlow = Color(0x99D4D8D3);
  static const green = Color(0xFF68786D);
  static const greenLight = Color(0xFFDCE3DD);
  static const greenDim = Color(0x66DCE3DD);
  static const greenGlow = Color(0x99DCE3DD);

  // Aliases so existing code doesn't break
  static const violet = Color(0xFF777F78);
  static const violetDim = Color(0x66E0E1DC);
  static const violetGlow = Color(0x99E0E1DC);

  // Semantic
  static const success = Color(0xFF68786D);
  static const successDim = Color(0x40DCE3DD);
  static const warning = Color(0xFF8A7660);
  static const warningDim = Color(0x40E7DDCF);
  static const error = Color(0xFFB27772);
  static const errorDim = Color(0x3FE9D8D5);

  // Module colours - tonal greys with subtle temperature shifts.
  static const modClients = Color(0xFF9EA49D);
  static const modCalendar = Color(0xFFAEB4AD);
  static const modFinance = Color(0xFF8D9A90);
  static const modTasks = Color(0xFFC1B7A5);

  // Module icon backgrounds.
  static const modBg = Color(0xFFEDEBE6);

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = Color(0xFFE9EDE7);
  static const panelSoftRaised = Color(0xFFD4D8D3);
  static const panelInk = Color(0xFF252A28);
  static const panelMuted = Color(0x99252A28);
  static const panelFaint = Color(0x26252A28);
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
