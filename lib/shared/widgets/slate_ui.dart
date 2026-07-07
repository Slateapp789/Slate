import 'dart:ui';

import 'package:flutter/material.dart';
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

  static void tap() {
    HapticFeedback.selectionClick();
  }

  static void action() {
    HapticFeedback.lightImpact();
  }

  static void confirm() {
    HapticFeedback.mediumImpact();
  }

  static void warning() {
    HapticFeedback.heavyImpact();
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
