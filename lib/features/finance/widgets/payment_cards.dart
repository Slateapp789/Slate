import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/widgets/slate_ui.dart';

class PaymentSummaryCard extends StatelessWidget {
  final List<Payment> payments;
  const PaymentSummaryCard({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    double received = 0;
    double outstanding = 0;
    double overdue = 0;
    double thisMonth = 0;
    int overdueCount = 0;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (final payment in payments) {
      if (payment.status == 'paid') {
        received += payment.total;
        if (!payment.issueDate.isBefore(monthStart)) {
          thisMonth += payment.total;
        }
      } else if (payment.status == 'sent' || payment.status == 'pending') {
        outstanding += payment.total;
      } else if (payment.status == 'overdue') {
        outstanding += payment.total;
        overdue += payment.total;
        overdueCount++;
      }
    }

    return SlateSurface(
      padding: const EdgeInsets.all(22),
      color: AppColors.panelSoft,
      borderColor: AppColors.panelSoftRaised,
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL RECEIVED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: AppColors.panelMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '£${received.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppColors.panelInk,
              letterSpacing: 0,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.panelFaint),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OUTSTANDING',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.panelMuted,
                      ),
                    ),
                    Text(
                      '£${outstanding.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: outstanding > 0
                            ? AppColors.panelInk
                            : AppColors.panelInk.withValues(alpha: 0.28),
                      ),
                    ),
                  ],
                ),
              ),
              if (overdueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$overdueCount overdue',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniPaymentMetric(
                  label: 'This month',
                  value: thisMonth,
                  muted: thisMonth == 0,
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.panelFaint),
              Expanded(
                child: _MiniPaymentMetric(
                  label: 'Overdue',
                  value: overdue,
                  muted: overdue == 0,
                  danger: overdue > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPaymentMetric extends StatelessWidget {
  final String label;
  final double value;
  final bool muted;
  final bool danger;

  const _MiniPaymentMetric({
    required this.label,
    required this.value,
    this.muted = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.panelMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '£${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: danger
                  ? AppColors.error
                  : muted
                  ? AppColors.panelInk.withValues(alpha: 0.28)
                  : AppColors.panelInk,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final clientName = payment.clientName ?? 'Unknown';
    final description = payment.notes ?? '';
    final isOverdue = payment.status == 'overdue';
    final isPending = payment.status == 'sent' || payment.status == 'pending';
    final isPaid = payment.status == 'paid';

    final statusColor = isPaid
        ? AppColors.green
        : isOverdue
        ? AppColors.error
        : isPending
        ? AppColors.warning
        : AppColors.t3;

    final statusLabel = isPaid
        ? 'Paid'
        : isOverdue
        ? 'Overdue'
        : isPending
        ? 'Pending'
        : payment.status;

    final initials = clientName
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: SlateSurface(
        padding: const EdgeInsets.all(AppSpacing.md),
        radius: AppRadius.md,
        borderColor: isOverdue
            ? AppColors.error.withValues(alpha: 0.3)
            : isPending
            ? AppColors.warning.withValues(alpha: 0.2)
            : AppColors.t1.withValues(alpha: 0.07),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.t1,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: AppColors.t3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (payment.issueDate.millisecondsSinceEpoch > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      _dateSubtitle(payment),
                      style: const TextStyle(fontSize: 12, color: AppColors.t3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '£${payment.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _dateSubtitle(Payment payment) {
    if (payment.status == 'paid') {
      return 'Received ${_formatDate(payment.issueDate)}';
    }
    final dueDate = payment.dueDate;
    if (dueDate == null || dueDate.millisecondsSinceEpoch == 0) {
      return 'Created ${_formatDate(payment.issueDate)}';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return 'Due ${_formatDate(dueDate)} · ${diff.abs()}d late';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${_formatDate(dueDate)} · ${diff}d';
  }
}
