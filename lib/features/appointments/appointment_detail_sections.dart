part of 'appointment_detail_screen.dart';

class _PickedAppointmentDetailTime {
  final int hour;
  final int minute;

  const _PickedAppointmentDetailTime({
    required this.hour,
    required this.minute,
  });
}

Future<_PickedAppointmentDetailTime?> _showAppointmentDetailTimePicker({
  required BuildContext context,
  required int initialHour,
  required int initialMinute,
}) {
  int tempHour = initialHour;
  int tempMinute = initialMinute;

  return showModalBottomSheet<_PickedAppointmentDetailTime>(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModal) => SizedBox(
        height: 280,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.t1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(
                      context,
                      _PickedAppointmentDetailTime(
                        hour: tempHour,
                        minute: tempMinute,
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 48,
                      perspective: 0.003,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: tempHour,
                      ),
                      onSelectedItemChanged: (i) =>
                          setModal(() => tempHour = i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24,
                        builder: (context, i) {
                          final selected = i == tempHour;
                          return Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: selected ? 24 : 18,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w400,
                                color: selected ? AppColors.t1 : AppColors.t3,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Text(
                    ':',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.t1,
                    ),
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 48,
                      perspective: 0.003,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: tempMinute ~/ 15,
                      ),
                      onSelectedItemChanged: (i) =>
                          setModal(() => tempMinute = i * 15),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 4,
                        builder: (context, i) {
                          final min = i * 15;
                          final selected = min == tempMinute;
                          return Center(
                            child: Text(
                              min.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: selected ? 24 : 18,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w400,
                                color: selected ? AppColors.t1 : AppColors.t3,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _repeatLabel(String rule) {
  if (rule.contains('FREQ=MONTHLY')) return 'Repeats monthly';
  if (rule.contains('INTERVAL=2')) return 'Repeats fortnightly';
  if (rule.contains('FREQ=WEEKLY')) return 'Repeats weekly';
  return 'Repeating booking';
}

class _BookingTasksCard extends StatelessWidget {
  final AsyncValue<List<SlateTask>> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<SlateTask> onToggle;

  const _BookingTasksCard({
    required this.tasks,
    required this.onAddTask,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.listChecks, color: AppColors.t3, size: 16),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Booking tasks',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddTask,
                icon: const Icon(LucideIcons.plus, size: 15),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          tasks.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, __) => const Text(
              'Could not load booking tasks',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text(
                  'Add prep, follow-up, or payment tasks for this booking.',
                  style: TextStyle(color: AppColors.t3, fontSize: 13),
                );
              }
              return Column(
                children: items.map((task) {
                  final done = task.status == 'done';
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onToggle(task),
                    leading: Icon(
                      done ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: done ? AppColors.success : AppColors.t3,
                      size: 19,
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        color: done ? AppColors.t3 : AppColors.t1,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BookingPaymentCard extends StatelessWidget {
  final AsyncValue<List<Payment>> payments;
  final double price;
  final VoidCallback onRecordPayment;
  final ValueChanged<Payment> onMarkPaid;

  const _BookingPaymentCard({
    required this.payments,
    required this.price,
    required this.onRecordPayment,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return payments.when(
      loading: () => const SlateLoadingBlock(height: 96, radius: 16),
      error: (_, __) =>
          const SlateErrorState(message: 'Could not load booking payment'),
      data: (rows) {
        final paid = rows.where((payment) => payment.status == 'paid').toList();
        final unpaid = rows
            .where((payment) => payment.status != 'paid')
            .toList();
        final primary = rows.isEmpty ? null : rows.first;
        final statusLabel = paid.isNotEmpty
            ? 'Paid'
            : unpaid.isNotEmpty
            ? 'Unpaid'
            : 'No payment linked';
        final amount = primary?.total ?? price;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.t1.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.banknote,
                      size: 17,
                      color: AppColors.t2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.t3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$statusLabel · £${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: paid.isNotEmpty
                                ? AppColors.success
                                : unpaid.isNotEmpty
                                ? AppColors.warning
                                : AppColors.t1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (unpaid.isNotEmpty) ...[
                const SizedBox(height: 14),
                SlateButton(
                  label: 'Mark Payment Received',
                  icon: LucideIcons.checkCircle,
                  onPressed: () => onMarkPaid(unpaid.first),
                ),
              ] else if (rows.isEmpty) ...[
                const SizedBox(height: 14),
                SlateButton(
                  label: 'Record Payment',
                  icon: LucideIcons.plus,
                  secondary: true,
                  onPressed: onRecordPayment,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BookingLocationOption {
  final String value;
  final String label;

  const _BookingLocationOption({required this.value, required this.label});
}
