import 'dart:ui' show ColorSpace;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Compatibility bridge for legacy widgets that still reference [AppColors].
/// New and actively edited widgets should use [WorkloopThemeTokens] instead.
class WorkloopLegacyPalette {
  const WorkloopLegacyPalette._();

  static Brightness brightness = Brightness.dark;

  static void sync(Brightness value) => brightness = value;

  static Brightness resolve({
    required ThemeMode themeMode,
    required Brightness platformBrightness,
  }) => switch (themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platformBrightness,
  };
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
  // Workloop Studio replaces the retired lime/graphite identity with a warm
  // porcelain and midnight system led by confident indigo and human teal.
  static const bg = _AdaptiveColor(Color(0xFFF6F4EF), Color(0xFF111318));
  static const bgCard = _AdaptiveColor(Color(0xFFFFFFFF), Color(0xFF1C2027));
  static const bgRaised = _AdaptiveColor(Color(0xFFF0EEF8), Color(0xFF252A33));
  static const bgInteract = _AdaptiveColor(
    Color(0xFFECEFF3),
    Color(0xFF2E343F),
  );
  static const border = _AdaptiveColor(Color(0xFFDDE2E8), Color(0xFF3A414D));
  static const borderStrong = _AdaptiveColor(
    Color(0xFFC7CED8),
    Color(0xFF545D6B),
  );

  static const t1 = _AdaptiveColor(Color(0xFF172033), Color(0xFFF6F7FB));
  static const t2 = _AdaptiveColor(Color(0xFF5F6B7A), Color(0xFFC5CAD3));
  static const t3 = _AdaptiveColor(Color(0xFF7C8795), Color(0xFF9CA4B0));
  static const t4 = _AdaptiveColor(Color(0xFF929BA7), Color(0xFF7E8794));

  static const brandAccent = _AdaptiveColor(
    Color(0xFF4F46E5),
    Color(0xFF9496E8),
  );
  static const onBrandAccent = _AdaptiveColor(
    Color(0xFFFFFFFF),
    Color(0xFF111427),
  );
  static const accentInk = brandAccent;
  static const accentBorder = _AdaptiveColor(
    Color(0xFF4038C9),
    Color(0xFF7D80D4),
  );
  static const slate = brandAccent;
  static const slateLight = brandAccent;
  static const slateDim = _AdaptiveColor(Color(0xFFE9E8FF), Color(0xFF2A2D3E));
  static const slateGlow = _AdaptiveColor(Color(0x334F46E5), Color(0x309496E8));
  static const accentPrimary = accentInk;
  static const accentPrimaryStrong = brandAccent;
  static const green = accentInk;
  static const greenLight = slateDim;
  static const greenDim = slateDim;
  static const greenGlow = slateGlow;

  static const violet = _AdaptiveColor(Color(0xFF7557D9), Color(0xFF9A96E3));
  static const violetDim = _AdaptiveColor(Color(0xFFECE7FF), Color(0xFF302F45));
  static const violetGlow = _AdaptiveColor(
    Color(0x337557D9),
    Color(0x309A96E3),
  );

  static const statusSuccess = _AdaptiveColor(
    Color(0xFF19704E),
    Color(0xFF65D9A5),
  );
  static const statusSuccessDim = _AdaptiveColor(
    Color(0xFFDFF3E9),
    Color(0xFF173A31),
  );
  static const success = statusSuccess;
  static const successDim = statusSuccessDim;
  static const warning = _AdaptiveColor(Color(0xFF8B5A12), Color(0xFFF2BE62));
  static const warningDim = _AdaptiveColor(
    Color(0xFFFFF0D6),
    Color(0xFF42331E),
  );
  static const error = _AdaptiveColor(Color(0xFFB23C4A), Color(0xFFFF8490));
  static const errorDim = _AdaptiveColor(Color(0xFFF9E4E7), Color(0xFF44232B));

  static const modHome = brandAccent;
  static const modClients = _AdaptiveColor(
    Color(0xFF168F83),
    Color(0xFF5FD6C5),
  );
  static const modCalendar = violet;
  static const modFinance = _AdaptiveColor(
    Color(0xFFB87516),
    Color(0xFFF1B85B),
  );
  static const modTasks = _AdaptiveColor(Color(0xFFC65E55), Color(0xFFFF9188));
  static const modNotes = _AdaptiveColor(Color(0xFF3185B8), Color(0xFF78C8F3));

  static const modBg = _AdaptiveColor(Color(0xFFF0EEF8), Color(0xFF252A33));

