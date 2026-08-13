import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/slate_ui.dart';

class ObWelcome extends StatelessWidget {
  final VoidCallback onNext;
  const ObWelcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = SlateTheme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.pageX),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: tokens.accentStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.accentBorder),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'WORKLOOP',
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.textPrimary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Run your business.\nNot your admin.',
                  style: textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your bookings, clients, and payments — one app built for people who work for themselves.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.t3,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _OperatingLoopGraphic(),
                const SizedBox(height: AppSpacing.xl),
                const _ValueProp(
                  icon: LucideIcons.calendarDays,
                  text: 'Know exactly what is on today',
                ),
                const SizedBox(height: AppSpacing.md),
                const _ValueProp(
                  icon: LucideIcons.banknote,
                  text: 'Get paid faster, with less chasing',
                ),
                const SizedBox(height: AppSpacing.md),
                const _ValueProp(
                  icon: LucideIcons.users,
                  text: 'Every client, every history, one place',
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.xl),
                SlateButton(
                  label: 'Get started',
                  icon: LucideIcons.arrowRight,
                  onPressed: onNext,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OperatingLoopGraphic extends StatelessWidget {
  const _OperatingLoopGraphic();

  static const _stages = [
    (LucideIcons.userRound, 'Client'),
    (LucideIcons.calendarDays, 'Booking'),
    (LucideIcons.briefcaseBusiness, 'Work'),
    (LucideIcons.circlePoundSterling, 'Pay · repeat'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      label: 'Workloop operating loop: client, booking, work, payment, repeat.',
      child: ExcludeSemantics(
        child: WorkloopSurface(
          color: tokens.inkSurface,
          borderColor: tokens.divider,
          radius: AppRadius.xl,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: SizedBox(
            height: 84,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OperatingLoopPainter(
                          line: tokens.onInkMuted,
                          active: tokens.accentStrong,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (index, stage) in _stages.indexed)
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: AppSpacing.minTouch,
                                  height: AppSpacing.minTouch,
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? tokens.accentStrong
                                        : tokens.onInk.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: index == 0
                                          ? tokens.accentBorder
                                          : tokens.onInk.withValues(
                                              alpha: 0.16,
                                            ),
                                    ),
                                  ),
                                  child: Icon(
                                    stage.$1,
                                    size: 18,
                                    color: index == 0
                                        ? tokens.onAccent
                                        : tokens.onInk,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    stage.$2,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: tokens.onInkMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OperatingLoopPainter extends CustomPainter {
  final Color line;
  final Color active;

  const _OperatingLoopPainter({required this.line, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final y = AppSpacing.xl;
    final first = size.width / 8;
    final last = size.width - first;
    final basePaint = Paint()
      ..color = line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(first, y), Offset(last, y), basePaint);

    final activePaint = Paint()
      ..color = active
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(first, y), Offset(last, y), activePaint);

    final arrowX = last - AppSpacing.xs;
    final arrow = Path()
      ..moveTo(arrowX - AppSpacing.xxs, y - AppSpacing.xxs)
      ..lineTo(arrowX, y)
      ..lineTo(arrowX - AppSpacing.xxs, y + AppSpacing.xxs);
    canvas.drawPath(arrow, activePaint);
  }

  @override
  bool shouldRepaint(_OperatingLoopPainter oldDelegate) {
    return oldDelegate.line != line || oldDelegate.active != active;
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ValueProp({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.t1.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.t3, size: 17),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.t2),
          ),
        ),
      ],
    );
  }
}
