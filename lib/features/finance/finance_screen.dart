import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/providers/workspace_settings_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/currency_format.dart';
import '../../shared/widgets/slate_ui.dart';
import 'add_payment_screen.dart';
import 'expense_editor_screen.dart';
import 'widgets/money_summary_widgets.dart';
import 'widgets/payment_cards.dart';

part 'finance_screen_widgets.dart';

enum FinanceInitialFocus { top, followUps }

enum MoneySection { made, spent, owed }

class FinanceScreen extends ConsumerStatefulWidget {
  final FinanceInitialFocus initialFocus;

  const FinanceScreen({super.key, this.initialFocus = FinanceInitialFocus.top});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  MoneySection _section = MoneySection.made;
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
      _section = MoneySection.owed;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialFocus());
  }

  @override
  void didUpdateWidget(covariant FinanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocus != oldWidget.initialFocus &&
        widget.initialFocus == FinanceInitialFocus.followUps) {
      _didApplyInitialFocus = false;
      _section = MoneySection.owed;
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
      duration: AppMotion.responsive(context, AppMotion.standard),
      curve: AppMotion.curve,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider);
    final expenses = ref.watch(expensesProvider);
    final settings = ref.watch(workspaceSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            bottom: false,
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
                  AppSpacing.screenTop,
                  AppSpacing.pageX,
                  AppSpacing.bottomNavClearance,
                ),
                children: [
                  WorkloopPageHeader(
                    title: 'Money',
                    subtitle:
                        'Know what came in, went out, and needs following up.',
                    color: AppColors.modFinance,
                    trailing: WorkloopTopAction(
                      label: 'Record',
                      semanticLabel: 'Add money',
                      onTap: () => _showMoneyCreateSheet(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  WorkloopNavigationControl<MoneySection>(
                    selected: _section,
                    segments: const [
                      WorkloopSegment(value: MoneySection.made, label: 'Made'),
                      WorkloopSegment(
                        value: MoneySection.spent,
                        label: 'Spent',
                      ),
                      WorkloopSegment(value: MoneySection.owed, label: 'Owed'),
                    ],
                    color: AppColors.accentPrimary,
                    onChanged: (section) => setState(() => _section = section),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedSwitcher(
                    duration: AppMotion.responsive(context, AppMotion.standard),
                    switchInCurve: AppMotion.curve,
                    switchOutCurve: AppMotion.curve,
                    child: KeyedSubtree(
                      key: ValueKey(_section),
                      child: _buildMoneySection(
                        invoices: invoices,
                        expenses: expenses,
                        settings: settings,
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
    required AsyncValue<List<Payment>> invoices,
    required AsyncValue<List<Expense>> expenses,
    required AsyncValue<Map<String, dynamic>?> settings,
  }) {
    final range = _selectedRange();
    return switch (_section) {
      MoneySection.made => invoices.when(
        loading: () => const SlateLoadingBlock(height: 360, radius: 18),
        error: (_, _) => SlateErrorState(
          message: 'Could not load income',
          onRetry: () => ref.invalidate(invoicesProvider),
        ),
        data: (payments) => _incomeSection(
          payments: payments,
          settings: settings,
          range: range,
          periodSummary: PeriodMoneySummary.from(
            payments: payments,
            expenses: const [],
            range: range,
          ),
        ),
      ),
      MoneySection.spent => expenses.when(
        loading: () => const SlateLoadingBlock(height: 360, radius: 18),
        error: (_, _) => SlateErrorState(
          message: 'Could not load expenses',
          onRetry: () => ref.invalidate(expensesProvider),
        ),
        data: (expenseRows) => _outgoingSection(
          expenses: expenseRows,
          range: range,
          periodSummary: PeriodMoneySummary.from(
            payments: const [],
            expenses: expenseRows,
            range: range,
          ),
        ),
      ),
      MoneySection.owed => invoices.when(
        loading: () => const SlateLoadingBlock(height: 360, radius: 18),
        error: (_, _) => SlateErrorState(
          message: 'Could not load payments owed',
          onRetry: () => ref.invalidate(invoicesProvider),
        ),
        data: _owedSection,
      ),
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
    required AsyncValue<Map<String, dynamic>?> settings,
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
          label: 'Made ${range.label.toLowerCase()}',
          value: periodSummary.paid,
          detail:
              '${income.length} payment${income.length == 1 ? '' : 's'} received',
        ),
        if (_period != FinancePeriod.custom) ...[
          const SizedBox(height: AppSpacing.xxl),
          settings.when(
            loading: () =>
                const SlateLoadingBlock(height: 112, radius: AppRadius.md),
            error: (_, _) => SlateErrorState(
              message: 'Could not load your Money target',
              onRetry: () => ref.invalidate(workspaceSettingsProvider),
            ),
            data: (values) {
              final monthlyTarget =
                  (values?['revenue_target'] as num?)?.toDouble() ?? 0;
              return _IncomeTargetProgress(
                label: _period == FinancePeriod.month
                    ? 'Monthly target'
                    : 'Weekly target',
                made: periodSummary.paid,
                target: _period == FinancePeriod.month
                    ? monthlyTarget
                    : monthlyTarget / 4.345,
                onEditTarget: () => _showTargetSheet(context, monthlyTarget),
              );
            },
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        WorkloopSectionHeader(
          label: 'Payments received',
          actionLabel: 'Add',
          onAction: () => _recordPayment(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (income.isEmpty)
          const WorkloopEmptyState(
            icon: LucideIcons.arrowDownToLine,
            title: 'Nothing made in this period',
            subtitle: 'Payments you receive will appear here.',
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
          label: 'Spent ${range.label.toLowerCase()}',
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
          label: 'Expenses',
          actionLabel: 'Add',
          onAction: () => _showExpenseSheet(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (outgoing.isEmpty)
          const WorkloopEmptyState(
            icon: LucideIcons.receipt,
            title: 'Nothing spent in this period',
            subtitle: 'Business expenses you record will appear here.',
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

  Widget _owedSection(List<Payment> payments) {
    final owed =
        payments.where((payment) => outstandingAmountFor(payment) > 0).toList()
          ..sort((a, b) {
            final aOverdue = moneyStatusFor(a) == MoneyStatus.overdue;
            final bOverdue = moneyStatusFor(b) == MoneyStatus.overdue;
            if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
            return (a.dueDate ?? a.issueDate).compareTo(
              b.dueDate ?? b.issueDate,
            );
          });
    final owedTotal = owed.fold<double>(
      0,
      (total, payment) => total + outstandingAmountFor(payment),
    );
    return Column(
      key: _followUpsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MoneySectionHero(
          label: 'You are owed',
          value: owedTotal,
          detail:
              '${owed.length} payment${owed.length == 1 ? '' : 's'} waiting to be paid',
        ),
        const SizedBox(height: AppSpacing.xxl),
        const WorkloopSectionHeader(label: 'Payments owed'),
        const SizedBox(height: AppSpacing.xs),
        if (owed.isEmpty)
          const _QuietMoneyState()
        else
          ...owed.map(
            (payment) => PaymentCard(
              payment: payment,
              onTap: () => _showPaymentActionsSheet(context, payment),
              onDelete: () => _confirmDeletePayment(context, payment),
            ),
          ),
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

  Future<void> _showMoneyCreateSheet(BuildContext context) async {
    final action = await showModalBottomSheet<_MoneyCreateAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: SlateTheme.of(context).scrim,
      builder: (sheetContext) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to Money',
              style: TextStyle(
                color: AppColors.t1,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            const Text(
              'Choose what you want to record.',
              style: TextStyle(color: AppColors.t3, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            _MoneyCreateChoice(
              icon: LucideIcons.banknote,
              label: 'Record income',
              description: 'Money received or waiting to be paid.',
              onTap: () =>
                  Navigator.pop(sheetContext, _MoneyCreateAction.income),
            ),
            _MoneyCreateChoice(
              icon: LucideIcons.receipt,
              label: 'Add expense',
              description: 'Money spent by the business.',
              showDivider: false,
              onTap: () =>
                  Navigator.pop(sheetContext, _MoneyCreateAction.expense),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _MoneyCreateAction.income:
        await _recordPayment(context);
      case _MoneyCreateAction.expense:
        await _showExpenseSheet(context);
    }
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
            final picked = await showWorkloopDatePicker(
              context: context,
              initialDate: start,
              firstDate: DateTime.now().subtract(const Duration(days: 730)),
              lastDate: end,
            );
            if (picked != null) setSheetState(() => start = picked);
          }

          Future<void> pickEnd() async {
            final picked = await showWorkloopDatePicker(
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
                    fontWeight: FontWeight.w600,
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

  void _showTargetSheet(BuildContext context, double monthlyTarget) {
    final monthlyController = TextEditingController(
      text: monthlyTarget > 0 ? currencyInputValue(monthlyTarget) : '',
    );
    final weeklyTarget = monthlyTarget / 4.345;
    final weeklyController = TextEditingController(
      text: weeklyTarget > 0 ? currencyInputValue(weeklyTarget) : '',
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
                    content: Text('The target could not be updated.'),
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
                      fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w600,
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

  Future<bool> _confirmDeleteExpense(
    BuildContext context,
    Expense expense,
  ) async {
    var deleting = false;
    String? errorMessage;
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => PopScope(
          canPop: !deleting,
          child: SlateSheetFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete expense?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${expense.category} · ${formatPounds(expense.amount)}',
                  style: const TextStyle(fontSize: 14, color: AppColors.t3),
                  textAlign: TextAlign.center,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SlateButton(
                  label: deleting ? 'Deleting...' : 'Delete Expense',
                  destructive: true,
                  onPressed: deleting
                      ? null
                      : () async {
                          setSheetState(() {
                            deleting = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(expensesRepositoryProvider)
                                .delete(expense.id);
                            _refreshMoney();
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setSheetState(() {
                              deleting = false;
                              errorMessage =
                                  'Could not confirm this deletion. The expense remains visible; check your connection and try again.';
                            });
                          }
                        },
                ),
                const SizedBox(height: 10),
                SlateButton(
                  label: 'Cancel',
                  secondary: true,
                  onPressed: deleting ? null : () => Navigator.pop(ctx, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return deleted ?? false;
  }

  void _showPaymentActionsSheet(BuildContext context, Payment payment) {
    final clientName = payment.clientName ?? 'Unknown client';
    final amount = payment.total;
    final description = payment.notes ?? '';
    final canMarkPaid =
        payment.status == 'sent' ||
        payment.status == 'pending' ||
        payment.status == 'overdue';
    var updating = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => PopScope(
          canPop: !updating,
          child: SlateSheetFrame(
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
                            fontWeight: FontWeight.w600,
                            color: AppColors.t3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          formatPounds(amount),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.t1,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.t1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _paymentTiming(payment),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.t3,
                          ),
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (errorMessage != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (canMarkPaid) ...[
                      SlateButton(
                        label: updating ? 'Updating...' : 'Mark as Received',
                        icon: LucideIcons.checkCircle,
                        onPressed: updating
                            ? null
                            : () async {
                                setSheetState(() {
                                  updating = true;
                                  errorMessage = null;
                                });
                                try {
                                  await _markPaymentPaid(context, payment);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  if (!ctx.mounted) return;
                                  setSheetState(() {
                                    updating = false;
                                    errorMessage =
                                        'Could not mark this payment as received. Nothing visible has changed; check your connection and try again.';
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 10),
                    ],
                    SlateButton(
                      label: 'Edit income',
                      icon: LucideIcons.pencil,
                      secondary: true,
                      onPressed: updating
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                if (!context.mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddPaymentScreen(payment: payment),
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
                      onPressed: updating
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _confirmDeletePayment(context, payment);
                            },
                    ),
                    const SizedBox(height: 10),
                    SlateButton(
                      label: 'Close',
                      secondary: true,
                      onPressed: updating ? null : () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markPaymentPaid(BuildContext context, Payment payment) async {
    final amount = payment.total;
    await ref.read(paymentsRepositoryProvider).markPaid(payment);
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .create(
            workspaceId: payment.workspaceId,
            type: 'payment_received',
            title: 'Payment received',
            body:
                '${formatPounds(amount)} from ${payment.clientName ?? 'a client'} is now paid.',
            deepLink: '/payments',
          );
    } catch (_) {
      // The confirmed payment update remains successful even if the optional
      // notification feed is temporarily unavailable.
    }
    _refreshPayment(payment);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatPounds(amount)} marked as received',
            style: const TextStyle(color: AppColors.onBrandAccent),
          ),
          backgroundColor: AppColors.brandAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
    }
  }

  Future<bool> _confirmDeletePayment(
    BuildContext context,
    Payment payment,
  ) async {
    final clientName = payment.clientName ?? 'Unknown';
    final amount = payment.total;
    var deleting = false;
    String? errorMessage;

    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => PopScope(
          canPop: !deleting,
          child: SlateSheetFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete income entry?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$clientName · ${formatPounds(amount)}',
                  style: const TextStyle(fontSize: 14, color: AppColors.t3),
                  textAlign: TextAlign.center,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SlateButton(
                  label: deleting ? 'Deleting...' : 'Delete income',
                  destructive: true,
                  onPressed: deleting
                      ? null
                      : () async {
                          setSheetState(() {
                            deleting = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(paymentsRepositoryProvider)
                                .delete(payment.id);
                            _refreshPayment(payment);
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setSheetState(() {
                              deleting = false;
                              errorMessage =
                                  'Could not confirm this deletion. The income entry remains visible; check your connection and try again.';
                            });
                          }
                        },
                ),
                const SizedBox(height: 10),
                SlateButton(
                  label: 'Cancel',
                  secondary: true,
                  onPressed: deleting ? null : () => Navigator.pop(ctx, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return deleted ?? false;
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

enum _MoneyCreateAction { income, expense }

class _MoneyCreateChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool showDivider;

  const _MoneyCreateChoice({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopListRow(
      leading: Container(
        width: AppSpacing.minTouch,
        height: AppSpacing.minTouch,
        decoration: BoxDecoration(
          color: tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: tokens.accentInk, size: 19),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: tokens.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: tokens.textSecondary,
          fontSize: 13,
          height: 1.35,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: tokens.textTertiary,
        size: 18,
      ),
      showDivider: showDivider,
      onTap: onTap,
    );
  }
}