  static const panelSoft = _AdaptiveColor(Color(0xFFE9E8FF), Color(0xFF2A2D3E));
  static const panelSoftRaised = _AdaptiveColor(
    Color(0xFFDDF5F1),
    Color(0xFF173A38),
  );
  static const panelInk = onBrandAccent;
  static const panelMuted = _AdaptiveColor(
    Color(0xFF5F6B7A),
    Color(0xFFC5CAD3),
  );
  static const panelFaint = _AdaptiveColor(
    Color(0x334F46E5),
    Color(0x309496E8),
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
  final Color accentBorder;
  final Color onAccent;
  final Color primaryAction;
  final Color onPrimaryAction;
  final Color inkSurface;
  final Color onInk;
  final Color onInkMuted;
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

  // Hero roles are explicit because Dark mode uses a deep, muted indigo field
  // rather than expanding the brighter interactive accent across the screen.
  bool get _isDarkContract => background.computeLuminance() < 0.1;
  Color get heroGradientStart =>
      _isDarkContract ? const Color(0xFF333852) : accentStrong;
  Color get heroGradientEnd =>
      _isDarkContract ? const Color(0xFF414866) : primaryAction;
  Color get onHeroPrimary =>
      _isDarkContract ? const Color(0xFFF8F9FC) : onPrimaryAction;
  Color get heroActionForeground => _isDarkContract ? onAccent : primaryAction;
  Color get onHeroSecondary => onHeroPrimary.withValues(alpha: 0.92);
  Color get onHeroMuted => onHeroPrimary.withValues(alpha: 0.82);
  Color get heroBorder => onHeroPrimary.withValues(alpha: 0.20);
  Color get heroSurface => onHeroPrimary.withValues(alpha: 0.08);
  Color get heroControlSurface => onHeroPrimary.withValues(alpha: 0.10);

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
    required this.accentBorder,
    required this.onAccent,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.inkSurface,
    required this.onInk,
    required this.onInkMuted,
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
    background: Color(0xFFF6F4EF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0EEF8),
    surfaceSubtle: Color(0xFFECEFF3),
    divider: Color(0xFFDDE2E8),
    dividerStrong: Color(0xFFC7CED8),
    textPrimary: Color(0xFF172033),
    textSecondary: Color(0xFF5F6B7A),
    textTertiary: Color(0xFF7C8795),
    textDisabled: Color(0xFF929BA7),
    accent: Color(0xFF4F46E5),
    accentStrong: Color(0xFF4038C9),
    accentInk: Color(0xFF4F46E5),
    accentBorder: Color(0xFF4038C9),
    onAccent: Color(0xFFFFFFFF),
    primaryAction: Color(0xFF4F46E5),
    onPrimaryAction: Color(0xFFFFFFFF),
    inkSurface: Color(0xFF4F46E5),
    onInk: Color(0xFFFFFFFF),
    onInkMuted: Color(0xFFE9E8FF),
    success: Color(0xFF19704E),
    successContainer: Color(0xFFDFF3E9),
    warning: Color(0xFF8B5A12),
    warningContainer: Color(0xFFFFF0D6),
    error: Color(0xFFB23C4A),
    errorContainer: Color(0xFFF9E4E7),
    info: Color(0xFF246F9E),
    infoContainer: Color(0xFFE1F1FA),
    scrim: Color(0x52000000),
    skeletonBase: Color(0xFFE2E5EA),
    skeletonHighlight: Color(0xFFF7F8FA),
  );

  static const dark = WorkloopThemeTokens(
    background: Color(0xFF111318),
    surface: Color(0xFF1C2027),
    surfaceRaised: Color(0xFF252A33),
    surfaceSubtle: Color(0xFF2E343F),
    divider: Color(0xFF3A414D),
    dividerStrong: Color(0xFF545D6B),
    textPrimary: Color(0xFFF6F7FB),
    textSecondary: Color(0xFFC5CAD3),
    textTertiary: Color(0xFF9CA4B0),
    textDisabled: Color(0xFF7E8794),
    accent: Color(0xFF9496E8),
    accentStrong: Color(0xFF7D80D4),
    accentInk: Color(0xFFA4A6F2),
    accentBorder: Color(0xFF7D80D4),
    onAccent: Color(0xFF111427),
    primaryAction: Color(0xFF9496E8),
    onPrimaryAction: Color(0xFF111427),
    inkSurface: Color(0xFF2A2D3E),
    onInk: Color(0xFFF6F7FB),
    onInkMuted: Color(0xFFC5CAD3),
    success: Color(0xFF65D9A5),
    successContainer: Color(0xFF173A31),
    warning: Color(0xFFF2BE62),
    warningContainer: Color(0xFF42331E),
    error: Color(0xFFFF8490),
    errorContainer: Color(0xFF44232B),
    info: Color(0xFF78C8F3),
    infoContainer: Color(0xFF183548),
    scrim: Color(0xA6000000),
    skeletonBase: Color(0xFF2E343F),
    skeletonHighlight: Color(0xFF414955),
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
    Color? accentBorder,
    Color? onAccent,
    Color? primaryAction,
    Color? onPrimaryAction,
    Color? inkSurface,
    Color? onInk,
    Color? onInkMuted,
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
      accentBorder: accentBorder ?? this.accentBorder,
      onAccent: onAccent ?? this.onAccent,
      primaryAction: primaryAction ?? this.primaryAction,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      inkSurface: inkSurface ?? this.inkSurface,
      onInk: onInk ?? this.onInk,
      onInkMuted: onInkMuted ?? this.onInkMuted,
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
      accentBorder: blend(accentBorder, other.accentBorder),
      onAccent: blend(onAccent, other.onAccent),
      primaryAction: blend(primaryAction, other.primaryAction),
      onPrimaryAction: blend(onPrimaryAction, other.onPrimaryAction),
      inkSurface: blend(inkSurface, other.inkSurface),
      onInk: blend(onInk, other.onInk),
      onInkMuted: blend(onInkMuted, other.onInkMuted),
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
  static const double pageX = 18;
  static const double section = 24;

  /// Canonical content inset below the platform safe area.
  static const double screenTop = 12;
  static const double minTouch = 44;

  /// Shared floating-navigation geometry. Shell screens calculate their final
  /// content inset from these values and the real device safe area.
  static const double bottomNavHeight = 66;
  static const double bottomNavOffset = 10;
  static const double bottomNavBreathingRoom = 18;

  static double shellBottomClearance(BuildContext context) {
    return bottomNavHeight +
        bottomNavOffset +
        MediaQuery.paddingOf(context).bottom +
        bottomNavBreathingRoom;
  }
}

class AppRadius {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double sheet = 28;

