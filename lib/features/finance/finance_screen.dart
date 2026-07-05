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
import '../../shared/providers/workspace_settings_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import 'add_payment_screen.dart';
import 'widgets/money_summary_widgets.dart';
import 'widgets/payment_cards.dart';

part 'finance_screen_widgets.dart';

enum FinanceInitialFocus { top, followUps }

class FinanceScreen extends ConsumerStatefulWidget {
  final FinanceInitialFocus initialFocus;

  const FinanceScreen({super.key, this.initialFocus = FinanceInitialFocus.top});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  FinancePeriod _period = FinancePeriod.week;
  DateTime? _customStart;
  DateTime? _customEnd;
  final _scrollController = ScrollController();
  final _followUpsKey = GlobalKey();
  bool _didApplyInitialFocus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialFocus());
  }

  @override
  void didUpdateWidget(covariant FinanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocus != oldWidget.initialFocus &&
        widget.initialFocus == FinanceInitialFocus.followUps) {
      _didApplyInitialFocus = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialFocus());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyInitialFocus() {
    if (!mounted ||
        _didApplyInitialFocus ||
        widget.initialFocus != FinanceInitialFocus.followUps) {
      return;
    }
    final targetContext = _followUpsKey.currentContext;
    if (targetContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialFocus());
      return;
    }
    _didApplyInitialFocus = true;
    Scrollable.ensureVisible(
      targetContext,
      duration: AppMotion.standard,
      curve: AppMotion.curve,
      alignment: 0.08,
    );
  }

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
            SlateHaptics.action();
            ref.invalidate(invoicesProvider);
            ref.invalidate(expensesProvider);
            ref.invalidate(financeSummaryProvider);
            ref.invalidate(dashboardRevenueProvider);
            ref.invalidate(clientCrmRecordsProvider);
          },
          color: AppColors.green,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageX,
              AppSpacing.lg,
              AppSpacing.pageX,
              110,
            ),
            children: [
              SlateFeatureHeader(
                icon: LucideIcons.banknote,
                title: 'Money',
                subtitle: 'See income, expenses, net, and what is still due.',
                color: AppColors.modFinance,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlateIconButton(
                      icon: LucideIcons.plus,
                      semanticLabel: 'Record payment',
                      color: AppColors.modFinance,
                      backgroundColor: AppColors.modFinance.withValues(
                        alpha: 0.10,
                      ),
                      onTap: () => _recordPayment(context),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SlateIconButton(
                      icon: LucideIcons.receipt,
                      semanticLabel: 'Add expense',
                      color: AppColors.modFinance,
                      backgroundColor: AppColors.modFinance.withValues(
                        alpha: 0.10,
                      ),
                      onTap: () => _showExpenseSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              summary.when(
                loading: () => const SlateLoadingBlock(height: 240, radius: 22),
                error: (_, __) =>
                    const SlateErrorState(message: 'Could not load finances'),
                data: (data) => invoices.when(
                  loading: () =>
                      const SlateLoadingBlock(height: 240, radius: 22),
                  error: (_, __) =>
                      const SlateErrorState(message: 'Could not load payments'),
                  data: (payments) => expenses.when(
                    loading: () =>
                        const SlateLoadingBlock(height: 240, radius: 22),
                    error: (_, __) => const SlateErrorState(
                      message: 'Could not load expenses',
                    ),
                    data: (expenseRows) {
                      final range = _selectedRange();
                      final periodSummary = PeriodMoneySummary.from(
                        payments: payments,
                        expenses: expenseRows,
                        range: range,
                      );
                      return Column(
                        children: [
                          _WeeklyTargetCard(
                            summary: data,
                            onEditTarget: () => _showTargetSheet(context, data),
                          ),
                          const SizedBox(height: 12),
                          MoneyPeriodSwitcher(
                            selected: _period,
                            customLabel: _period == FinancePeriod.custom
                                ? range.label
                                : null,
                            onSelected: (period) async {
                              if (period == FinancePeriod.custom) {
                                await _showCustomPeriodSheet(context);
                                return;
                              }
                              setState(() => _period = period);
                            },
                          ),
                          const SizedBox(height: 12),
                          MoneySnapshot(summary: periodSummary),
                          const SizedBox(height: 12),
                          ExpenseCategorySummary(summary: periodSummary),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 22),
              invoices.when(
                loading: () => _skeletonList(),
                error: (_, __) =>
                    const SlateErrorState(message: 'Could not load payments'),
                data: (payments) {
                  final overdue =
                      payments
                          .where(
                            (p) => moneyStatusFor(p) == MoneyStatus.overdue,
                          )
                          .toList()
                        ..sort(
                          (a, b) => (a.dueDate ?? a.issueDate).compareTo(
                            b.dueDate ?? b.issueDate,
                          ),
                        );
                  final upcoming =
                      payments
                          .where((p) => moneyStatusFor(p) == MoneyStatus.unpaid)
                          .toList()
                        ..sort(
                          (a, b) => (a.dueDate ?? a.issueDate).compareTo(
                            b.dueDate ?? b.issueDate,
                          ),
                        );
                  if (payments.isEmpty) return _emptyState(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KeyedSubtree(
                        key: _followUpsKey,
                        child: const SlateSectionHeader(
                          label: 'Money to collect',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (overdue.isEmpty && upcoming.isEmpty)
                        const _QuietMoneyState()
                      else ...[
                        if (overdue.isNotEmpty) ...[
                          const _MoneyCollectGroupHeader(label: 'Overdue'),
                          ...overdue.map(
                            (p) => PaymentCard(
                              payment: p,
                              onTap: () => _showPaymentActionsSheet(context, p),
                              onDelete: () => _confirmDeletePayment(context, p),
                            ),
                          ),
                        ],
                        if (upcoming.isNotEmpty) ...[
                          const _MoneyCollectGroupHeader(
                            label: 'Due soon / Upcoming',
                          ),
                          ...upcoming
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
                        ],
                      ],
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

  void _refreshPayment(Payment payment) {
    _refreshMoney();
    if (payment.appointmentId != null) {
      ref.invalidate(appointmentPaymentsProvider(payment.appointmentId!));
    }
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
          onTap: () => _showExpenseSheet(context, expense: expense),
          onDelete: () => _confirmDeleteExpense(context, expense),
        );
      }).toList(),
    );
  }

  MoneyPeriodRange _selectedRange() {
    final now = DateTime.now();
    switch (_period) {
      case FinancePeriod.week:
        final start = startOfWeek(now);
        return MoneyPeriodRange(
          start: start,
          end: start.add(const Duration(days: 7)),
          label: 'This week',
        );
      case FinancePeriod.month:
        final start = DateTime(now.year, now.month, 1);
        return MoneyPeriodRange(
          start: start,
          end: DateTime(now.year, now.month + 1, 1),
          label: 'This month',
        );
      case FinancePeriod.custom:
        final start = _customStart ?? DateTime(now.year, now.month, 1);
        final end = _customEnd ?? now;
        return MoneyPeriodRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(
            end.year,
            end.month,
            end.day,
          ).add(const Duration(days: 1)),
          label: '${_formatDate(start)} - ${_formatDate(end)}',
        );
    }
  }

  Future<void> _showCustomPeriodSheet(BuildContext context) async {
    var start =
        _customStart ?? DateTime.now().subtract(const Duration(days: 29));
    var end = _customEnd ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickStart() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: start,
              firstDate: DateTime.now().subtract(const Duration(days: 730)),
              lastDate: end,
            );
            if (picked != null) setSheetState(() => start = picked);
          }

          Future<void> pickEnd() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: end,
              firstDate: start,
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setSheetState(() => end = picked);
          }

          return SlateSheetFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom period',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DatePickTile(
                        label: 'From',
                        value: _formatDate(start),
                        onTap: pickStart,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DatePickTile(
                        label: 'To',
                        value: _formatDate(end),
                        onTap: pickEnd,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SlateButton(
                  label: 'Apply Period',
                  icon: LucideIcons.calendarRange,
                  onPressed: () {
                    setState(() {
                      _period = FinancePeriod.custom;
                      _customStart = start;
                      _customEnd = end;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTargetSheet(BuildContext context, FinanceSummary summary) {
    final monthlyController = TextEditingController(
      text: summary.monthlyTarget > 0
          ? summary.monthlyTarget.toStringAsFixed(0)
          : '',
    );
    final weeklyController = TextEditingController(
      text: summary.weeklyTarget > 0
          ? summary.weeklyTarget.toStringAsFixed(0)
          : '',
    );
    var mode = 'monthly';
    var saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> save() async {
            final raw = mode == 'monthly'
                ? monthlyController.text.trim()
                : weeklyController.text.trim();
            final value = double.tryParse(raw);
            if (value == null || value < 0) return;
            final monthlyTarget = mode == 'monthly' ? value : value * 4.345;
            setSheetState(() => saving = true);
            final workspaceId = await ref.read(workspaceIdProvider.future);
            if (workspaceId == null) return;
            try {
              await ref.read(workspaceSettingsRepositoryProvider).update(
                workspaceId,
                {'revenue_target': monthlyTarget},
              );
              ref.invalidate(workspaceSettingsProvider);
              ref.invalidate(financeSummaryProvider);
              ref.invalidate(dashboardRevenueProvider);
              if (context.mounted) Navigator.pop(ctx);
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not update target: $error'),
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
                    'Money target',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ModePills(
                    selected: mode,
                    options: const {'monthly': 'Monthly', 'weekly': 'Weekly'},
                    onSelected: (value) => setSheetState(() => mode = value),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: mode == 'monthly'
                        ? monthlyController
                        : weeklyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      prefixText: '£ ',
                      hintText: '0',
                      labelText: mode == 'monthly'
                          ? 'Monthly target'
                          : 'Weekly target',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mode == 'monthly'
                        ? 'Workloop will show a weekly target of roughly one quarter of this.'
                        : 'Workloop will save this as a monthly target for the rest of the app.',
                    style: const TextStyle(fontSize: 12, color: AppColors.t3),
                  ),
                  const SizedBox(height: 18),
                  SlateButton(
                    label: saving ? 'Saving...' : 'Save Target',
                    icon: LucideIcons.target,
                    onPressed: saving ? null : save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      monthlyController.dispose();
      weeklyController.dispose();
    });
  }

  void _showExpenseSheet(BuildContext context, {Expense? expense}) {
    final amountController = TextEditingController(
      text: expense == null
          ? ''
          : expense.amount.toStringAsFixed(
              expense.amount.truncateToDouble() == expense.amount ? 0 : 2,
            ),
    );
    final notesController = TextEditingController(text: expense?.notes ?? '');
    var category = expense?.category ?? 'Materials';
    var date = expense?.expenseDate ?? DateTime.now();
    var saving = false;
    final editing = expense != null;

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
              if (editing) {
                await ref
                    .read(expensesRepositoryProvider)
                    .update(
                      expenseId: expense.id,
                      amount: amount,
                      category: category,
                      date: date,
                      notes: notesController.text,
                    );
              } else {
                await ref
                    .read(expensesRepositoryProvider)
                    .create(
                      workspaceId: workspaceId,
                      amount: amount,
                      category: category,
                      date: date,
                      notes: notesController.text,
                    );
              }
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
                  Text(
                    editing ? 'Edit expense' : 'Add expense',
                    style: const TextStyle(
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
                    label: saving
                        ? 'Saving...'
                        : editing
                        ? 'Save Expense'
                        : 'Add Expense',
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.76,
          ),
          child: SingleChildScrollView(
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
                        payment.status == 'paid'
                            ? 'PAYMENT RECEIVED'
                            : 'PAYMENT',
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.t3,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.t3,
                          ),
                        ),
                      ],
                      if (payment.appointmentId != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.t1.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.calendarCheck,
                                size: 13,
                                color: AppColors.t2,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Linked to booking',
                                style: TextStyle(
                                  color: AppColors.t2,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
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
                      _refreshPayment(payment);
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
                const SizedBox(height: 2),
              ],
            ),
          ),
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
    _refreshPayment(payment);
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
                _refreshPayment(payment);
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
