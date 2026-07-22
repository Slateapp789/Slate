import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

class SlateTheme {
  const SlateTheme._();

  static WorkloopThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<WorkloopThemeTokens>() ??
        WorkloopThemeTokens.light;
  }
}

class SlateHaptics {
  const SlateHaptics._();

  static void _safe(Future<void> Function() feedback) {
    unawaited(
      Future<void>.sync(feedback).catchError((Object _, StackTrace __) {}),
    );
  }

  static void selection() => _safe(HapticFeedback.selectionClick);
  static void light() => _safe(HapticFeedback.lightImpact);
  static void success() => _safe(HapticFeedback.mediumImpact);
  static void warning() => _safe(HapticFeedback.heavyImpact);
  static void destructive() => _safe(HapticFeedback.heavyImpact);

  // Compatibility aliases keep existing interactions routed through this one
  // restrained service while call sites migrate to semantic names.
  static void tap() => selection();
  static void action() => light();
  static void confirm() => success();
}

enum WorkloopDraftDecision { stay, discard, save }

Future<DateTime?> showWorkloopDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Choose date',
  TransitionBuilder? builder,
}) async {
  var selected = initialDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (context) {
                final calendar = CalendarDatePicker(
                  initialDate: selected,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onDateChanged: (value) {
                    SlateHaptics.selection();
                    setSheetState(() => selected = value);
                  },
                );
                return builder?.call(context, calendar) ?? calendar;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: WorkloopPrimaryButton(
                    label: 'Cancel',
                    secondary: true,
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: WorkloopPrimaryButton(
                    label: 'Use date',
                    onPressed: () {
                      SlateHaptics.success();
                      Navigator.pop(sheetContext, selected);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<TimeOfDay?> showWorkloopTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = 'Choose time',
}) async {
  var selected = initialTime;
  final initialDateTime = DateTime(
    2000,
    1,
    1,
    initialTime.hour,
    initialTime.minute,
  );
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => SlateSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 190,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: initialDateTime,
              use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
              onDateTimeChanged: (value) {
                selected = TimeOfDay(hour: value.hour, minute: value.minute);
                SlateHaptics.selection();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: WorkloopPrimaryButton(
                  label: 'Cancel',
                  secondary: true,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: WorkloopPrimaryButton(
                  label: 'Use time',
                  onPressed: () {
                    SlateHaptics.success();
                    Navigator.pop(sheetContext, selected);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<WorkloopDraftDecision> showWorkloopDraftConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String saveLabel = 'Save changes',
  bool canSave = true,
}) async {
  final result = await showModalBottomSheet<WorkloopDraftDecision>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => SlateSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SlateButton(
            label: saveLabel,
            icon: LucideIcons.check,
            onPressed: canSave
                ? () => Navigator.pop(sheetContext, WorkloopDraftDecision.save)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          SlateButton(
            label: 'Keep editing',
            secondary: true,
            onPressed: () =>
                Navigator.pop(sheetContext, WorkloopDraftDecision.stay),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.pop(sheetContext, WorkloopDraftDecision.discard),
              child: const Text(
                'Discard changes',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? WorkloopDraftDecision.stay;
}

Future<bool> showWorkloopOutsideHoursConfirmation(
  BuildContext context, {
  required String detail,
  bool repeating = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => SlateSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outside working hours',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            repeating
                ? '$detail At least one booking in this repeat schedule is outside your saved hours. You can still create it.'
                : '$detail You can still create this booking.',
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SlateButton(
            label: 'Book anyway',
            icon: LucideIcons.calendarCheck,
            onPressed: () => Navigator.pop(sheetContext, true),
          ),
          const SizedBox(height: AppSpacing.sm),
          SlateButton(
            label: 'Go back',
            secondary: true,
            onPressed: () => Navigator.pop(sheetContext, false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Applies Workloop's tap-away keyboard behaviour to every editable field.
///
/// Flutter intentionally keeps the keyboard open for touch taps outside an
/// [EditableText] on mobile. Overriding the standard intent here preserves the
/// field's own tap region while making the rest of the app dismiss focus.
class WorkloopKeyboardDismissRegion extends StatelessWidget {
  final Widget child;

  const WorkloopKeyboardDismissRegion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (intent) {
                intent.focusNode.unfocus();
                return null;
              },
            ),
      },
      child: child,
    );
  }
}

class WorkloopPage extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeArea;
  final bool scrollable;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;

  const WorkloopPage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.pageX,
      AppSpacing.lg,
      AppSpacing.pageX,
      AppSpacing.bottomNavClearance,
    ),
    this.safeArea = true,
    this.scrollable = true,
    this.controller,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    Widget content = scrollable
        ? ListView(controller: controller, padding: padding, children: [child])
        : Padding(padding: padding, child: child);

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: tokens.accentInk,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: tokens.background,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          Positioned.fill(child: safeArea ? SafeArea(child: content) : content),
        ],
      ),
    );
  }
}

/// A restrained paper-like backdrop shared by calm primary screens.
class WorkloopTexturedBackdrop extends StatelessWidget {
  const WorkloopTexturedBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WorkloopTexturePainter(
            background: tokens.background,
            raised: tokens.surfaceRaised,
            accent: tokens.accent,
            dark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _WorkloopTexturePainter extends CustomPainter {
  final Color background;
  final Color raised;
  final Color accent;
  final bool dark;

  const _WorkloopTexturePainter({
    required this.background,
    required this.raised,
    required this.accent,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [raised, background, Color.lerp(background, raised, 0.28)!],
        stops: [0, 0.48, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, backgroundPaint);

    final topGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.82, -0.92),
        radius: 0.9,
        colors: [
          accent.withValues(alpha: dark ? 0.055 : 0.075),
          accent.withValues(alpha: 0),
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, topGlow);

    var state = 0x13579B;
    double nextUnit() {
      state = (state * 1664525 + 1013904223) & 0x7fffffff;
      return state / 0x7fffffff;
    }

    final neutralGrain = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.026);
    final greenGrain = Paint()
      ..color = accent.withValues(alpha: dark ? 0.035 : 0.026);
    final pointCount = (size.width * size.height / 950).round();
    for (var index = 0; index < pointCount; index++) {
      final point = Offset(nextUnit() * size.width, nextUnit() * size.height);
      final radius = 0.3 + (nextUnit() * 0.35);
      canvas.drawCircle(
        point,
        radius,
        index.isEven ? neutralGrain : greenGrain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorkloopTexturePainter oldDelegate) {
    return background != oldDelegate.background ||
        raised != oldDelegate.raised ||
        accent != oldDelegate.accent ||
        dark != oldDelegate.dark;
  }
}

class WorkloopSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final VoidCallback? onTap;

  const WorkloopSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.radius = AppRadius.md,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      padding: padding,
      color: color,
      borderColor: borderColor,
      radius: radius,
      elevated: elevated,
      onTap: onTap,
      child: child,
    );
  }
}

class WorkloopPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final List<Widget> metrics;

  const WorkloopPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.metrics = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SlateFeatureHeader(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      trailing: trailing,
      stats: metrics,
    );
  }
}

class WorkloopMetricRow extends StatelessWidget {
  final List<Widget> children;

  const WorkloopMetricRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens.divider.withValues(alpha: 0.62)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1)
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  color: tokens.divider.withValues(alpha: 0.62),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkloopMetricItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const WorkloopMetricItem({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SlateHeaderStat(value: value, label: label, color: color);
  }
}

class WorkloopSectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WorkloopSectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SlateSectionHeader(
      label: label,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class WorkloopDivider extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const WorkloopDivider({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: margin,
      child: Divider(
        height: 1,
        thickness: 1,
        color: tokens.divider.withValues(alpha: 0.66),
      ),
    );
  }
}

class WorkloopListRow extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showDivider;

  const WorkloopListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return SlateListRow(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      padding: padding,
      showDivider: showDivider,
    );
  }
}

class WorkloopEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const WorkloopEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    if (action == null) {
      return SlateEmptyState(icon: icon, title: title, subtitle: subtitle);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SlateEmptyState(icon: icon, title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.sm),
        action!,
      ],
    );
  }
}

class WorkloopPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;
  final bool secondary;

  const WorkloopPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SlateButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      destructive: destructive,
      secondary: secondary,
    );
  }
}

class WorkloopTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  const WorkloopTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              SlateHaptics.tap();
              onPressed!();
            },
      style: TextButton.styleFrom(
        foregroundColor: destructive ? AppColors.error : AppColors.t2,
        minimumSize: const Size(0, 42),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class WorkloopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final Widget? badge;
  final String? semanticLabel;

  const WorkloopIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.size = AppSpacing.minTouch,
    this.badge,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SlateIconButton(
      icon: icon,
      onTap: onTap,
      color: color,
      backgroundColor: backgroundColor,
      size: size,
      badge: badge,
      semanticLabel: semanticLabel,
    );
  }
}

class WorkloopPickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;

  const WorkloopPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
  });
}

/// Canonical search field used by list and picker surfaces.
class WorkloopSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;
  final String semanticLabel;

  const WorkloopSearchField({
    super.key,
    this.controller,
    required this.onChanged,
    this.hintText = 'Search',
    this.autofocus = false,
    this.semanticLabel = 'Search',
  });

  @override
  State<WorkloopSearchField> createState() => _WorkloopSearchFieldState();
}

