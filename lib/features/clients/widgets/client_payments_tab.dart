import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/providers/clients_provider.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../shared/providers/finance_provider.dart';
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
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyPayments(
            onAction: () async {
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
            },
          );
        }
        final paid = items
            .where((payment) => payment.status == 'paid')
            .fold<double>(0, (sum, payment) => sum + payment.total);
        final outstanding = items
            .where((payment) => payment.status != 'paid')
            .fold<double>(0, (sum, payment) => sum + payment.total);
        return RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async =>
              ref.invalidate(clientPaymentsProvider(clientId)),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PaymentSummary(paid: paid, outstanding: outstanding);
              }
              final payment = items[index - 1];
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
        );
      },
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final double paid;
  final double outstanding;

  const _PaymentSummary({required this.paid, required this.outstanding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'Received',
              value: paid,
              color: AppColors.green,
            ),
          ),
          Container(width: 1, height: 42, color: AppColors.border),
          Expanded(
            child: _Metric(
              label: 'Outstanding',
              value: outstanding,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '£${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.t3,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;
  const _PaymentRow({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = payment.status;
    final amount = payment.total;
    final color = switch (status) {
      'paid' => AppColors.green,
      'overdue' => AppColors.error,
      _ => AppColors.warning,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.banknote, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.notes ?? payment.number.ifEmpty('Payment'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(payment.issueDate),
                    style: const TextStyle(color: AppColors.t3, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '£${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
          ],
        ),
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
          const Icon(LucideIcons.banknote, color: AppColors.t3, size: 32),
          const SizedBox(height: 12),
          const Text(
            'No payments yet',
            style: TextStyle(fontSize: 14, color: AppColors.t3),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '+ Record Payment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
