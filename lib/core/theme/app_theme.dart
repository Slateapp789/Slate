import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds - neutral graphite-to-mist greys.
  static const bg = Color(0xFFD6D5D1);
  static const bgCard = Color(0xFFE9E8E4);
  static const bgRaised = Color(0xFFF5F4F0);
  static const bgInteract = Color(0xFFC9C8C3);
  static const border = Color(0xFFB8B7B1);
  static const borderStrong = Color(0xFF85847F);

  // Text
  static const t1 = Color(0xFF242424);
  static const t2 = Color(0xBF242424);
  static const t3 = Color(0x73242424);
  static const t4 = Color(0x33242424);

  // Accent - pure neutral slate. Green aliases remain for existing code.
  static const slate = Color(0xFF5F5F5B);
  static const slateLight = Color(0xFFBCBAB4);
  static const slateDim = Color(0x66BCBAB4);
  static const slateGlow = Color(0x99BCBAB4);
  static const green = Color(0xFF5F5F5B);
  static const greenLight = Color(0xFFC8C6BF);
  static const greenDim = Color(0x66C8C6BF);
  static const greenGlow = Color(0x99C8C6BF);

  // Aliases so existing code doesn't break
  static const violet = Color(0xFF6D6C67);
  static const violetDim = Color(0x66CFCDC7);
  static const violetGlow = Color(0x99CFCDC7);

  // Semantic
  static const success = Color(0xFF626760);
  static const successDim = Color(0x335F645E);
  static const warning = Color(0xFF8A806F);
  static const warningDim = Color(0x33A49A8A);
  static const error = Color(0xFF9D6B67);
  static const errorDim = Color(0x33BCA19E);

  // Module colours - tonal greys without the previous green cast.
  static const modClients = Color(0xFF83827D);
  static const modCalendar = Color(0xFF92908A);
  static const modFinance = Color(0xFF706F6A);
  static const modTasks = Color(0xFFA4A19A);

  // Module icon backgrounds.
  static const modBg = Color(0xFFDAD8D2);

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = Color(0xFFD0CFCA);
  static const panelSoftRaised = Color(0xFFBDBBB5);
  static const panelInk = Color(0xFF242424);
  static const panelMuted = Color(0x99242424);
  static const panelFaint = Color(0x26242424);
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
      color: const Color(0xFF3F3F3C).withValues(alpha: 0.11),
      blurRadius: 24,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get glass => [
    BoxShadow(
      color: const Color(0xFF3F3F3C).withValues(alpha: 0.15),
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
