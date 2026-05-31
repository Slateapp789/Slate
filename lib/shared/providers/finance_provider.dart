import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';
import 'workspace_settings_provider.dart';

final invoicesProvider = FutureProvider<List<Payment>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(paymentsRepositoryProvider).list(workspaceId);
});

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];

  return ref.watch(expensesRepositoryProvider).list(workspaceId);
});

final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) async {
  final payments = await ref.watch(invoicesProvider.future);
  final expenses = await ref.watch(expensesProvider.future);
  final settings = await ref.watch(workspaceSettingsProvider.future);
  final monthlyTarget = (settings?['revenue_target'] as num?)?.toDouble() ?? 0;
  return FinanceSummary.from(
    payments: payments,
    expenses: expenses,
    monthlyTarget: monthlyTarget,
  );
});

class FinanceSummary {
  final double weeklyTarget;
  final double thisWeekPaid;
  final double lastWeekPaid;
  final double thisMonthPaid;
  final double lastMonthPaid;
  final double unpaid;
  final double overdue;
  final double thisWeekExpenses;
  final double thisMonthExpenses;
  final double thisWeekNet;
  final double thisMonthNet;

  const FinanceSummary({
    required this.weeklyTarget,
    required this.thisWeekPaid,
    required this.lastWeekPaid,
    required this.thisMonthPaid,
    required this.lastMonthPaid,
    required this.unpaid,
    required this.overdue,
    required this.thisWeekExpenses,
    required this.thisMonthExpenses,
    required this.thisWeekNet,
    required this.thisMonthNet,
  });

  double get weeklyProgress {
    if (weeklyTarget <= 0) return 0;
    return (thisWeekPaid / weeklyTarget).clamp(0, 1);
  }

  double get weekDelta => thisWeekPaid - lastWeekPaid;

  double get weekDeltaPercent {
    if (lastWeekPaid <= 0) return thisWeekPaid > 0 ? 1 : 0;
    return weekDelta / lastWeekPaid;
  }

  double get monthDelta => thisMonthPaid - lastMonthPaid;

  factory FinanceSummary.from({
    required List<Payment> payments,
    required List<Expense> expenses,
    required double monthlyTarget,
  }) {
    final now = DateTime.now();
    final thisWeekStart = _startOfWeek(now);
    final nextWeekStart = thisWeekStart.add(const Duration(days: 7));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final paidPayments = payments.where((item) => item.status == 'paid');
    final thisWeekPaid = _sumPaymentsInRange(
      paidPayments,
      thisWeekStart,
      nextWeekStart,
    );
    final lastWeekPaid = _sumPaymentsInRange(
      paidPayments,
      lastWeekStart,
      thisWeekStart,
    );
    final thisMonthPaid = _sumPaymentsInRange(
      paidPayments,
      thisMonthStart,
      nextMonthStart,
    );
    final lastMonthPaid = _sumPaymentsInRange(
      paidPayments,
      lastMonthStart,
      thisMonthStart,
    );
    final unpaid = payments
        .where((item) => item.status != 'paid')
        .fold<double>(0, (sum, item) => sum + item.total);
    final overdue = payments
        .where((item) => item.status == 'overdue')
        .fold<double>(0, (sum, item) => sum + item.total);
    final thisWeekExpenses = _sumExpensesInRange(
      expenses,
      thisWeekStart,
      nextWeekStart,
    );
    final thisMonthExpenses = _sumExpensesInRange(
      expenses,
      thisMonthStart,
      nextMonthStart,
    );

    return FinanceSummary(
      weeklyTarget: monthlyTarget > 0 ? monthlyTarget / 4.345 : 0,
      thisWeekPaid: thisWeekPaid,
      lastWeekPaid: lastWeekPaid,
      thisMonthPaid: thisMonthPaid,
      lastMonthPaid: lastMonthPaid,
      unpaid: unpaid,
      overdue: overdue,
      thisWeekExpenses: thisWeekExpenses,
      thisMonthExpenses: thisMonthExpenses,
      thisWeekNet: thisWeekPaid - thisWeekExpenses,
      thisMonthNet: thisMonthPaid - thisMonthExpenses,
    );
  }
}

DateTime _startOfWeek(DateTime now) {
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

double _sumPaymentsInRange(
  Iterable<Payment> payments,
  DateTime start,
  DateTime end,
) {
  return payments
      .where(
        (item) =>
            !item.issueDate.isBefore(start) && item.issueDate.isBefore(end),
      )
      .fold<double>(0, (sum, item) => sum + item.total);
}

double _sumExpensesInRange(
  Iterable<Expense> expenses,
  DateTime start,
  DateTime end,
) {
  return expenses
      .where(
        (item) =>
            !item.expenseDate.isBefore(start) && item.expenseDate.isBefore(end),
      )
      .fold<double>(0, (sum, item) => sum + item.amount);
}
