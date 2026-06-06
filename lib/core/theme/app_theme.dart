import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds - graphite slate with lime as the living accent.
  static const bg = Color(0xFF141713);
  static const bgCard = Color(0xFF1D211C);
  static const bgRaised = Color(0xFF282D25);
  static const bgInteract = Color(0xFF30372D);
  static const border = Color(0xFF3E463A);
  static const borderStrong = Color(0xFF68735F);

  // Text
  static const t1 = Color(0xFFF3F5EE);
  static const t2 = Color(0xCCF3F5EE);
  static const t3 = Color(0x8CF3F5EE);
  static const t4 = Color(0x3DF3F5EE);

  // Accent. Green aliases remain for existing code.
  static const slate = Color(0xFFB8F24B);
  static const slateLight = Color(0xFFD8FF7A);
  static const slateDim = Color(0x3DB8F24B);
  static const slateGlow = Color(0x66B8F24B);
  static const accentPrimary = Color(0xFFB8F24B);
  static const accentPrimaryStrong = Color(0xFFD8FF7A);
  static const green = Color(0xFFB8F24B);
  static const greenLight = Color(0xFFD8FF7A);
  static const greenDim = Color(0x26B8F24B);
  static const greenGlow = Color(0x66B8F24B);

  // Aliases so existing code doesn't break
  static const violet = Color(0xFFB8F24B);
  static const violetDim = Color(0x33B8F24B);
  static const violetGlow = Color(0x66B8F24B);

  // Semantic
  static const statusSuccess = Color(0xFF8CCF65);
  static const statusSuccessDim = Color(0x298CCF65);
  static const success = Color(0xFF8CCF65);
  static const successDim = Color(0x298CCF65);
  static const warning = Color(0xFFE4BE6A);
  static const warningDim = Color(0x29E4BE6A);
  static const error = Color(0xFFFF837A);
  static const errorDim = Color(0x29FF837A);

  // Module colours - restrained greys with subtle lime lift.
  static const modClients = Color(0xFF8FA086);
  static const modCalendar = Color(0xFFA8B894);
  static const modFinance = Color(0xFFB8F24B);
  static const modTasks = Color(0xFFC3C9BB);

  // Module icon backgrounds.
  static const modBg = Color(0xFF2D342A);

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = Color(0xFF1B2018);
  static const panelSoftRaised = Color(0xFF38432F);
  static const panelInk = Color(0xFFF5F7EF);
  static const panelMuted = Color(0x99F5F7EF);
  static const panelFaint = Color(0x263D4637);
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
      color: Colors.black.withValues(alpha: 0.24),
      blurRadius: 24,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get glass => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.32),
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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlatePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlatePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlatePageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.dark(
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
