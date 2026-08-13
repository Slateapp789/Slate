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
    return WorkloopSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      elevated: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.accentInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  formatPounds(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: tokens.divider),
            ),
            child: Icon(
              LucideIcons.walletCards,
              color: tokens.accentInk,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashMovementGraphic extends StatelessWidget {
  final List<WorkloopStudioBarDatum> data;
  final String periodLabel;

  const _CashMovementGraphic({required this.data, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    final spokenData = data
        .map((item) => '${item.label} ${formatPounds(item.value)}')
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
            children: [
              Expanded(
                child: Text(
                  'Cash movement',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatPounds(total),
                style: TextStyle(
                  color: tokens.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          WorkloopStudioBarChart(
            data: data,
            color: tokens.accent,
            height: 80,
            semanticsLabel: 'Cash movement for $periodLabel: $spokenData',
          ),
        ],
      ),
    );
  }
}

class _IncomeTargetProgress extends StatelessWidget {
  final String label;
  final double made;
  final double target;
  final VoidCallback onEditTarget;

  const _IncomeTargetProgress({
    required this.label,
    required this.made,
    required this.target,
    required this.onEditTarget,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final hasTarget = target > 0;
    final progress = hasTarget ? (made / target).clamp(0.0, 1.0) : 0.0;
    final left = (target - made).clamp(0, double.infinity);
    final percentage = hasTarget ? ((made / target) * 100).round() : 0;
    return WorkloopSurface(
      child: Row(
        children: [
          WorkloopStudioProgressArc(
            progress: progress,
            color: tokens.accent,
            size: 78,
            child: Text(
              hasTarget ? '$percentage%' : '—',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkloopSectionHeader(
                  label: label,
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

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseRow({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.t1.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: Icon(LucideIcons.receipt, size: 17, color: AppColors.t3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.t1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.notes?.isNotEmpty == true
                        ? expense.notes!
                        : 'Expense · ${expense.expenseDate.day}/${expense.expenseDate.month}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.t3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '-${formatPounds(expense.amount)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.t1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
