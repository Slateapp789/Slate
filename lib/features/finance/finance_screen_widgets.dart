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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.t3,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '£${value.toStringAsFixed(0)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 40,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          style: const TextStyle(
            color: AppColors.t3,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _OutstandingHero extends StatelessWidget {
  final double total;
  final double upcoming;
  final double overdue;

  const _OutstandingHero({
    required this.total,
    required this.upcoming,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outstanding',
          style: TextStyle(
            color: AppColors.t3,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '£${total.toStringAsFixed(0)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 40,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        WorkloopMetricRow(
          children: [
            WorkloopMetricItem(
              value: '£${upcoming.toStringAsFixed(0)}',
              label: 'Upcoming',
              color: AppColors.t1,
            ),
            WorkloopMetricItem(
              value: '£${overdue.toStringAsFixed(0)}',
              label: 'Past due',
              color: AppColors.t1,
            ),
          ],
        ),
      ],
    );
  }
}

class _WeeklyTargetCard extends StatelessWidget {
  final FinanceSummary summary;
  final VoidCallback onEditTarget;

  const _WeeklyTargetCard({required this.summary, required this.onEditTarget});

  @override
  Widget build(BuildContext context) {
    final hasTarget = summary.weeklyTarget > 0;
    final progress = summary.weeklyProgress;
    final left = (summary.weeklyTarget - summary.thisWeekPaid).clamp(
      0,
      double.infinity,
    );
    final change = summary.weekDelta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkloopSectionHeader(
          label: 'Weekly target',
          actionLabel: hasTarget ? 'Edit' : 'Set target',
          onAction: onEditTarget,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasTarget
              ? '£${summary.thisWeekPaid.toStringAsFixed(0)} of £${summary.weeklyTarget.toStringAsFixed(0)}'
              : 'No target set',
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: hasTarget ? progress : 0,
            backgroundColor: AppColors.t1.withValues(alpha: 0.06),
            valueColor: const AlwaysStoppedAnimation(
              AppColors.accentPrimaryStrong,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasTarget
              ? '£${left.toStringAsFixed(0)} left · ${change >= 0 ? '+' : '-'}£${change.abs().toStringAsFixed(0)} compared with last week'
              : 'Set a monthly goal to see gentle weekly progress here.',
          style: const TextStyle(
            color: AppColors.t3,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyCollectGroupHeader extends StatelessWidget {
  final String label;

  const _MoneyCollectGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.t3,
          letterSpacing: 0,
        ),
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
                      fontWeight: FontWeight.w800,
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
              '-£${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.t1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