class _WorkloopSearchFieldState extends State<WorkloopSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _clear() {
    SlateHaptics.selection();
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onChanged: widget.onChanged,
        style: TextStyle(color: tokens.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(
            LucideIcons.search,
            color: tokens.textTertiary,
            size: 18,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clear,
                  icon: Icon(
                    LucideIcons.x,
                    color: tokens.textTertiary,
                    size: 17,
                  ),
                ),
          filled: true,
          fillColor: tokens.surfaceRaised.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide(
              color: tokens.divider.withValues(alpha: 0.72),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide(
              color: tokens.divider.withValues(alpha: 0.72),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide(color: tokens.accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}

/// A mobile-first alternative to Flutter's desktop-style dropdown menu.
///
/// Long lists become searchable automatically and every picker uses the same
/// rounded, keyboard-safe sheet and selection treatment.
class WorkloopPickerField<T> extends StatelessWidget {
  final T? value;
  final List<WorkloopPickerOption<T>> options;
  final ValueChanged<T> onChanged;
  final String title;
  final String hint;
  final String searchHint;
  final IconData? leadingIcon;
  final bool searchable;
  final bool enabled;
  final Color accentColor;

  const WorkloopPickerField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.title,
    required this.hint,
    this.searchHint = 'Search',
    this.leadingIcon,
    this.searchable = false,
    this.enabled = true,
    this.accentColor = AppColors.accentPrimary,
  });

  WorkloopPickerOption<T>? get _selectedOption {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _showPicker(BuildContext context) async {
    if (!enabled || options.isEmpty) return;
    SlateHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: SlateTheme.of(context).scrim,
      builder: (sheetContext) => _WorkloopPickerSheet<T>(
        title: title,
        searchHint: searchHint,
        selected: value,
        options: options,
        searchable: searchable || options.length > 8,
        accentColor: accentColor,
        onSelected: (selected) {
          Navigator.pop(sheetContext);
          SlateHaptics.tap();
          onChanged(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final selected = _selectedOption;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _showPicker(context) : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: tokens.divider.withValues(alpha: 0.72)),
          ),
          child: Row(
            children: [
              if (selected?.leading != null || leadingIcon != null) ...[
                selected?.leading ??
                    Icon(leadingIcon, color: tokens.textTertiary, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  selected?.label ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected == null
                        ? tokens.textTertiary
                        : tokens.textPrimary,
                    fontSize: 15,
                    fontWeight: selected == null
                        ? FontWeight.w600
                        : FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: enabled ? tokens.textTertiary : tokens.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkloopPickerSheet<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final T? selected;
  final List<WorkloopPickerOption<T>> options;
  final bool searchable;
  final Color accentColor;
  final ValueChanged<T> onSelected;

  const _WorkloopPickerSheet({
    required this.title,
    required this.searchHint,
    required this.selected,
    required this.options,
    required this.searchable,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  State<_WorkloopPickerSheet<T>> createState() =>
      _WorkloopPickerSheetState<T>();
}

class _WorkloopPickerSheetState<T> extends State<_WorkloopPickerSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkloopPickerOption<T>> get _filteredOptions {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options.where((option) {
      return option.label.toLowerCase().contains(query) ||
          (option.subtitle?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.options.length > 6 ? 0.78 : 0.55,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        final filtered = _filteredOptions;
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border.all(color: tokens.divider.withValues(alpha: 0.62)),
            boxShadow: AppShadows.glass,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.textPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                    ),
                    WorkloopIconButton(
                      icon: LucideIcons.x,
                      semanticLabel: 'Close ${widget.title}',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(LucideIcons.x, size: 17),
                            ),
                      filled: true,
                      fillColor: tokens.textPrimary.withValues(alpha: 0.035),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide(
                          color: tokens.divider.withValues(alpha: 0.62),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide(
                          color: tokens.divider.withValues(alpha: 0.62),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide(
                          color: widget.accentColor.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(
                            color: tokens.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final selected = option.value == widget.selected;
                          return _WorkloopPickerRow<T>(
                            option: option,
                            selected: selected,
                            accentColor: widget.accentColor,
                            onTap: () => widget.onSelected(option.value),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkloopPickerRow<T> extends StatelessWidget {
  final WorkloopPickerOption<T> option;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _WorkloopPickerRow({
    required this.option,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Material(
      color: selected
          ? accentColor.withValues(alpha: 0.09)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (option.leading != null) ...[
                option.leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w700,
                      ),
                    ),
                    if (option.subtitle?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        option.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check, color: accentColor, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkloopSegment<T> {
  final T value;
  final String label;
  final String? badge;

  const WorkloopSegment({required this.value, required this.label, this.badge});
}

class WorkloopSegmentedControl<T> extends StatelessWidget {
  final List<WorkloopSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const WorkloopSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final selectedIndex = segments.indexWhere(
      (segment) => segment.value == selected,
    );

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: tokens.textPrimary.withValues(alpha: 0.028),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tokens.divider.withValues(alpha: 0.54)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.deliberate,
                curve: AppMotion.emphasized,
                left: (selectedIndex < 0 ? 0 : selectedIndex) * width,
                top: 3,
                bottom: 3,
                width: width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.accentStrong.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: tokens.accentStrong.withValues(alpha: 0.54),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: _WorkloopSegmentButton<T>(
                        segment: segment,
                        selected: segment.value == selected,
                        onTap: () {
                          SlateHaptics.tap();
                          onChanged(segment.value);
                        },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A draggable glass navigation capsule shared by feature workspaces.
///
/// This mirrors the interaction and geometry of the bottom navigation and the
/// Clients workspace rail. Use it for peer destinations; use
/// [WorkloopSegmentedControl] for compact filters.
class WorkloopNavigationControl<T> extends StatelessWidget {
  final List<WorkloopSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color color;

  const WorkloopNavigationControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.color = AppColors.accentPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final selectedIndex = segments.indexWhere(
      (segment) => segment.value == selected,
    );
    return SlateGlassSurface(
      blur: 22,
      color: tokens.surface.withValues(alpha: 0.90),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: SizedBox(
        height: 54,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / segments.length;

            void select(T value) {
              if (value == selected) return;
              SlateHaptics.tap();
              onChanged(value);
            }

            void handleDrag(double dx) {
              final index = (dx / itemWidth).floor().clamp(
                0,
                segments.length - 1,
              );
              select(segments[index].value);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                handleDrag(details.localPosition.dx);
              },
              onHorizontalDragUpdate: (details) {
                handleDrag(details.localPosition.dx);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedPositioned(
                    duration: AppMotion.deliberate,
                    curve: AppMotion.emphasized,
                    left: (selectedIndex < 0 ? 0 : selectedIndex) * itemWidth,
                    top: 6,
                    width: itemWidth,
                    height: 42,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: color.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final segment in segments)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => select(segment.value),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: AppMotion.standard,
                                style: TextStyle(
                                  color: segment.value == selected
                                      ? tokens.accentInk
                                      : tokens.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                child: Text(
                                  segment.badge == null
                                      ? segment.label
                                      : '${segment.label} ${segment.badge}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkloopSegmentButton<T> extends StatelessWidget {
  final WorkloopSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;

  const _WorkloopSegmentButton({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            segment.badge == null
                ? segment.label
                : '${segment.label} ${segment.badge}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? tokens.textPrimary : tokens.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class WorkloopFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const WorkloopFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlateFilterChip(label: label, selected: selected, onTap: onTap);
  }
}

class WorkloopNavItem {
  final String label;
  final IconData icon;
  final Color color;

  const WorkloopNavItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class WorkloopBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<WorkloopNavItem> items;
  final ValueChanged<int> onTap;

  const WorkloopBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    final tabCount = items.length;
    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottom > 0 ? 2 : AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SlateGlassSurface(
              blur: 26,
              color: tokens.surface.withValues(alpha: 0.90),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: 62,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / tabCount;
                    final left = currentIndex * tabWidth;

                    int indexForPosition(double dx) {
                      return (dx / tabWidth).floor().clamp(0, tabCount - 1);
                    }

                    void handleDrag(double dx) {
                      final index = indexForPosition(dx);
                      if (index != currentIndex) {
                        SlateHaptics.tap();
                        onTap(index);
                      }
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (details) {
                        handleDrag(details.localPosition.dx);
                      },
                      onHorizontalDragUpdate: (details) {
                        handleDrag(details.localPosition.dx);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedPositioned(
                            duration: AppMotion.deliberate,
                            curve: AppMotion.emphasized,
                            left: left,
                            top: 9,
                            width: tabWidth,
                            height: 44,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: items[currentIndex].color.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: items[currentIndex].color.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(
                              tabCount,
                              (index) =>
                                  Expanded(child: _buildTab(context, index)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final tokens = SlateTheme.of(context);
    final tab = items[index];
    final active = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index != currentIndex) SlateHaptics.tap();
        onTap(index);
      },
      child: Container(
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1,
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              child: Icon(
                tab.icon,
                color: active ? tokens.accentInk : tokens.textTertiary,
                size: 18,
              ),
            ),
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            color: tokens.accentInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkloopFAB extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;

  const WorkloopFAB({
    super.key,
    required this.onTap,
    this.icon = LucideIcons.plus,
  });

  @override
  State<WorkloopFAB> createState() => _WorkloopFABState();
}

class _WorkloopFABState extends State<WorkloopFAB> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return SlateGlassSurface(
      radius: AppRadius.pill,
      blur: 24,
      color: AppColors.accentPrimaryStrong,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          SlateHaptics.confirm();
          widget.onTap();
        },
        child: AnimatedScale(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          scale: _pressed ? 0.96 : 1,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Icon(widget.icon, color: AppColors.t1, size: 26),
          ),
        ),
      ),
    );
  }
}

class SlateSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final VoidCallback? onTap;

  const SlateSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.radius = AppRadius.md,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final content = AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.curve,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? tokens.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? tokens.divider.withValues(alpha: 0.42),
        ),
        boxShadow: elevated ? AppShadows.soft : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          SlateHaptics.tap();
          onTap!();
        },
        child: content,
      ),
    );
  }
}

class SlateGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? color;

  const SlateGlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = AppRadius.pill,
    this.blur = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? tokens.surfaceRaised.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tokens.divider.withValues(alpha: 0.52)),
            boxShadow: AppShadows.glass,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SlateIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final Widget? badge;
  final String? semanticLabel;

  const SlateIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.size = AppSpacing.minTouch,
    this.badge,
    this.semanticLabel,
  });

  @override
  State<SlateIconButton> createState() => _SlateIconButtonState();
}

class _SlateIconButtonState extends State<SlateIconButton> {
  bool _pressed = false;

  void _handleTap() {
    SlateHaptics.action();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color:
                      widget.backgroundColor ??
                      tokens.textPrimary.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: tokens.divider.withValues(alpha: 0.46),
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color ?? tokens.textSecondary,
                  size: 19,
                ),
              ),
              if (widget.badge != null) widget.badge!,
            ],
          ),
        ),
      ),
    );
  }
}

class SlateSectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SlateSectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            color: tokens.textTertiary,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction == null
                ? null
                : () {
                    SlateHaptics.tap();
                    onAction!();
                  },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentPrimary,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: const StadiumBorder(),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class SlateFeatureHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final List<Widget> stats;

  const SlateFeatureHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: tokens.divider.withValues(alpha: 0.62)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  for (var index = 0; index < stats.length; index++) ...[
                    Expanded(child: stats[index]),
                    if (index != stats.length - 1)
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        color: tokens.divider.withValues(alpha: 0.62),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SlateHeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const SlateHeaderStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SlateEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SlateEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: AppMotion.deliberate,
        curve: AppMotion.curve,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tokens.textPrimary.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tokens.textTertiary, size: 23),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class SlateListRow extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showDivider;

  const SlateListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final row = Container(
      padding: padding,
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: tokens.divider.withValues(alpha: 0.66),
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () {
        SlateHaptics.tap();
        onTap!();
      },
      child: row,
    );
  }
}

class SlateFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SlateFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return GestureDetector(
      onTap: () {
        SlateHaptics.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tokens.accentStrong.withValues(alpha: 0.34)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? tokens.accentStrong.withValues(alpha: 0.54)
                : tokens.divider.withValues(alpha: 0.58),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? tokens.textPrimary : tokens.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class SlateLoadingBlock extends StatelessWidget {
  final double height;
  final double radius;

  const SlateLoadingBlock({
    super.key,
    this.height = 80,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.70),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.t1.withValues(alpha: value * 0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.t1.withValues(alpha: 0.04)),
          ),
        );
      },
    );
  }
}

class SlateErrorState extends StatelessWidget {
  final String message;

  const SlateErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      color: AppColors.errorDim,
      borderColor: AppColors.error.withValues(alpha: 0.22),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.t2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SlateDisclosure extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final EdgeInsetsGeometry childPadding;

  const SlateDisclosure({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.subtitle,
    this.childPadding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    void handleToggle() {
      SlateHaptics.tap();
      onToggle();
    }

    return SlateSurface(
      padding: EdgeInsets.zero,
      radius: AppRadius.lg,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: handleToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.t1.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 17, color: AppColors.t2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.t1,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.t3,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.t3,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(padding: childPadding, child: child),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppMotion.standard,
            firstCurve: AppMotion.curve,
            secondCurve: AppMotion.curve,
            sizeCurve: AppMotion.curve,
          ),
        ],
      ),
    );
  }
}

class SlateButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;
  final bool secondary;

  const SlateButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.secondary = false,
  });

  @override
  State<SlateButton> createState() => _SlateButtonState();
}

class _SlateButtonState extends State<SlateButton> {
  bool _pressed = false;

  void _handleTap() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    if (widget.destructive) {
      SlateHaptics.warning();
    } else if (widget.secondary) {
      SlateHaptics.tap();
    } else {
      SlateHaptics.confirm();
    }
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bg = widget.destructive
        ? AppColors.error
        : widget.secondary
        ? AppColors.t1.withValues(alpha: 0.06)
        : AppColors.accentPrimaryStrong;
    final fg = widget.destructive
        ? Colors.white
        : widget.secondary
        ? AppColors.t2
        : AppColors.t1;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTap: enabled ? _handleTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.48,
          duration: AppMotion.fast,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: widget.secondary
                    ? AppColors.t1.withValues(alpha: 0.06)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SlateSheetFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SlateSheetFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.96, end: 1),
          duration: AppMotion.standard,
          curve: AppMotion.curve,
          builder: (context, value, sheet) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value,
                alignment: Alignment.bottomCenter,
                child: sheet,
              ),
            );
          },
          child: SlateSurface(
            color: AppColors.bgCard.withValues(alpha: 0.96),
            borderColor: AppColors.t1.withValues(alpha: 0.08),
            radius: AppRadius.xl,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            elevated: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.t1.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
