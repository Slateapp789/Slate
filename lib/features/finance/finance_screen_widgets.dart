part of 'finance_screen.dart';

class _MoneySectionHero extends StatelessWidget {
  final String label;
  final double value;
  final String detail;

  const _MoneySectionHero({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopPaperPanel(
      title: label,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPounds(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const WorkloopIllustration(
            kind: WorkloopIllustrationKind.receipt,
            size: 44,
          ),
        ],
      ),
    );
  }
}

class _NetProfitGraphic extends StatelessWidget {
  final List<WorkloopStudioBarDatum> data;
  final String periodLabel;

  const _NetProfitGraphic({required this.data, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final total = roundToPence(
      data.fold<double>(0, (sum, item) => sum + item.value),
    );
    final spokenData = data
        .map((item) => '${item.label} ${_profitAmount(item.value)}')
        .join(', ');
    return WorkloopSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Net profit',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _profitAmount(total),
                  key: const ValueKey('money-net-profit-total'),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: total < 0 ? tokens.error : tokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Income minus expenses',
            style: TextStyle(color: tokens.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          _NetProfitBarChart(
            data: data,
            semanticsLabel:
                'Net profit for $periodLabel: ${_profitAmount(total)}. '
                'Income minus expenses. $spokenData',
          ),
        ],
      ),
    );
  }
}

String _profitAmount(double value) =>
    value < 0 ? '-${formatPounds(value.abs())}' : formatPounds(value);

/// Signed bars share a zero line so expense-only days cannot look like income.
class _NetProfitBarChart extends StatelessWidget {
  final List<WorkloopStudioBarDatum> data;
  final String semanticsLabel;

  const _NetProfitBarChart({required this.data, required this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final high = data.fold<double>(
      0,
      (value, row) => math.max(value, row.value),
    );
    final low = data.fold<double>(
      0,
      (value, row) => math.min(value, row.value),
    );
    final extent = high - low;
    const plotHeight = 76.0;
    // Leave a little room at either edge for the zero line and zero-value dots.
    const plotInset = 2.0;
    const plotSpace = plotHeight - plotInset * 2;
    final zeroY =
        plotInset + (extent == 0 ? plotSpace : high / extent * plotSpace);
    final labelStyle = TextStyle(
      color: tokens.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      key: const ValueKey('money-net-profit-chart'),
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              children: [
                for (final item in data)
                  Expanded(
                    child: Text(
                      item.valueLabel ?? _profitAmount(item.value),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle.copyWith(
                        color: item.value < 0
                            ? tokens.error
                            : tokens.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: plotHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: zeroY,
                    left: 0,
                    right: 0,
                    child: Container(
                      key: const ValueKey('money-net-profit-zero-line'),
                      height: 1,
                      color: tokens.divider,
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var index = 0; index < data.length; index++)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final value = data[index].value;
                                final height = extent == 0
                                    ? 0.0
                                    : value.abs() / extent * plotSpace;
                                return Stack(
                                  children: [
                                    Positioned(
                                      top: value > 0 ? zeroY - height : zeroY,
                                      left:
                                          (constraints.maxWidth -
                                              math.min(
                                                20.0,
                                                constraints.maxWidth * 0.55,
                                              )) /
                                          2,
                                      child: Container(
                                        key: ValueKey(
                                          'money-net-profit-bar-$index',
                                        ),
                                        width: math.min(
                                          20.0,
                                          constraints.maxWidth * 0.55,
                                        ),
                                        height: math.max(1, height),
                                        decoration: BoxDecoration(
                                          color: value < 0
                                              ? tokens.error
                                              : value > 0
                                              ? tokens.accent
                                              : tokens.dividerStrong,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final item in data)
                  Expanded(
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeTargetProgress extends StatelessWidget {
  final double made;
  final double target;
  final VoidCallback onEditTarget;

  const _IncomeTargetProgress({
    required this.made,
    required this.target,
    required this.onEditTarget,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final hasTarget = target.isFinite && roundToPence(target) > 0;
    final left = roundToPence(target - made).clamp(0, double.infinity);
    return WorkloopSurface(
      child: Row(
        children: [
          WorkloopIncomeTargetIndicator(amount: made, target: target),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkloopSectionHeader(
                  label: 'Monthly target',
                  actionLabel: hasTarget ? 'Edit' : 'Set target',
                  onAction: onEditTarget,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasTarget
                      ? left > 0
                            ? '${formatPounds(left)} left to reach ${formatPounds(target)}'
                            : 'Target reached'
                      : 'Set a target to track progress.',
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietMoneyState extends StatelessWidget {
  const _QuietMoneyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: AppColors.t3, size: 17),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Nothing waiting to be collected.',
              style: TextStyle(
                color: AppColors.t3,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
