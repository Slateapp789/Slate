import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';

class PaymentSummaryCard extends StatelessWidget {
  final List<Payment> payments;
  const PaymentSummaryCard({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    double received = 0;
    double outstanding = 0;
    int overdueCount = 0;

    for (final payment in payments) {
      if (payment.status == 'paid') {
        received += payment.total;
      } else if (payment.status == 'sent') {
        outstanding += payment.total;
      } else if (payment.status == 'overdue') {
        outstanding += payment.total;
        overdueCount++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.panelSoftRaised),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL RECEIVED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
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
              letterSpacing: -2.0,
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
                    borderRadius: BorderRadius.circular(999),
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
    final isPending = payment.status == 'sent';
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue
                ? AppColors.error.withValues(alpha: 0.3)
                : isPending
                ? AppColors.warning.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
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
                      _formatDate(payment.issueDate),
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
                    borderRadius: BorderRadius.circular(999),
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
}
