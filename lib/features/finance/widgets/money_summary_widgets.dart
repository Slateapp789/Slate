import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/finance_provider.dart';
import '../../../shared/widgets/slate_ui.dart';

enum FinancePeriod { week, month, custom }

class MoneyPeriodSwitcher extends StatelessWidget {
  final FinancePeriod selected;
  final String? customLabel;
  final ValueChanged<FinancePeriod> onSelected;

  const MoneyPeriodSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      padding: const EdgeInsets.all(6),
      radius: AppRadius.pill,
      color: AppColors.t1.withValues(alpha: 0.028),
      borderColor: AppColors.border.withValues(alpha: 0.54),
      child: Row(
        children: [
          _periodOption('Week', FinancePeriod.week),
          _periodOption('Month', FinancePeriod.month),
          _periodOption(customLabel ?? 'Custom', FinancePeriod.custom),
        ],
      ),
    );
  }

  Widget _periodOption(String label, FinancePeriod period) {
    final active = selected == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(period),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentPrimaryStrong.withValues(alpha: 0.34)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active
                  ? AppColors.accentPrimaryStrong.withValues(alpha: 0.54)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.t1 : AppColors.t3,
            ),
          ),
        ),
      ),
    );
  }
}

class MoneySnapshot extends StatelessWidget {
  final PeriodMoneySummary summary;

  const MoneySnapshot({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.profit >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.walletCards,
              color: AppColors.modFinance,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cashflow',
                    style: TextStyle(
                      color: AppColors.t1,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    summary.label,
                    style: const TextStyle(
                      color: AppColors.t3,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: netPositive ? AppColors.greenDim : AppColors.errorDim,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: netPositive
                      ? AppColors.green.withValues(alpha: 0.22)
                      : AppColors.error.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                netPositive ? 'Net positive' : 'Net down',
                style: TextStyle(
                  color: netPositive ? AppColors.green : AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: netPositive
                    ? AppColors.success.withValues(alpha: 0.14)
                    : AppColors.error.withValues(alpha: 0.16),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _CashflowValue(
                  label: 'Net',
                  value: summary.profit,
                  size: 40,
                  color: netPositive ? AppColors.success : AppColors.error,
                ),
              ),
              Icon(
                netPositive
                    ? LucideIcons.arrowUpRight
                    : LucideIcons.arrowDownRight,
                color: netPositive ? AppColors.success : AppColors.error,
                size: 30,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _CashflowTile(
                icon: LucideIcons.trendingUp,
                label: 'Income',
                value: summary.paid,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CashflowTile(
                icon: LucideIcons.receipt,
                label: 'Expenses',
                value: summary.expenses,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _CashflowTile(
          icon: LucideIcons.clock3,
          label: 'To collect',
          value: summary.toCollect,
          color: summary.toCollect > 0 ? AppColors.warning : AppColors.t3,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _CashflowValue extends StatelessWidget {
  final String label;
  final double value;
  final double size;
  final Color color;

  const _CashflowValue({
    required this.label,
    required this.value,
    required this.size,
    required this.color,
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
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '£${value.toStringAsFixed(0)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _CashflowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool fullWidth;

  const _CashflowTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.58)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _CashflowValue(
              label: label,
              value: value,
              size: 24,
              color: AppColors.t1,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseCategorySummary extends StatelessWidget {
  final PeriodMoneySummary summary;

  const ExpenseCategorySummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final categories = summary.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'EXPENSE CATEGORIES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t3,
                ),
              ),
            ),
            Text(
              summary.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.t3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty)
          const Text(
            'No expenses in this period.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.t3,
            ),
          )
        else
          ...categories
              .take(4)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryBar(
                    label: entry.key,
                    amount: entry.value,
                    total: summary.expenses,
                  ),
                ),
              ),
      ],
    );
  }
}

class DatePickTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const DatePickTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgInteract,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
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
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
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

class ModePills extends StatelessWidget {
  final String selected;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  const ModePills({
    super.key,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(
            child: _ModePill(
              entry: entries[i],
              selected: selected,
              onSelected: onSelected,
            ),
          ),
          if (i != entries.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  final MapEntry<String, String> entry;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ModePill({
    required this.entry,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == entry.key;
    return GestureDetector(
      onTap: () => onSelected(entry.key),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.t1.withValues(alpha: 0.10)
              : AppColors.bgInteract,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active
                ? AppColors.t1.withValues(alpha: 0.16)
                : AppColors.border,
          ),
        ),
        child: Text(
          entry.value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: active ? AppColors.t1 : AppColors.t3,
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double amount;
  final double total;

  const _CategoryBar({
    required this.label,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t2,
                ),
              ),
            ),
            Text(
              '£${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.t1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: AppColors.t1.withValues(alpha: 0.06),
            valueColor: const AlwaysStoppedAnimation(AppColors.t1),
          ),
        ),
      ],
    );
  }
}
