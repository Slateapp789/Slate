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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          formatPounds(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 40,
            height: 1,
            fontWeight: FontWeight.w600,
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
    final hasTarget = target > 0;
    final progress = hasTarget ? (made / target).clamp(0.0, 1.0) : 0.0;
    final left = (target - made).clamp(0, double.infinity);
    final percentage = hasTarget ? ((made / target) * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkloopSectionHeader(
          label: label,
          actionLabel: hasTarget ? 'Edit' : 'Set target',
          onAction: onEditTarget,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          hasTarget ? '$percentage% complete' : 'No target set',
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            minHeight: 8,
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
              ? left > 0
                    ? '${formatPounds(made)} of ${formatPounds(target)} · ${formatPounds(left)} left'
                    : '${formatPounds(made)} of ${formatPounds(target)} · Target reached'
              : 'Set an income target to track your progress here.',
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
