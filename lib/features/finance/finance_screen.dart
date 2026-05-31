import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider);
    final expenses = ref.watch(expensesProvider);
    final summary = ref.watch(financeSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(invoicesProvider);
            ref.invalidate(expensesProvider);
            ref.invalidate(financeSummaryProvider);
            ref.invalidate(dashboardRevenueProvider);
            ref.invalidate(clientCrmRecordsProvider);
          },
          color: AppColors.green,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageX,
              AppSpacing.lg,
              AppSpacing.pageX,
              110,
            ),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Money',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.t1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  _HeaderAction(
                    label: 'Payment',
                    icon: LucideIcons.plus,
                    onTap: () => _recordPayment(context),
                  ),
                  const SizedBox(width: 8),
                  _HeaderAction(
                    label: 'Expense',
                    icon: LucideIcons.receipt,
                    onTap: () => _showExpenseSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              summary.when(
                loading: () => const SlateLoadingBlock(height: 240, radius: 22),
                error: (_, __) =>
                    const SlateErrorState(message: 'Could not load finances'),
                data: (data) => Column(
                  children: [
                    _WeeklyTargetCard(summary: data),
                    const SizedBox(height: 12),
                    _MoneySnapshot(summary: data),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              invoices.when(
                loading: () => _skeletonList(),
                error: (_, __) =>
                    const SlateErrorState(message: 'Could not load payments'),
                data: (payments) {
                  final followUps =
                      payments.where((p) => p.status != 'paid').toList()
                        ..sort((a, b) {
                          const order = {'overdue': 0, 'sent': 1, 'pending': 2};
                          final aO = order[a.status] ?? 3;
                          final bO = order[b.status] ?? 3;
                          if (aO != bO) return aO.compareTo(bO);
                          return (a.dueDate ?? a.issueDate).compareTo(
                            b.dueDate ?? b.issueDate,
                          );
                        });
                  if (payments.isEmpty) return _emptyState(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SlateSectionHeader(label: 'Needs follow-up'),
                      const SizedBox(height: 8),
                      if (followUps.isEmpty)
                        const _QuietMoneyState()
                      else
                        ...followUps
                            .take(4)
                            .map(
                              (p) => PaymentCard(
                                payment: p,
                                onTap: () =>
                                    _showPaymentActionsSheet(context, p),
                                onDelete: () =>
                                    _confirmDeletePayment(context, p),
                              ),
                            ),
                      const SizedBox(height: 22),
                      const SlateSectionHeader(label: 'Recent activity'),
                      const SizedBox(height: 8),
                      expenses.when(
                        loading: () =>
                            const SlateLoadingBlock(height: 90, radius: 16),
                        error: (_, __) => _activityList(payments, const []),
                        data: (expenseRows) =>
                            _activityList(payments, expenseRows),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonList() {
    return Column(
      children: List.generate(
        4,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: SlateLoadingBlock(height: 76, radius: AppRadius.md),
        ),
      ),
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
                  ref.invalidate(dashboardRevenueProvider);
                  ref.invalidate(clientCrmRecordsProvider);
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

  Future<void> _recordPayment(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
    );
    _refreshMoney();
  }

  void _refreshMoney() {
    ref.invalidate(invoicesProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(financeSummaryProvider);
    ref.invalidate(dashboardRevenueProvider);
    ref.invalidate(clientCrmRecordsProvider);
  }

  Widget _activityList(List<Payment> payments, List<Expense> expenses) {
    final activities = <_MoneyActivity>[
      ...payments.map(
        (payment) => _MoneyActivity.payment(payment, payment.issueDate),
      ),
      ...expenses.map(
        (expense) => _MoneyActivity.expense(expense, expense.expenseDate),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (activities.isEmpty) {
      return const SlateEmptyState(
        icon: LucideIcons.receipt,
        title: 'No money activity yet',
        subtitle: 'Payments and expenses will appear here.',
      );
    }

    return Column(
      children: activities.take(8).map((activity) {
        if (activity.payment != null) {
          final payment = activity.payment!;
          return PaymentCard(
            payment: payment,
            onTap: () => _showPaymentActionsSheet(context, payment),
            onDelete: () => _confirmDeletePayment(context, payment),
          );
        }
        final expense = activity.expense!;
        return _ExpenseRow(
          expense: expense,
          onDelete: () => _confirmDeleteExpense(context, expense),
        );
      }).toList(),
    );
  }

  void _showExpenseSheet(BuildContext context) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    var category = 'Materials';
    var date = DateTime.now();
    var saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 730)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) setSheetState(() => date = picked);
          }

          Future<void> save() async {
            final amount = double.tryParse(amountController.text.trim());
            if (amount == null || amount <= 0) return;
            setSheetState(() => saving = true);
            final workspaceId = await ref.read(workspaceIdProvider.future);
            if (workspaceId == null) return;
            try {
              await ref
                  .read(expensesRepositoryProvider)
                  .create(
                    workspaceId: workspaceId,
                    amount: amount,
                    category: category,
                    date: date,
                    notes: notesController.text,
                  );
              _refreshMoney();
              if (context.mounted) Navigator.pop(ctx);
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not save expense: $error'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } finally {
              if (context.mounted) setSheetState(() => saving = false);
            }
          }

          return SlateSheetFrame(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '£ ',
                      hintText: '0',
                      labelText: 'Amount',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Materials', 'Rent', 'Travel', 'Tools', 'Other']
                        .map((item) {
                          final active = category == item;
                          return GestureDetector(
                            onTap: () => setSheetState(() => category = item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.t1.withValues(alpha: 0.10)
                                    : AppColors.bgInteract,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: active
                                      ? AppColors.t1.withValues(alpha: 0.16)
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: active ? AppColors.t1 : AppColors.t3,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgInteract,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: AppColors.t3,
                            size: 17,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              color: AppColors.t1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.t1),
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'e.g. Colour supplies',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlateButton(
                    label: saving ? 'Saving...' : 'Save Expense',
                    icon: LucideIcons.receipt,
                    onPressed: saving ? null : save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      amountController.dispose();
      notesController.dispose();
    });
  }

  void _confirmDeleteExpense(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete expense?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.t1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${expense.category} · £${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, color: AppColors.t3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SlateButton(
              label: 'Delete Expense',
              destructive: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(expensesRepositoryProvider).delete(expense.id);
                _refreshMoney();
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentActionsSheet(BuildContext context, Payment payment) {
    final clientName = payment.clientName ?? 'Unknown client';
    final amount = payment.total;
    final description = payment.notes ?? '';
    final canMarkPaid =
        payment.status == 'sent' ||
        payment.status == 'pending' ||
        payment.status == 'overdue';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlateSurface(
              padding: const EdgeInsets.all(AppSpacing.lg),
              radius: AppRadius.lg,
              color: AppColors.greenDim,
              borderColor: AppColors.t1.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.status == 'paid' ? 'PAYMENT RECEIVED' : 'PAYMENT',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.t3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.t1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _paymentTiming(payment),
                    style: const TextStyle(fontSize: 13, color: AppColors.t3),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: AppColors.t3),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '£${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (canMarkPaid) ...[
              SlateButton(
                label: 'Mark as Received',
                icon: LucideIcons.checkCircle,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _markPaymentPaid(context, payment);
                },
              ),
              const SizedBox(height: 10),
            ],
            SlateButton(
              label: 'Edit Payment',
              icon: LucideIcons.pencil,
              secondary: true,
              onPressed: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPaymentScreen(payment: payment),
                    ),
                  );
                  ref.invalidate(invoicesProvider);
                  ref.invalidate(dashboardRevenueProvider);
                  ref.invalidate(clientCrmRecordsProvider);
                });
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Delete Payment',
              icon: LucideIcons.trash2,
              destructive: true,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDeletePayment(context, payment);
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Close',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaymentPaid(BuildContext context, Payment payment) async {
    final amount = payment.total;
    await ref.read(paymentsRepositoryProvider).markPaid(payment);
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
    ref.invalidate(clientCrmRecordsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('£${amount.toStringAsFixed(0)} marked as received'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
    }
  }

  void _confirmDeletePayment(BuildContext context, Payment payment) {
    final clientName = payment.clientName ?? 'Unknown';
    final amount = payment.total;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            SlateButton(
              label: 'Delete Payment',
              destructive: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(paymentsRepositoryProvider).delete(payment.id);
                ref.invalidate(invoicesProvider);
                ref.invalidate(dashboardRevenueProvider);
                ref.invalidate(clientCrmRecordsProvider);
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentTiming(Payment payment) {
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

class _HeaderAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.slateLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.t1.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.panelInk, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.panelInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTargetCard extends StatelessWidget {
  final FinanceSummary summary;

  const _WeeklyTargetCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final hasTarget = summary.weeklyTarget > 0;
    final progress = summary.weeklyProgress;
    final left = (summary.weeklyTarget - summary.thisWeekPaid).clamp(
      0,
      double.infinity,
    );
    return SlateSurface(
      padding: const EdgeInsets.all(22),
      color: AppColors.panelSoft,
      borderColor: AppColors.panelSoftRaised,
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEEKLY TARGET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.panelMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '£${summary.thisWeekPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: AppColors.panelInk,
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
                    color: AppColors.panelMuted,
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
              valueColor: const AlwaysStoppedAnimation(AppColors.panelInk),
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

class _MoneySnapshot extends StatelessWidget {
  final FinanceSummary summary;

  const _MoneySnapshot({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      padding: const EdgeInsets.all(16),
      radius: AppRadius.lg,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MoneyMetric(
                  label: 'Paid',
                  value: summary.thisWeekPaid,
                  icon: LucideIcons.checkCircle2,
                ),
              ),
              Expanded(
                child: _MoneyMetric(
                  label: 'Unpaid',
                  value: summary.unpaid,
                  icon: LucideIcons.clock3,
                  danger: summary.overdue > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MoneyMetric(
                  label: 'Expenses',
                  value: summary.thisWeekExpenses,
                  icon: LucideIcons.receipt,
                  muted: summary.thisWeekExpenses == 0,
                ),
              ),
              Expanded(
                child: _MoneyMetric(
                  label: 'Net',
                  value: summary.thisWeekNet,
                  icon: LucideIcons.trendingUp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final bool danger;
  final bool muted;

  const _MoneyMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.danger = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.t1;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color.withValues(alpha: 0.72), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '£${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: muted ? AppColors.t3 : color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t3,
                ),
              ),
            ],
          ),
        ),
      ],
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
        color: AppColors.bgRaised.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.panelMuted,
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
        color: AppColors.bgRaised.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.panelMuted,
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
              color: AppColors.panelInk,
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
              'No unpaid money needs chasing.',
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

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const _ExpenseRow({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
