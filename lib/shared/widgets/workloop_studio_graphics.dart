import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Four connected nodes representing Client, Booking, Work and Payment.
class WorkloopStudioLoopMark extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? secondaryColor;
  final bool animate;

  const WorkloopStudioLoopMark({
    super.key,
    this.size = 112,
    this.color,
    this.secondaryColor,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    final theme = Theme.of(context);
    final tokens =
        theme.extension<WorkloopThemeTokens>() ??
        (theme.brightness == Brightness.dark
            ? WorkloopThemeTokens.dark
            : WorkloopThemeTokens.light);
    final primary = color ?? tokens.accent;
    final secondary = secondaryColor ?? AppColors.modClients;
    return Semantics(
      image: true,
      label: 'Client, Booking, Work and Payment connected in one loop',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: animate && !reducedMotion ? 0 : 1, end: 1),
          duration: AppMotion.responsive(context, AppMotion.deliberate),
          curve: AppMotion.emphasized,
          builder: (context, progress, _) => CustomPaint(
            size: Size.square(size),
            painter: _StudioLoopPainter(
              primary: primary,
              secondary: secondary,
              progress: progress,
            ),
          ),
        ),
      ),
    );
  }
}

class WorkloopStudioProgressArc extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget? child;

  const WorkloopStudioProgressArc({
    super.key,
    required this.progress,
    required this.color,
    this.size = 84,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens =
        theme.extension<WorkloopThemeTokens>() ??
        (theme.brightness == Brightness.dark
            ? WorkloopThemeTokens.dark
            : WorkloopThemeTokens.light);
    final value = progress.clamp(0.0, 1.0);
    return Semantics(
      label: '${(value * 100).round()} percent complete',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: AppMotion.responsive(context, AppMotion.deliberate),
              curve: AppMotion.curve,
              builder: (context, animatedValue, _) => CustomPaint(
                size: Size.square(size),
                painter: _ProgressArcPainter(
                  progress: animatedValue,
                  track: tokens.divider,
                  color: color,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class WorkloopStudioModuleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const WorkloopStudioModuleIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: size * 0.42),
    );
  }
}

class WorkloopStudioBarDatum {
  final String label;
  final double value;
  final String? valueLabel;

  const WorkloopStudioBarDatum({
    required this.label,
    required this.value,
    this.valueLabel,
  });
}

/// A compact, native Flutter data strip for small sets of comparable values.
/// It intentionally avoids axes and chart furniture so the data remains useful
/// without making Workloop feel like an analytics dashboard.
class WorkloopStudioBarChart extends StatelessWidget {
  final List<WorkloopStudioBarDatum> data;
  final Color color;
  final String semanticsLabel;
  final double height;
  final bool showValues;

  const WorkloopStudioBarChart({
    super.key,
    required this.data,
    required this.color,
    required this.semanticsLabel,
    this.height = 92,
    this.showValues = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<WorkloopThemeTokens>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? WorkloopThemeTokens.dark
            : WorkloopThemeTokens.light);
    final maxValue = data.fold<double>(
      0,
      (largest, item) => math.max(largest, item.value),
    );

    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final item in data)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (showValues)
                                Text(
                                  item.valueLabel ??
                                      item.value.toStringAsFixed(0),
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                    color: tokens.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0,
                                      end: maxValue <= 0
                                          ? 0
                                          : item.value / maxValue,
                                    ),
                                    duration: AppMotion.responsive(
                                      context,
                                      AppMotion.deliberate,
                                    ),
                                    curve: AppMotion.emphasized,
                                    builder: (context, progress, _) =>
                                        FractionallySizedBox(
                                          heightFactor: math.max(
                                            0.07,
                                            progress,
                                          ),
                                          child: Container(
                                            width: 22,
                                            decoration: BoxDecoration(
                                              color: item.value <= 0
                                                  ? tokens.divider
                                                  : color.withValues(
                                                      alpha: 0.9,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.xs,
                                                  ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final item in data)
                    Expanded(
                      child: Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: tokens.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
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
}

class _StudioLoopPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final double progress;

  const _StudioLoopPainter({
    required this.primary,
    required this.secondary,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;
    final path = Path();
    for (var index = 0; index <= 48; index++) {
      final angle = -math.pi / 2 + math.pi * 2 * index / 48;
      final wobble = math.sin(angle * 2) * size.shortestSide * 0.035;
      final point =
          center +
          Offset(
            math.cos(angle) * (radius + wobble),
            math.sin(angle) * (radius - wobble),
          );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.055
        ..strokeCap = StrokeCap.round
        ..color = primary,
    );
    for (var index = 0; index < 4; index++) {
      final nodeProgress = (progress * 5 - index).clamp(0.0, 1.0);
      final angle = -math.pi / 2 + math.pi * 2 * index / 4;
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawCircle(
        point,
        size.shortestSide * 0.075 * nodeProgress,
        Paint()..color = index.isEven ? secondary : primary,
      );
      canvas.drawCircle(
        point,
        size.shortestSide * 0.032 * nodeProgress,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StudioLoopPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.progress != progress;
}

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color color;
  final double strokeWidth;

  const _ProgressArcPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arc = rect.deflate(inset);
    const start = math.pi * 0.72;
    const sweep = math.pi * 1.56;
    canvas.drawArc(
      arc,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = track,
    );
    canvas.drawArc(
      arc,
      start,
      sweep * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
