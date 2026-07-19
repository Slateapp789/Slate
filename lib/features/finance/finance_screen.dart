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
import 'expense_editor_screen.dart';
import 'widgets/money_summary_widgets.dart';
import 'widgets/payment_cards.dart';

part 'finance_screen_widgets.dart';

enum FinanceInitialFocus { top, followUps }

enum MoneySection { income, outgoing, outstanding }

class FinanceScreen extends ConsumerStatefulWidget {
  final FinanceInitialFocus initialFocus;

  const FinanceScreen({super.key, this.initialFocus = FinanceInitialFocus.top});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  MoneySection _section = MoneySection.income;
  FinancePeriod _period = FinancePeriod.week;
  DateTime? _customStart;
  DateTime? _customEnd;
  final _scrollController = ScrollController();
  final _followUpsKey = GlobalKey();
  bool _didApplyInitialFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFocus == FinanceInitialFocus.followUps) {
      _section = MoneySection.outstanding;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialFocus());
  }

  @override
  void didUpdateWidget(covariant FinanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocus != oldWidget.initialFocus &&
        widget.initialFocus == FinanceInitialFocus.followUps) {
      _didApplyInitialFocus = false;
      _section = MoneySection.outstanding;
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
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                SlateHaptics.action();
                _refreshMoney();
              },
              color: AppColors.accentPrimary,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.lg,
                  AppSpacing.pageX,
                  110,
                ),
                children: [
                  WorkloopPageHeader(
                    icon: LucideIcons.banknote,
                    title: 'Money',
                    subtitle: 'Income, outgoing, and what is still due.',
                    color: AppColors.modFinance,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WorkloopIconButton(
                          icon: LucideIcons.plus,
                          semanticLabel: 'Record income',
                          color: AppColors.t2,
                          backgroundColor: AppColors.t1.withValues(alpha: 0.04),
                          onTap: () => _recordPayment(context),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        WorkloopIconButton(
                          icon: LucideIcons.minus,
                          semanticLabel: 'Add outgoing',
                          color: AppColors.t2,
                          backgroundColor: AppColors.t1.withValues(alpha: 0.04),
                          onTap: () => _showExpenseSheet(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  WorkloopNavigationControl<MoneySection>(
                    selected: _section,
                    segments: const [
                      WorkloopSegment(
                        value: MoneySection.income,
                        label: 'Income',
                      ),
                      WorkloopSegment(
                        value: MoneySection.outgoing,
                        label: 'Outgoing',
                      ),
                      WorkloopSegment(
                        value: MoneySection.outstanding,
                        label: 'Outstanding',
                      ),
                    ],
                    color: AppColors.accentPrimary,
                    onChanged: (section) => setState(() => _section = section),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  invoices.when(
                    loading: () =>
                        const SlateLoadingBlock(height: 360, radius: 18),
                    error: (_, __) =>
                        const SlateErrorState(message: 'Could not load income'),
                    data: (payments) => expenses.when(
                      loading: () =>
                          const SlateLoadingBlock(height: 360, radius: 18),
                      error: (_, __) => const SlateErrorState(
                        message: 'Could not load outgoing',
                      ),
                      data: (expenseRows) => summary.when(
                        loading: () =>
                            const SlateLoadingBlock(height: 360, radius: 18),
                        error: (_, __) => const SlateErrorState(
                          message: 'Could not load Money',
                        ),
                        data: (financeSummary) => AnimatedSwitcher(
                          duration: AppMotion.standard,
                          switchInCurve: AppMotion.curve,
                          switchOutCurve: AppMotion.curve,
                          child: KeyedSubtree(
                            key: ValueKey(_section),
                            child: _buildMoneySection(
                              payments: payments,
                              expenses: expenseRows,
                              summary: financeSummary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneySection({
    required List<Payment> payments,
    required List<Expense> expenses,
    required FinanceSummary summary,
  }) {
    final range = _selectedRange();
    final periodSummary = PeriodMoneySummary.from(
      payments: payments,
      expenses: expenses,
      range: range,
    );
    return switch (_section) {
      MoneySection.income => _incomeSection(
        payments: payments,
        summary: summary,
        range: range,
        periodSummary: periodSummary,
      ),
      MoneySection.outgoing => _outgoingSection(
        expenses: expenses,
        range: range,
        periodSummary: periodSummary,
      ),
      MoneySection.outstanding => _outstandingSection(payments),
    };
  }

  Widget _periodSelector(MoneyPeriodRange range) {
    return MoneyPeriodSwitcher(
      selected: _period,
      customLabel: _period == FinancePeriod.custom ? range.label : null,
      onSelected: (period) async {
        if (period == FinancePeriod.custom) {
          await _showCustomPeriodSheet(context);
          return;
        }
        setState(() => _period = period);
      },
    );
  }

  Widget _incomeSection({
    required List<Payment> payments,
    required FinanceSummary summary,
    required MoneyPeriodRange range,
    required PeriodMoneySummary periodSummary,
  }) {
    final income =
        payments
            .where((payment) => moneyStatusFor(payment) == MoneyStatus.paid)
            .where((payment) => _inRange(payment.issueDate, range))
            .toList()
          ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _periodSelector(range),
        const SizedBox(height: AppSpacing.xl),
        _MoneySectionHero(
          label: 'Income received',
          value: periodSummary.paid,
          detail:
              '${income.length} received entr${income.length == 1 ? 'y' : 'ies'} · ${range.label}',
        ),
        const SizedBox(height: AppSpacing.xxl),
        _WeeklyTargetCard(
          summary: summary,
          onEditTarget: () => _showTargetSheet(context, summary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        WorkloopSectionHeader(
          label: 'Income activity',
          actionLabel: 'Add',
          onAction: () => _recordPayment(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (income.isEmpty)
          const WorkloopEmptyState(
            icon: LucideIcons.arrowDownToLine,
            title: 'No income in this period',
            subtitle: 'Received income will appear here.',
          )
        else
          ...income.map(
            (payment) => PaymentCard(
              payment: payment,
              onTap: () => _showPaymentActionsSheet(context, payment),
              onDelete: () => _confirmDeletePayment(context, payment),
            ),
          ),
      ],
    );
  }

  Widget _outgoingSection({
    required List<Expense> expenses,
    required MoneyPeriodRange range,
    required PeriodMoneySummary periodSummary,
  }) {
    final outgoing =
        expenses
            .where((expense) => _inRange(expense.expenseDate, range))
            .toList()
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _periodSelector(range),
        const SizedBox(height: AppSpacing.xl),
        _MoneySectionHero(
          label: 'Outgoing',
          value: periodSummary.expenses,
          detail:
              '${outgoing.length} expense${outgoing.length == 1 ? '' : 's'} · ${range.label}',
        ),
        if (periodSummary.categoryTotals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          ExpenseCategorySummary(summary: periodSummary),
        ],
        const SizedBox(height: AppSpacing.xxl),
        WorkloopSectionHeader(
          label: 'Outgoing activity',
          actionLabel: 'Add',
          onAction: () => _showExpenseSheet(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (outgoing.isEmpty)
          const WorkloopEmptyState(
            icon: LucideIcons.receipt,
            title: 'No outgoing in this period',
            subtitle: 'Business expenses will appear here.',
          )
        else
          ...outgoing.map(
            (expense) => _ExpenseRow(
              expense: expense,
              onTap: () => _showExpenseSheet(context, expense: expense),
              onDelete: () => _confirmDeleteExpense(context, expense),
            ),
          ),
      ],
    );
  }

  Widget _outstandingSection(List<Payment> payments) {
    final overdue =
        payments
            .where((payment) => moneyStatusFor(payment) == MoneyStatus.overdue)
            .toList()
          ..sort(
            (a, b) =>
                (a.dueDate ?? a.issueDate).compareTo(b.dueDate ?? b.issueDate),
          );
    final upcoming =
        payments
            .where((payment) => moneyStatusFor(payment) == MoneyStatus.unpaid)
            .toList()
          ..sort(
            (a, b) =>
                (a.dueDate ?? a.issueDate).compareTo(b.dueDate ?? b.issueDate),
          );
    final overdueTotal = overdue.fold<double>(
      0,
      (total, payment) => total + payment.total,
    );
    final upcomingTotal = upcoming.fold<double>(
      0,
      (total, payment) => total + payment.total,
    );
    return Column(
      key: _followUpsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OutstandingHero(
          total: overdueTotal + upcomingTotal,
          upcoming: upcomingTotal,
          overdue: overdueTotal,
        ),
        const SizedBox(height: AppSpacing.xxl),
        const WorkloopSectionHeader(label: 'Waiting to be collected'),
        const SizedBox(height: AppSpacing.xs),
        if (overdue.isEmpty && upcoming.isEmpty)
          const _QuietMoneyState()
        else ...[
          if (overdue.isNotEmpty) ...[
            const _MoneyCollectGroupHeader(label: 'Past due'),
            ...overdue.map(
              (payment) => PaymentCard(
                payment: payment,
                onTap: () => _showPaymentActionsSheet(context, payment),
                onDelete: () => _confirmDeletePayment(context, payment),
              ),
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            const _MoneyCollectGroupHeader(label: 'Upcoming'),
            ...upcoming.map(
              (payment) => PaymentCard(
                payment: payment,
                onTap: () => _showPaymentActionsSheet(context, payment),
                onDelete: () => _confirmDeletePayment(context, payment),
              ),
            ),
          ],
        ],
      ],
    );
  }

  bool _inRange(DateTime date, MoneyPeriodRange range) {
    return !date.isBefore(range.start) && date.isBefore(range.end);
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

  Future<void> _showExpenseSheet(
    BuildContext context, {
    Expense? expense,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseEditorScreen(expense: expense)),
    );
    _refreshMoney();
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.status == 'paid'
                          ? 'Income received'
                          : 'To collect',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.t3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '£${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.t1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.t1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _paymentTiming(payment),
                      style: const TextStyle(fontSize: 13, color: AppColors.t3),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.t3,
                        ),
                      ),
                    ],
                    if (payment.appointmentId != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Row(
                        children: [
                          Icon(
                            LucideIcons.calendarCheck,
                            size: 14,
                            color: AppColors.t3,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Linked to booking',
                            style: TextStyle(
                              color: AppColors.t3,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
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
                  label: 'Edit income',
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
                  label: 'Delete income',
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
              'Delete income entry?',
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
              label: 'Delete income',
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
