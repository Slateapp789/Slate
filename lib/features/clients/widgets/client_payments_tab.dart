import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/providers/clients_provider.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/finance_provider.dart';
import '../../../shared/utils/currency_format.dart';
import '../../../shared/widgets/slate_ui.dart';
import '../../finance/add_payment_screen.dart';
import '../providers/client_detail_providers.dart';

class ClientPaymentsTab extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const ClientPaymentsTab({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(clientPaymentsProvider(clientId));
    return payments.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SlateErrorState(
          message: 'Money activity could not be loaded.',
          onRetry: () => ref.invalidate(clientPaymentsProvider(clientId)),
        ),
      ),
      data: (items) {
        Future<void> recordPayment() async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPaymentScreen(initialClientId: clientId),
            ),
          );
          ref.invalidate(clientPaymentsProvider(clientId));
          ref.invalidate(invoicesProvider);
          ref.invalidate(dashboardRevenueProvider);
          ref.invalidate(clientCrmRecordsProvider);
        }

        if (items.isEmpty) {
          return _EmptyPayments(onAction: recordPayment);
        }
        final received = items.fold<double>(
          0,
          (sum, payment) => sum + payment.amountPaid,
        );
        final remaining = items.fold<double>(
          0,
          (sum, payment) =>
              sum +
              (payment.total - payment.amountPaid).clamp(0, double.infinity),
        );
        return Column(
          children: [
            _PaymentsToolbar(
              received: received,
              remaining: remaining,
              onRecord: recordPayment,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.green,
                onRefresh: () async =>
                    ref.invalidate(clientPaymentsProvider(clientId)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    final payment = items[index];
                    return _PaymentRow(
                      payment: payment,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPaymentScreen(payment: payment),
                          ),
                        );
                        ref.invalidate(clientPaymentsProvider(clientId));
                        ref.invalidate(invoicesProvider);
                        ref.invalidate(dashboardRevenueProvider);
                        ref.invalidate(clientCrmRecordsProvider);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;
  const _PaymentRow({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final amount = payment.total;
    final remaining = (payment.total - payment.amountPaid).clamp(
      0,
      double.infinity,
    );
    final paid = remaining <= 0;
    final partPaid = !paid && payment.amountPaid > 0;
    final color = paid ? AppColors.success : AppColors.t3;
    final label = paid
        ? 'Paid'
        : partPaid
        ? 'Part paid'
        : 'Unpaid';
    return WorkloopListRow(
      onTap: onTap,
      leading: Icon(LucideIcons.banknote, color: color, size: 18),
      title: Text(
        payment.notes ?? payment.number.ifEmpty('Payment'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _formatDate(payment.issueDate),
        style: const TextStyle(color: AppColors.t3, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatPounds(amount),
            style: const TextStyle(
              color: AppColors.t1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
        ],
      ),
    );
  }
}

class _PaymentsToolbar extends StatelessWidget {
  final double received;
  final double remaining;
  final VoidCallback onRecord;

  const _PaymentsToolbar({
    required this.received,
    required this.remaining,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        AppSpacing.xs,
        AppSpacing.pageX,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${formatPounds(received)} received',
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(width: 8),
            Text(
              '· ${formatPounds(remaining)} left',
              style: const TextStyle(color: AppColors.t3, fontSize: 13),
            ),
          ],
          const Spacer(),
          WorkloopTextButton(label: 'Record', onPressed: onRecord),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _EmptyPayments extends StatelessWidget {
  final VoidCallback onAction;
  const _EmptyPayments({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WorkloopEmptyState(
            icon: LucideIcons.banknote,
            title: 'No payments yet.',
            subtitle:
                'Income and outstanding payments for this client will appear here.',
          ),
          const SizedBox(height: 16),
          WorkloopPrimaryButton(label: 'Record payment', onPressed: onAction),
        ],
      ),
    );
  }
}
