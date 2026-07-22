import 'dart:ui' show ColorSpace;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compatibility bridge for legacy widgets that still reference [AppColors].
/// New and actively edited widgets should use [WorkloopThemeTokens] instead.
class WorkloopLegacyPalette {
  const WorkloopLegacyPalette._();

  static Brightness brightness = Brightness.light;

  static void sync(Brightness value) => brightness = value;
}

class _AdaptiveColor extends Color {
  final Color light;
  final Color dark;

  const _AdaptiveColor(this.light, this.dark) : super(0x00000000);

  Color get _resolved =>
      WorkloopLegacyPalette.brightness == Brightness.dark ? dark : light;

  @override
  double get a => _resolved.a;

  @override
  double get r => _resolved.r;

  @override
  double get g => _resolved.g;

  @override
  double get b => _resolved.b;

  @override
  ColorSpace get colorSpace => _resolved.colorSpace;

  @override
  int toARGB32() => _resolved.toARGB32();
}

class AppColors {
  // Backgrounds - pure paper with very quiet operational surfaces.
  static const bg = _AdaptiveColor(Color(0xFFFFFFFF), Color(0xFF050604));
  static const bgCard = _AdaptiveColor(Color(0xFFFFFFFF), Color(0xFF090B08));
  static const bgRaised = _AdaptiveColor(Color(0xFFF8F9F6), Color(0xFF10130E));
  static const bgInteract = _AdaptiveColor(
    Color(0xFFF4F6F1),
    Color(0xFF151A12),
  );
  static const border = _AdaptiveColor(Color(0xFFE8EDE3), Color(0xFF20261D));
  static const borderStrong = _AdaptiveColor(
    Color(0xFFD6DFCE),
    Color(0xFF313A2C),
  );

  // Text
  static const t1 = _AdaptiveColor(Color(0xFF11130F), Color(0xFFF7F8F3));
  static const t2 = _AdaptiveColor(Color(0xCC11130F), Color(0xCCF7F8F3));
  static const t3 = _AdaptiveColor(Color(0x8C11130F), Color(0x8CF7F8F3));
  static const t4 = _AdaptiveColor(Color(0x3D11130F), Color(0x3DF7F8F3));

  // Brand accent. Keep the root accent exact; use accentInk for thin icons and
  // text that need stronger contrast on light surfaces.
  static const brandAccent = Color(0xFFC1FF72);
  static const onBrandAccent = Color(0xFF17200D);
  static const accentInk = _AdaptiveColor(Color(0xFF4D7317), Color(0xFFC1FF72));
  static const slate = brandAccent;
  static const slateLight = brandAccent;
  static const slateDim = Color(0x33C1FF72);
  static const slateGlow = Color(0x55C1FF72);
  static const accentPrimary = brandAccent;
  static const accentPrimaryStrong = brandAccent;
  // Compatibility aliases for older brand-colour call sites.
  static const green = brandAccent;
  static const greenLight = _AdaptiveColor(
    Color(0xFFF2FFDF),
    Color(0xFF1A2410),
  );
  static const greenDim = Color(0x33C1FF72);
  static const greenGlow = Color(0x55C1FF72);

  // Aliases so existing code doesn't break
  static const violet = Color(0xFFB05884);
  static const violetDim = Color(0x24B05884);
  static const violetGlow = Color(0x33B05884);

  // Semantic
  static const statusSuccess = Color(0xFF5C8F25);
  static const statusSuccessDim = _AdaptiveColor(
    Color(0x295C8F25),
    Color(0x385C8F25),
  );
  static const success = Color(0xFF5C8F25);
  static const successDim = statusSuccessDim;
  static const warning = Color(0xFFA67300);
  static const warningDim = _AdaptiveColor(
    Color(0x24A67300),
    Color(0x382B220D),
  );
  static const error = Color(0xFFC94A42);
  static const errorDim = _AdaptiveColor(Color(0x24C94A42), Color(0x4D2C1210));

  // Module colours.
  static const modHome = Color(0xFF6F911C);
  static const modClients = Color(0xFF17845F);
  static const modCalendar = Color(0xFF0D79A0);
  static const modFinance = Color(0xFF5D7F00);
  static const modTasks = Color(0xFFB05884);
  static const modNotes = Color(0xFF09789A);

