import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds - warm paper with soft operational green surfaces.
  static const bg = Color(0xFFF4F8F0);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgRaised = Color(0xFFF8FBF4);
  static const bgInteract = Color(0xFFEDF4E8);
  static const border = Color(0xFFDCE8D6);
  static const borderStrong = Color(0xFFBFD5B8);

  // Text
  static const t1 = Color(0xFF121811);
  static const t2 = Color(0xCC121811);
  static const t3 = Color(0x8C121811);
  static const t4 = Color(0x3D121811);

  // Accent. Green aliases remain for existing code.
  static const slate = Color(0xFF416300);
  static const slateLight = Color(0xFFD9FF57);
  static const slateDim = Color(0x33416300);
  static const slateGlow = Color(0x55D9FF57);
  static const accentPrimary = Color(0xFF416300);
  static const accentPrimaryStrong = Color(0xFFD9FF57);
  static const green = Color(0xFF17845F);
  static const greenLight = Color(0xFFDDF3E7);
  static const greenDim = Color(0x2417845F);
  static const greenGlow = Color(0x3317845F);

  // Aliases so existing code doesn't break
  static const violet = Color(0xFFB05884);
  static const violetDim = Color(0x24B05884);
  static const violetGlow = Color(0x33B05884);

  // Semantic
  static const statusSuccess = Color(0xFF5C8F25);
  static const statusSuccessDim = Color(0x295C8F25);
  static const success = Color(0xFF5C8F25);
  static const successDim = Color(0x295C8F25);
  static const warning = Color(0xFFA67300);
  static const warningDim = Color(0x24A67300);
  static const error = Color(0xFFC94A42);
  static const errorDim = Color(0x24C94A42);

  // Module colours.
  static const modHome = Color(0xFF6F911C);
  static const modClients = Color(0xFF17845F);
  static const modCalendar = Color(0xFF0D79A0);
  static const modFinance = Color(0xFF5D7F00);
  static const modTasks = Color(0xFFB05884);
  static const modNotes = Color(0xFF09789A);

  // Module icon backgrounds.
  static const modBg = Color(0xFFE7F0E1);

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = Color(0xFFEAF4E4);
  static const panelSoftRaised = Color(0xFFCFE2C8);
  static const panelInk = Color(0xFF121811);
  static const panelMuted = Color(0x99121811);
  static const panelFaint = Color(0x24BFD5B8);
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
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get glass => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlatePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlatePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlatePageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        surface: AppColors.bgCard,
        onSurface: AppColors.t1,
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
          foregroundColor: AppColors.bg,
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

class _SlatePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SlatePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
