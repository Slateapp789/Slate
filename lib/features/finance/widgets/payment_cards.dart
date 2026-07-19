import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/providers/finance_provider.dart';
import '../../../shared/utils/date_format.dart';

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
    final description = _cleanDemoText(payment.notes ?? '');
    final status = moneyStatusFor(payment);
    final isOverdue = status == MoneyStatus.overdue;
    final isPending = status == MoneyStatus.unpaid;
    final isPaid = status == MoneyStatus.paid;

    final statusColor = isPaid
        ? AppColors.success
        : isOverdue
        ? AppColors.t2
        : isPending
        ? AppColors.t3
        : AppColors.t3;

    final statusLabel = isPaid
        ? 'Paid'
        : isOverdue
        ? 'Overdue'
        : isPending
        ? 'Pending'
        : payment.status;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.t1.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isPaid
                      ? LucideIcons.check
                      : isOverdue
                      ? LucideIcons.clock3
                      : LucideIcons.clock3,
                  size: 15,
                  color: statusColor,
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
                      fontWeight: FontWeight.w800,
                      color: AppColors.t1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  '£${(isPaid ? receivedAmountFor(payment) : outstandingAmountFor(payment)).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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

  String _dateSubtitle(Payment payment) {
    if (payment.status == 'paid') {
      return 'Received ${slateShortDate(displayReceivedDate(payment))}';
    }
    final dueDate = payment.dueDate;
    if (dueDate == null || dueDate.millisecondsSinceEpoch == 0) {
      return 'Created ${slateShortDate(payment.issueDate)}';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return 'Due ${slateShortDate(dueDate)} · ${diff.abs()}d late';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${slateShortDate(dueDate)} · ${diff}d';
  }

  String _cleanDemoText(String value) {
    return value.replaceAll('[Slate demo]', '').trim();
  }
}
