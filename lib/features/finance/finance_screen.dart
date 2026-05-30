import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import 'add_payment_screen.dart';
import 'widgets/payment_cards.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.lg,
                AppSpacing.pageX,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Money',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      letterSpacing: 0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddPaymentScreen(),
                        ),
                      );
                      ref.invalidate(invoicesProvider);
                      ref.invalidate(dashboardRevenueProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slateLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.t1.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.plus,
                            color: AppColors.panelInk,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Record',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.panelInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary card
            invoices.when(
              data: (data) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageX,
                ),
                child: PaymentSummaryCard(payments: data),
              ),
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageX,
                ),
                child: const SlateLoadingBlock(height: 130, radius: 20),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: Row(
                children: ['All', 'Outstanding', 'Received', 'Overdue'].map((
                  f,
                ) {
                  final active = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.t1.withValues(alpha: 0.12)
                            : AppColors.t1.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: active
                              ? AppColors.t1.withValues(alpha: 0.18)
                              : AppColors.t1.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.t1 : AppColors.t3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: invoices.when(
                loading: () => _skeletonList(),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageX,
                  ),
                  child: const SlateErrorState(
                    message: 'Could not load payments',
                  ),
                ),
                data: (data) {
                  final filtered = data.where((p) {
                    switch (_filter) {
                      case 'Outstanding':
                        return p.status == 'sent' || p.status == 'pending';
                      case 'Received':
                        return p.status == 'paid';
                      case 'Overdue':
                        return p.status == 'overdue';
                      default:
                        return true;
                    }
                  }).toList();

                  if (data.isEmpty) return _emptyState(context);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No ${_filter.toLowerCase()} payments',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.t3,
                        ),
                      ),
                    );
                  }

                  final sorted = [...filtered]
                    ..sort((a, b) {
                      const order = {'overdue': 0, 'sent': 1, 'paid': 2};
                      final aO = order[a.status] ?? 3;
                      final bO = order[b.status] ?? 3;
                      if (aO != bO) return aO.compareTo(bO);
                      return b.issueDate.compareTo(a.issueDate);
                    });

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(invoicesProvider),
                    color: AppColors.green,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageX,
                        0,
                        AppSpacing.pageX,
                        100,
                      ),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = sorted[i];
                        final isActionable =
                            p.status == 'sent' || p.status == 'overdue';
                        return PaymentCard(
                          payment: p,
                          onTap: isActionable
                              ? () => _showMarkPaidSheet(context, p)
                              : null,
                          onDelete: () => _confirmDeletePayment(context, p),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        40,
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) =>
          const SlateLoadingBlock(height: 76, radius: AppRadius.md),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SlateEmptyState(
              icon: LucideIcons.banknote,
              title: 'No payments yet',
              subtitle: 'Record your first payment to get started',
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
                  );
                  ref.invalidate(invoicesProvider);
                },
                icon: const Icon(LucideIcons.plus, size: 17),
                label: const Text(
                  'Record Payment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkPaidSheet(BuildContext context, Payment payment) {
    final clientName = payment.clientName ?? 'Unknown client';
    final amount = payment.total;
    final description = payment.notes ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.greenDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.t1,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.t3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      '£${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.green,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(paymentsRepositoryProvider)
                        .markPaid(payment);
                    await ref
                        .read(notificationsRepositoryProvider)
                        .create(
                          workspaceId: payment.workspaceId,
                          type: 'payment_received',
                          title: 'Payment received',
                          body:
                              '£${amount.toStringAsFixed(0)} from ${payment.clientName ?? 'a client'} is now paid.',
                          deepLink: '/payments',
                        );
                    ref.invalidate(invoicesProvider);
                    ref.invalidate(dashboardRevenueProvider);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '£${amount.toStringAsFixed(0)} marked as paid',
                          ),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.checkCircle, size: 18),
                  label: const Text(
                    'Mark as Paid',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, Payment payment) {
    final clientName = payment.clientName ?? 'Unknown';
    final amount = payment.total;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delete payment?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$clientName · £${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, color: AppColors.t3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(paymentsRepositoryProvider)
                        .delete(payment.id);
                    ref.invalidate(invoicesProvider);
                    ref.invalidate(dashboardRevenueProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Delete Payment',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.t3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
