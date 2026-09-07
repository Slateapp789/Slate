import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import 'widgets/money_editor_widgets.dart';

typedef _ExpenseDraft = ({
  String amount,
  String category,
  String date,
  String notes,
});

class ExpenseEditorScreen extends ConsumerStatefulWidget {
  final Expense? expense;

  const ExpenseEditorScreen({super.key, this.expense});

  @override
  ConsumerState<ExpenseEditorScreen> createState() =>
      _ExpenseEditorScreenState();
}

class _ExpenseEditorScreenState extends ConsumerState<ExpenseEditorScreen> {
  static const _categories = ['Materials', 'Travel', 'Tools', 'Rent', 'Other'];

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late String _category;
  late DateTime _date;
  late _ExpenseDraft _savedDraft;
  bool _saving = false;
  bool _allowPop = false;

  bool get _editing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController.text = expense == null
        ? ''
        : expense.amount.toStringAsFixed(
            expense.amount.truncateToDouble() == expense.amount ? 0 : 2,
          );
    _notesController.text = expense?.notes ?? '';
    _category = expense?.category ?? _categories.first;
    _date = expense?.expenseDate ?? DateTime.now();
    _amountController.addListener(_handleDraftChanged);
    _notesController.addListener(_handleDraftChanged);
    _savedDraft = _currentDraft;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleDraftChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSave =>
      (double.tryParse(_amountController.text.trim()) ?? 0) > 0;

  _ExpenseDraft get _currentDraft => (
    amount: _amountController.text.trim(),
    category: _category,
    date:
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
    notes: _notesController.text.trim(),
  );

  bool get _hasChanges => _currentDraft != _savedDraft;

  Future<void> _handleBack() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_hasChanges) {
      await _leaveScreen();
      return;
    }
    final decision = await showWorkloopDraftConfirmation(
      context,
      title: _editing ? 'Save expense changes?' : 'Save this expense?',
      message: _editing
          ? 'You changed this expense. Save before leaving?'
          : 'Your expense details have not been saved yet.',
      saveLabel: _editing ? 'Save changes' : 'Add expense',
      canSave: _canSave && !_saving,
    );
    if (!mounted) return;
    switch (decision) {
      case WorkloopDraftDecision.save:
        await _save();
        return;
      case WorkloopDraftDecision.discard:
        await _leaveScreen();
        return;
      case WorkloopDraftDecision.stay:
        return;
    }
  }

  Future<void> _leaveScreen() async {
    if (!_allowPop && mounted) setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _save() async {
    if (!_canSave || _saving) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) {
        if (mounted) setState(() => _saving = false);
        return false;
      }
      final amount = double.parse(_amountController.text.trim());
      if (_editing) {
        await ref
            .read(expensesRepositoryProvider)
            .update(
              expenseId: widget.expense!.id,
              amount: amount,
              category: _category,
              date: _date,
              notes: _notesController.text,
            );
      } else {
        await ref
            .read(expensesRepositoryProvider)
            .create(
              workspaceId: workspaceId,
              amount: amount,
              category: _category,
              date: _date,
              notes: _notesController.text,
            );
      }
      ref.invalidate(expensesProvider);
      ref.invalidate(financeSummaryProvider);
      ref.invalidate(dashboardRevenueProvider);
      if (mounted) await _leaveScreen();
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not save this expense. Please try again.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showWorkloopDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: WorkloopTexturedBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageX,
                      AppSpacing.screenTop,
                      AppSpacing.pageX,
                      0,
                    ),
                    child: WorkloopRouteHeader(
                      title: _editing ? 'Edit expense' : 'Add expense',
                      backSemanticLabel: 'Back to Money',
                      onBack: _handleBack,
                      trailing: MoneySaveAction(
                        label: _editing ? 'Save' : 'Add',
                        loading: _saving,
                        enabled: _canSave,
                        onTap: _save,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageX,
                        0,
                        AppSpacing.pageX,
                        AppSpacing.xxl,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MoneyFormSection(
                            title: 'Amount',
                            subtitle: 'What the business spent.',
                            child: MoneyAmountField(
                              controller: _amountController,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          MoneyFormSection(
                            title: 'Details',
                            subtitle:
                                'Keep the expense easy to recognise later.',
                            child: Column(
                              children: [
                                WorkloopPickerField<String>(
                                  value: _category,
                                  title: 'Expense category',
                                  hint: 'Choose category',
                                  leadingIcon: LucideIcons.tag,
                                  options: _categories
                                      .map(
                                        (category) => WorkloopPickerOption(
                                          value: category,
                                          label: category,
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _category = value),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                MoneyDateField(
                                  label: 'Expense date',
                                  value: _formatDate(_date),
                                  onTap: _pickDate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          MoneyFormSection(
                            title: 'Note',
                            subtitle: 'Optional context for this expense.',
                            child: MoneyTextField(
                              controller: _notesController,
                              label: 'Note',
                              hint: 'Supplier, item or useful reference',
                              icon: LucideIcons.fileText,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
