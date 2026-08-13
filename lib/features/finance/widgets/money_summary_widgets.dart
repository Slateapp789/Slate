import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/finance_provider.dart';
import '../../../shared/utils/currency_format.dart';
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
    return WorkloopSegmentedControl<FinancePeriod>(
      selected: selected,
      segments: [
        const WorkloopSegment(value: FinancePeriod.week, label: 'Week'),
        const WorkloopSegment(value: FinancePeriod.month, label: 'Month'),
        WorkloopSegment(
          value: FinancePeriod.custom,
          label: customLabel ?? 'Custom',
        ),
      ],
      onChanged: onSelected,
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
        const WorkloopSectionHeader(label: 'Spending by category'),
        const SizedBox(height: AppSpacing.sm),
        if (categories.isEmpty)
          const Text(
            'No expenses in this period.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
    return Semantics(
      button: true,
      label: '$label, $value',
      hint: 'Choose date',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.bgInteract,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            excludeFromSemantics: true,
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.t1,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return WorkloopSegmentedControl<String>(
      selected: selected,
      segments: options.entries
          .map(
            (entry) =>
                WorkloopSegment<String>(value: entry.key, label: entry.value),
          )
          .toList(growable: false),
      onChanged: onSelected,
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.t2,
                ),
              ),
            ),
            Text(
              formatPounds(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.t1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.capsule),
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