  /// Reserved for status, compact filters and progress markers.
  static const double capsule = 999;
}

class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 200);
  static const deliberate = Duration(milliseconds: 280);
  static const celebration = Duration(milliseconds: 440);
  static const navigation = Duration(milliseconds: 220);
  static const double navigationOffset = 0.04;
  static const double destinationOffset = 14;
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;
  static const double pressedScale = 0.98;

  static Duration responsive(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : duration;
  }
}

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: const Color(0xFF172033).withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get glass => [
    BoxShadow(
      color: const Color(0xFF172033).withValues(alpha: 0.14),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get dock => [
    BoxShadow(
      color: const Color(0xFF172033).withValues(alpha: 0.16),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
}

class AppTheme {
  static ThemeData get light =>
      _build(tokens: WorkloopThemeTokens.light, brightness: Brightness.light);

  static ThemeData get dark =>
      _build(tokens: WorkloopThemeTokens.dark, brightness: Brightness.dark);

  static ThemeData _build({
    required WorkloopThemeTokens tokens,
    required Brightness brightness,
  }) {
    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: tokens.accent,
            onPrimary: tokens.onAccent,
            secondary: tokens.accent,
            onSecondary: tokens.onAccent,
            surface: tokens.surface,
            onSurface: tokens.textPrimary,
            error: tokens.error,
          )
        : ColorScheme.light(
            primary: tokens.accent,
            onPrimary: tokens.onAccent,
            secondary: tokens.accentInk,
            onSecondary: tokens.surface,
            surface: tokens.surface,
            onSurface: tokens.textPrimary,
            error: tokens.error,
          );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      brightness: brightness,
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      cardColor: tokens.surface,
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
      colorScheme: colorScheme,
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
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 40 / 34,
          color: tokens.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.65,
          height: 34 / 30,
          color: tokens.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.45,
          height: 32 / 26,
          color: tokens.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          height: 24 / 19,
          color: tokens.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 21 / 16,
          color: tokens.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 18 / 14,
          color: tokens.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 22 / 15,
          color: tokens.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 19 / 13,
          color: tokens.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 18 / 14,
          color: tokens.textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 14 / 11,
          color: tokens.textTertiary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: TextStyle(color: tokens.textTertiary),
        labelStyle: TextStyle(color: tokens.textSecondary),
        floatingLabelStyle: TextStyle(
          color: tokens.accentInk,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: TextStyle(color: tokens.error),
        prefixIconColor: tokens.textSecondary,
        suffixIconColor: tokens.textSecondary,
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
          borderSide: BorderSide(color: tokens.accent, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.divider),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primaryAction,
          foregroundColor: tokens.onPrimaryAction,
          minimumSize: const Size(44, 52),
          elevation: 1,
          shadowColor: tokens.accent.withValues(alpha: 0.2),
          side: BorderSide(color: tokens.primaryAction, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primaryAction,
          foregroundColor: tokens.onPrimaryAction,
          minimumSize: const Size(44, 52),
          side: BorderSide(color: tokens.primaryAction, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size(44, 50),
          side: BorderSide(color: tokens.dividerStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primaryAction,
        foregroundColor: tokens.onPrimaryAction,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: tokens.primaryAction, width: 1),
        ),
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
            top: Radius.circular(AppRadius.sheet),
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
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.015, 0),
      ).animate(outgoing),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.96).animate(outgoing),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(AppMotion.navigationOffset, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      ),
    );
  }
}
