import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../appointments/appointment_detail_screen.dart';
import '../../appointments/add_appointment_screen.dart';
import '../providers/client_detail_providers.dart';

class ClientAppointmentsTab extends ConsumerWidget {
  final String clientId;
  const ClientAppointmentsTab({super.key, required this.clientId});

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

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(clientAppointmentsProvider(clientId));

    return appointments.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (appts) => appts.isEmpty
          ? _EmptyStateWithAction(
              icon: LucideIcons.calendar,
              message: 'No bookings yet',
              actionLabel: '+ Add Booking',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddAppointmentScreen()),
                );
                ref.invalidate(clientAppointmentsProvider(clientId));
              },
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(clientAppointmentsProvider(clientId)),
              color: AppColors.green,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: appts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final appt = appts[i];
                  final dt = DateTime.tryParse(
                    appt['start_time'] as String? ?? '',
                  )?.toLocal();
                  final endDt = DateTime.tryParse(
                    appt['end_time'] as String? ?? '',
                  )?.toLocal();
                  final status = appt['status'] as String? ?? 'scheduled';
                  final isScheduled = status == 'scheduled';
                  final statusColor = status == 'completed'
                      ? AppColors.success
                      : status == 'cancelled'
                      ? AppColors.error
                      : status == 'no_show'
                      ? AppColors.warning
                      : AppColors.green;

                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AppointmentDetailScreen(appointment: appt),
                        ),
                      );
                      ref.invalidate(clientAppointmentsProvider(clientId));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isScheduled
                              ? AppColors.green.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt['services']?['name'] as String? ??
                                      'Booking',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.t1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dt != null
                                      ? endDt != null
                                            ? '${_formatDate(dt)} · ${_fmtTime(dt)} – ${_fmtTime(endDt)}'
                                            : '${_formatDate(dt)} · ${_fmtTime(dt)}'
                                      : '—',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.t3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (appt['price'] != null)
                                Text(
                                  '£${(appt['price'] as num).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.t1,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.t3,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── Empty state with action button ────────────────────────────────────────────
class _EmptyStateWithAction extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyStateWithAction({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.t3, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppColors.t3),
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
              child: Text(
                actionLabel,
                style: const TextStyle(
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
