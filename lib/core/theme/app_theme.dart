import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class AppColors {
  // Workloop is intentionally dark-only. These graphite layers are slightly
  // lifted from black so surfaces stay calm without collapsing together.
  static const bg = Color(0xFF151A16);
  static const bgCard = Color(0xFF1C231D);
  static const bgRaised = Color(0xFF252E26);
  static const bgInteract = Color(0xFF2C372D);
  static const border = Color(0xFF3E4B3F);
  static const borderStrong = Color(0xFF5E705F);

  // Text
  static const t1 = Color(0xFFF4F7F3);
  static const t2 = Color(0xFFCDD5CC);
  static const t3 = Color(0xFFA6B1A5);
  static const t4 = Color(0xFF899588);

  // Workloop's signature neon is sampled directly from the app icon and launch
  // artwork. It is reserved for primary actions and active states; filled
  // controls use the dark [onBrandAccent] foreground.
  static const brandAccent = Color(0xFFC1FF72);
  static const onBrandAccent = Color(0xFF17200D);
  static const accentInk = Color(0xFFC1FF72);
  static const slate = brandAccent;
  static const slateLight = brandAccent;
  static const slateDim = Color(0x33C1FF72);
  static const slateGlow = Color(0x55C1FF72);
  static const accentPrimary = accentInk;
  static const accentPrimaryStrong = brandAccent;
  // Compatibility alias for older foreground/status call sites. Filled brand
  // controls must use brandAccent/accentPrimaryStrong explicitly.
  static const green = accentInk;
  static const greenLight = Color(0xFF202B17);
  static const greenDim = slateDim;
  static const greenGlow = slateGlow;

  // Aliases so existing code doesn't break
  static const violet = Color(0xFFE58AB5);
  static const violetDim = Color(0x24B05884);
  static const violetGlow = Color(0x33B05884);

  // Semantic
  static const statusSuccess = Color(0xFFA8E85B);
  static const statusSuccessDim = Color(0x385C8F25);
  static const success = statusSuccess;
  static const successDim = statusSuccessDim;
  static const warning = Color(0xFFF2C56B);
  static const warningDim = Color(0x38332A13);
  static const error = Color(0xFFFF7A73);
  static const errorDim = Color(0x4D351817);

  // Module colours.
  static const modHome = accentInk;
  static const modClients = accentInk;
  static const modCalendar = Color(0xFF75C9B8);
  static const modFinance = accentInk;
  static const modTasks = Color(0xFFD19ABA);
  static const modNotes = Color(0xFF83BDD3);

  // Module icon backgrounds.
  static const modBg = Color(0xFF2C372D);

  // Hero/summary panels used for financial and high-trust information.
  static const panelSoft = Color(0xFF191F15);
  static const panelSoftRaised = Color(0xFF242F1A);
  // Foreground used whenever the exact brand neon is the background fill.
  // This stays dark to preserve contrast on the neon fill.
  static const panelInk = onBrandAccent;
  static const panelMuted = Color(0xFFC3CCC2);
  static const panelFaint = Color(0x38C1FF72);
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

  static const dark = WorkloopThemeTokens(
    background: Color(0xFF151A16),
    surface: Color(0xFF1C231D),
    surfaceRaised: Color(0xFF252E26),
    surfaceSubtle: Color(0xFF2C372D),
    divider: Color(0xFF3E4B3F),
    dividerStrong: Color(0xFF5E705F),
    textPrimary: Color(0xFFF4F7F3),
    textSecondary: Color(0xFFCDD5CC),
    textTertiary: Color(0xFFA6B1A5),
    textDisabled: Color(0xFF899588),
    accent: Color(0xFFC1FF72),
    accentStrong: Color(0xFFC1FF72),
    accentInk: Color(0xFFC1FF72),
    onAccent: Color(0xFF17200D),
    success: Color(0xFFA8E85B),
    successContainer: Color(0xFF202B17),
    warning: Color(0xFFF2C56B),
    warningContainer: Color(0xFF332A13),
    error: Color(0xFFFF7A73),
    errorContainer: Color(0xFF351817),
    info: Color(0xFF72C7EA),
    infoContainer: Color(0xFF162D36),
    scrim: Color(0xA6000000),
    skeletonBase: Color(0xFF3E4B3F),
    skeletonHighlight: Color(0xFF5B6C5C),
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
  static const double pageX = 20;

  /// Canonical content inset below the platform safe area.
  static const double screenTop = lg;
  static const double minTouch = 44;
  static const double bottomNavClearance = 104;
}

class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
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
  static const themeMode = ThemeMode.dark;

  static ThemeData get dark {
    const tokens = WorkloopThemeTokens.dark;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Instrument Sans',
      brightness: Brightness.dark,
      extensions: const [tokens],
      scaffoldBackgroundColor: tokens.background,
      focusColor: tokens.accent.withValues(alpha: 0.24),
      highlightColor: tokens.accent.withValues(alpha: 0.12),
      splashColor: tokens.accent.withValues(alpha: 0.14),
      disabledColor: tokens.textDisabled,
      iconTheme: IconThemeData(color: tokens.textSecondary, size: 20),
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
        secondary: tokens.accent,
        onSecondary: tokens.onAccent,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        error: tokens.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.accentInk,
        selectionColor: tokens.accent.withValues(alpha: 0.42),
        selectionHandleColor: tokens.accentInk,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
          height: 1.05,
          color: tokens.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.45,
          height: 1.06,
          color: tokens.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.1,
          color: tokens.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.12,
          color: tokens.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.38,
          color: tokens.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: tokens.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: tokens.textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: tokens.textTertiary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
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
          borderSide: BorderSide(color: tokens.accentInk, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accentStrong,
          foregroundColor: tokens.onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accentStrong,
          foregroundColor: tokens.onAccent,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accentInk,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size(44, 44),
          side: BorderSide(color: tokens.dividerStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.accentStrong,
        foregroundColor: tokens.onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.accentStrong
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(tokens.onAccent),
        side: BorderSide(color: tokens.dividerStrong, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs / 2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.accentInk
              : tokens.textTertiary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accentInk,
        linearTrackColor: tokens.surfaceSubtle,
        circularTrackColor: tokens.surfaceSubtle,
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
          fontWeight: FontWeight.w500,
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
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      return child;
    }
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
