part of 'finance_screen.dart';

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
    return SlateSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.t1.withValues(alpha: 0.028),
      borderColor: AppColors.border.withValues(alpha: 0.54),
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEEKLY TARGET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.t3,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onEditTarget,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.target, size: 13, color: AppColors.t2),
                    SizedBox(width: 5),
                    Text(
                      'Edit target',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.t2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '£${summary.thisWeekPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  hasTarget
                      ? '/ £${summary.weeklyTarget.toStringAsFixed(0)}'
                      : 'this week',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.t3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: hasTarget ? progress : 0,
              backgroundColor: AppColors.panelFaint,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.accentPrimaryStrong,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FinanceComparePill(
                  label: 'vs last week',
                  value: summary.weekDelta,
                  percent: summary.weekDeltaPercent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TargetLeftPill(
                  label: hasTarget ? 'left' : 'target',
                  value: hasTarget
                      ? '£${left.toStringAsFixed(0)}'
                      : 'Set monthly target',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceComparePill extends StatelessWidget {
  final String label;
  final double value;
  final double percent;

  const _FinanceComparePill({
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.t3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${positive ? '+' : '-'}£${value.abs().toStringAsFixed(0)} · ${(percent.abs() * 100).toStringAsFixed(0)}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: positive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetLeftPill extends StatelessWidget {
  final String label;
  final String value;

  const _TargetLeftPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.t3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
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
    return SlateSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              color: AppColors.success,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No unpaid money to collect.',
              style: TextStyle(
                color: AppColors.t2,
                fontWeight: FontWeight.w800,
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
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.t1.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.receipt,
                size: 16,
                color: AppColors.t2,
              ),
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
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.t1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyActivity {
  final Payment? payment;
  final Expense? expense;
  final DateTime date;

  const _MoneyActivity._({this.payment, this.expense, required this.date});

  factory _MoneyActivity.payment(Payment payment, DateTime date) {
    return _MoneyActivity._(payment: payment, date: date);
  }

  factory _MoneyActivity.expense(Expense expense, DateTime date) {
    return _MoneyActivity._(expense: expense, date: date);
  }
}
