import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds - pure paper with very quiet operational surfaces.
  static const bg = Color(0xFFFFFFFF);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgRaised = Color(0xFFF8F9F6);
  static const bgInteract = Color(0xFFF4F6F1);
  static const border = Color(0xFFE8EDE3);
  static const borderStrong = Color(0xFFD6DFCE);

  // Text
  static const t1 = Color(0xFF11130F);
  static const t2 = Color(0xCC11130F);
  static const t3 = Color(0x8C11130F);
  static const t4 = Color(0x3D11130F);

  // Accent. Green aliases remain for existing code.
  static const slate = Color(0xFF7FB500);
  static const slateLight = Color(0xFFD9FF57);
  static const slateDim = Color(0x337FB500);
  static const slateGlow = Color(0x55D9FF57);
  static const accentPrimary = Color(0xFF7FB500);
  static const accentPrimaryStrong = Color(0xFFD9FF57);
  static const green = Color(0xFF2E7D5B);
  static const greenLight = Color(0xFFE7F4EC);
  static const greenDim = Color(0x242E7D5B);
  static const greenGlow = Color(0x332E7D5B);

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
  static const modBg = Color(0xFFF2F5EE);

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = Color(0xFFF7FAF1);
  static const panelSoftRaised = Color(0xFFE4ECD9);
  static const panelInk = Color(0xFF11130F);
  static const panelMuted = Color(0x9911130F);
  static const panelFaint = Color(0x24D6DFCE);
}

@immutable
class WorkloopThemeTokens extends ThemeExtension<WorkloopThemeTokens> {
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSubtle;
  final Color divider;
  final Color dividerStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color accent;
  final Color accentStrong;
  final Color success;
  final Color warning;
  final Color error;

  const WorkloopThemeTokens({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSubtle,
    required this.divider,
    required this.dividerStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.accent,
    required this.accentStrong,
    required this.success,
    required this.warning,
    required this.error,
  });

  static const light = WorkloopThemeTokens(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF8F9F6),
    surfaceSubtle: Color(0xFFF4F6F1),
    divider: Color(0xFFE8EDE3),
    dividerStrong: Color(0xFFD6DFCE),
    textPrimary: Color(0xFF11130F),
    textSecondary: Color(0xCC11130F),
    textTertiary: Color(0x8C11130F),
    textDisabled: Color(0x3D11130F),
    accent: Color(0xFF7FB500),
    accentStrong: Color(0xFFD9FF57),
    success: Color(0xFF5C8F25),
    warning: Color(0xFFA67300),
    error: Color(0xFFC94A42),
  );

  static const dark = WorkloopThemeTokens(
    background: Color(0xFF050604),
    surface: Color(0xFF090B08),
    surfaceRaised: Color(0xFF10130E),
    surfaceSubtle: Color(0xFF151A12),
    divider: Color(0xFF20261D),
    dividerStrong: Color(0xFF313A2C),
    textPrimary: Color(0xFFF7F8F3),
    textSecondary: Color(0xCCF7F8F3),
    textTertiary: Color(0x8CF7F8F3),
    textDisabled: Color(0x3DF7F8F3),
    accent: Color(0xFF9BDE18),
    accentStrong: Color(0xFFD9FF57),
    success: Color(0xFF8CBF39),
    warning: Color(0xFFE2AC38),
    error: Color(0xFFFF6961),
  );

  @override
  WorkloopThemeTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSubtle,
    Color? divider,
    Color? dividerStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? accent,
    Color? accentStrong,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return WorkloopThemeTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      divider: divider ?? this.divider,
      dividerStrong: dividerStrong ?? this.dividerStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  WorkloopThemeTokens lerp(
    ThemeExtension<WorkloopThemeTokens>? other,
    double t,
  ) {
    if (other is! WorkloopThemeTokens) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return WorkloopThemeTokens(
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      surfaceRaised: blend(surfaceRaised, other.surfaceRaised),
      surfaceSubtle: blend(surfaceSubtle, other.surfaceSubtle),
      divider: blend(divider, other.divider),
      dividerStrong: blend(dividerStrong, other.dividerStrong),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      textTertiary: blend(textTertiary, other.textTertiary),
      textDisabled: blend(textDisabled, other.textDisabled),
      accent: blend(accent, other.accent),
      accentStrong: blend(accentStrong, other.accentStrong),
      success: blend(success, other.success),
      warning: blend(warning, other.warning),
      error: blend(error, other.error),
    );
  }
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
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get glass => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.07),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

class AppTheme {
  static ThemeData get dark => light;

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      extensions: const [WorkloopThemeTokens.light],
      scaffoldBackgroundColor: AppColors.bg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlatePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlatePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlatePageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPrimary,
        surface: AppColors.bgCard,
        onSurface: AppColors.t1,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.02,
            color: AppColors.t1,
          ),
          displayMedium: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.04,
            color: AppColors.t1,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.08,
            color: AppColors.t1,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 1.12,
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
            height: 1.38,
            color: AppColors.t1,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.36,
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
          borderSide: const BorderSide(
            color: AppColors.accentPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimaryStrong,
          foregroundColor: AppColors.t1,
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

  static ThemeData get oledDark {
    const tokens = WorkloopThemeTokens.dark;
    return ThemeData(
      brightness: Brightness.dark,
      extensions: const [tokens],
      scaffoldBackgroundColor: tokens.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlatePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlatePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlatePageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.dark(
        primary: tokens.accent,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        error: tokens.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.02,
            color: tokens.textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.04,
            color: tokens.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            height: 1.08,
            color: tokens.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 1.12,
            color: tokens.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.38,
            color: tokens.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.36,
            color: tokens.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: tokens.textTertiary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceSubtle,
        hintStyle: TextStyle(color: tokens.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accentStrong,
          foregroundColor: const Color(0xFF11130F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: tokens.divider,
      dividerTheme: DividerThemeData(
        color: tokens.divider,
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