  // Module icon backgrounds.
  static const modBg = _AdaptiveColor(Color(0xFFF2F5EE), Color(0xFF151A12));

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = _AdaptiveColor(Color(0xFFF7FAF1), Color(0xFF10130E));
  static const panelSoftRaised = _AdaptiveColor(
    Color(0xFFE4ECD9),
    Color(0xFF18220F),
  );
  static const panelInk = _AdaptiveColor(Color(0xFF11130F), Color(0xFFF7F8F3));
  static const panelMuted = _AdaptiveColor(
    Color(0x9911130F),
    Color(0x99F7F8F3),
  );
  static const panelFaint = _AdaptiveColor(
    Color(0x24D6DFCE),
    Color(0x38313A2C),
  );
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
  final Color accentInk;
  final Color onAccent;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;
  final Color scrim;
  final Color skeletonBase;
  final Color skeletonHighlight;

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
    required this.accentInk,
    required this.onAccent,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
    required this.scrim,
    required this.skeletonBase,
    required this.skeletonHighlight,
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
    accent: Color(0xFFC1FF72),
    accentStrong: Color(0xFFC1FF72),
    accentInk: Color(0xFF4D7317),
    onAccent: Color(0xFF17200D),
    success: Color(0xFF5C8F25),
    successContainer: Color(0xFFEAF4DE),
    warning: Color(0xFFA67300),
    warningContainer: Color(0xFFFFF3D6),
    error: Color(0xFFC94A42),
    errorContainer: Color(0xFFFBEAE8),
    info: Color(0xFF256C8A),
    infoContainer: Color(0xFFE5F3F8),
    scrim: Color(0x52000000),
    skeletonBase: Color(0xFFE8EDE3),
    skeletonHighlight: Color(0xFFF7F9F4),
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
    accent: Color(0xFFC1FF72),
    accentStrong: Color(0xFFC1FF72),
    accentInk: Color(0xFFC1FF72),
    onAccent: Color(0xFF17200D),
    success: Color(0xFF8CBF39),
    successContainer: Color(0xFF18220F),
    warning: Color(0xFFE2AC38),
    warningContainer: Color(0xFF2B220D),
    error: Color(0xFFFF6961),
    errorContainer: Color(0xFF2C1210),
    info: Color(0xFF72C7EA),
    infoContainer: Color(0xFF10242C),
    scrim: Color(0xA6000000),
    skeletonBase: Color(0xFF20261D),
    skeletonHighlight: Color(0xFF313A2C),
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
    Color? accentInk,
    Color? onAccent,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    Color? info,
    Color? infoContainer,
    Color? scrim,
    Color? skeletonBase,
    Color? skeletonHighlight,
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
      accentInk: accentInk ?? this.accentInk,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      scrim: scrim ?? this.scrim,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
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
      accentInk: blend(accentInk, other.accentInk),
      onAccent: blend(onAccent, other.onAccent),
      success: blend(success, other.success),
      successContainer: blend(successContainer, other.successContainer),
      warning: blend(warning, other.warning),
      warningContainer: blend(warningContainer, other.warningContainer),
      error: blend(error, other.error),
      errorContainer: blend(errorContainer, other.errorContainer),
      info: blend(info, other.info),
      infoContainer: blend(infoContainer, other.infoContainer),
      scrim: blend(scrim, other.scrim),
      skeletonBase: blend(skeletonBase, other.skeletonBase),
      skeletonHighlight: blend(skeletonHighlight, other.skeletonHighlight),
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
  static const double bottomNavClearance = 118;
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

  static Duration responsive(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : duration;
  }
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
  static ThemeData get dark => oledDark;

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      extensions: const [WorkloopThemeTokens.light],
      scaffoldBackgroundColor: AppColors.bg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlatePageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandAccent,
        onPrimary: AppColors.onBrandAccent,
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
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgCard,
        modalBackgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.t1,
        contentTextStyle: const TextStyle(
          color: AppColors.bgCard,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onBrandAccent
              : AppColors.bgCard,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandAccent
              : AppColors.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
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
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.dark(
        primary: tokens.accent,
        onPrimary: tokens.onAccent,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceRaised,
        modalBackgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: tokens.dividerStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: tokens.divider),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.textPrimary,
        contentTextStyle: TextStyle(
          color: tokens.background,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.onAccent
              : tokens.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.accent
              : tokens.dividerStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
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
