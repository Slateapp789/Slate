import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../providers/client_detail_providers.dart';

class ClientOverviewTab extends ConsumerWidget {
  final String clientId;
  final String clientName;
  final String notes;

  const ClientOverviewTab({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.notes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(clientAppointmentsProvider(clientId));
    final payments = ref.watch(clientPaymentsProvider(clientId));
    final tasks = ref.watch(clientTasksProvider(clientId));

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async {
        ref.invalidate(clientAppointmentsProvider(clientId));
        ref.invalidate(clientPaymentsProvider(clientId));
        ref.invalidate(clientTasksProvider(clientId));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          _PulseSection(
            appointments: appointments.value ?? const [],
            payments: payments.value ?? const [],
            tasks: tasks.value ?? const [],
          ),
          const SizedBox(height: 12),
          _NotesSection(notes: notes, clientName: clientName),
          const SizedBox(height: 12),
          _TimelineSection(
            appointments: appointments.value ?? const [],
            payments: payments.value ?? const [],
            tasks: tasks.value ?? const [],
            loading:
                appointments.isLoading || payments.isLoading || tasks.isLoading,
          ),
        ],
      ),
    );
  }
}

class _PulseSection extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final List<Payment> payments;
  final List<SlateTask> tasks;

  const _PulseSection({
    required this.appointments,
    required this.payments,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextAppointment = appointments
        .map(_appointmentDate)
        .whereType<DateTime>()
        .where((date) => date.isAfter(now))
        .fold<DateTime?>(null, (next, date) {
          if (next == null || date.isBefore(next)) return date;
          return next;
        });
    final openTasks = tasks.where((task) => task.status != 'done').length;
    final outstanding = payments
        .where((payment) => payment.status != 'paid')
        .fold<double>(0, (sum, payment) => sum + payment.total);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLIENT PULSE',
            style: TextStyle(
              color: AppColors.t3,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: LucideIcons.calendarClock,
                  label: 'Next',
                  value: nextAppointment == null
                      ? 'None'
                      : _formatShortDate(nextAppointment),
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: LucideIcons.banknote,
                  label: 'Owes',
                  value: '£${outstanding.toStringAsFixed(0)}',
                  color: outstanding > 0 ? AppColors.warning : AppColors.t3,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: LucideIcons.checkSquare,
                  label: 'Tasks',
                  value: '$openTasks open',
                  color: openTasks > 0 ? AppColors.warning : AppColors.t3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final String notes;
  final String clientName;

  const _NotesSection({required this.notes, required this.clientName});

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.bgInteract,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.fileText,
              color: AppColors.t2,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client Notes',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasNotes
                      ? notes
                      : 'No notes yet. Add preferences, follow-up context, or anything worth remembering about $clientName.',
                  style: TextStyle(
                    color: hasNotes ? AppColors.t2 : AppColors.t3,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final List<Payment> payments;
  final List<SlateTask> tasks;
  final bool loading;

  const _TimelineSection({
    required this.appointments,
    required this.payments,
    required this.tasks,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ...appointments.map(_TimelineItem.fromAppointment),
      ...payments.map(_TimelineItem.fromPayment),
      ...tasks.map(_TimelineItem.fromTask),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final visibleItems = items.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT HISTORY',
            style: TextStyle(
              color: AppColors.t3,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (visibleItems.isEmpty)
            const _EmptyTimeline()
          else
            ...visibleItems.map((item) => _TimelineRow(item: item)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _TimelineItem item;

  const _TimelineRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.t3,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Appointments, payments, and tasks will appear here as the relationship builds.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.t3, fontSize: 13, height: 1.35),
      ),
    );
  }
}

class _TimelineItem {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _TimelineItem({
    required this.date,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  factory _TimelineItem.fromAppointment(Map<String, dynamic> row) {
    final date =
        _appointmentDate(row) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final status = row['status'] as String? ?? 'scheduled';
    final service = row['services']?['name'] as String? ?? 'Appointment';
    final price = row['price'] is num
        ? ' · £${(row['price'] as num).toStringAsFixed(0)}'
        : '';
    return _TimelineItem(
      date: date,
      icon: LucideIcons.calendar,
      color: status == 'cancelled'
          ? AppColors.error
          : status == 'completed'
          ? AppColors.success
          : AppColors.green,
      title: service,
      subtitle:
          '${_formatLongDate(date)} · ${status.replaceAll('_', ' ')}$price',
    );
  }

  factory _TimelineItem.fromPayment(Payment payment) {
    final color = switch (payment.status) {
      'paid' => AppColors.success,
      'overdue' => AppColors.error,
      _ => AppColors.warning,
    };
    return _TimelineItem(
      date: payment.issueDate,
      icon: LucideIcons.banknote,
      color: color,
      title: 'Payment ${payment.status}',
      subtitle:
          '£${payment.total.toStringAsFixed(0)} · ${_formatLongDate(payment.issueDate)}',
    );
  }

  factory _TimelineItem.fromTask(SlateTask task) {
    final date = task.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final color = task.status == 'done' ? AppColors.success : AppColors.warning;
    return _TimelineItem(
      date: date,
      icon: LucideIcons.checkSquare,
      color: color,
      title: task.title,
      subtitle:
          '${task.status == 'done' ? 'Completed' : 'Open'} task · ${task.dueDate == null ? 'No due date' : _formatLongDate(task.dueDate!)}',
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.bgCard,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.border),
);

DateTime? _appointmentDate(Map<String, dynamic> row) =>
    DateTime.tryParse(row['start_time'] as String? ?? '')?.toLocal();

String _formatShortDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final value = DateTime(date.year, date.month, date.day);
  if (value == today) return 'Today';
  if (value == today.add(const Duration(days: 1))) return 'Tomorrow';
  return '${date.day}/${date.month}';
}

String _formatLongDate(DateTime date) {
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
