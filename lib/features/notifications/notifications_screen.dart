import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        color: AppColors.t2,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: AppColors.t1,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
                error: (_, __) => const _EmptyNotifications(
                  title: 'Could not load notifications',
                  subtitle: 'Try again in a moment.',
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyNotifications(
                      title: 'No notifications',
                      subtitle: 'Important updates will appear here.',
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.green,
                    onRefresh: () async =>
                        ref.invalidate(notificationsProvider),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      children: _groupedNotificationChildren(items),
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
}

class NotificationSettingsView extends ConsumerWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    return prefs.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (_, __) => const Text(
        'Could not load notification settings',
        style: TextStyle(color: AppColors.error),
      ),
      data: (values) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          _PreferenceGroup(
            title: 'Important alerts',
            values: values,
            items: const [
              _PreferenceItem(
                'all_notifications',
                'All notifications',
                'Push alerts can be turned off at once.',
              ),
              _PreferenceItem(
                'payment_received',
                'Payment received',
                'A payment has been recorded.',
              ),
              _PreferenceItem(
                'new_booking',
                'New booking',
                'A client books from your page.',
              ),
              _PreferenceItem(
                'booking_request',
                'Booking request',
                'A request needs approval.',
              ),
              _PreferenceItem(
                'invoice_overdue',
                'Overdue payment',
                'Money needs attention.',
              ),
            ],
          ),
          const SizedBox(height: 22),
          _PreferenceGroup(
            title: 'Workday',
            values: values,
            items: const [
              _PreferenceItem(
                'no_show',
                'No-show check',
                'Appointment has not been completed.',
              ),
              _PreferenceItem(
                'lead_followup',
                'Lead follow-up',
                'A lead has gone quiet.',
              ),
              _PreferenceItem(
                'appointment_reminder_15',
                '15 min appointment reminder',
                'Optional owner reminder.',
              ),
              _PreferenceItem(
                'task_due_morning',
                'Tasks due today',
                'Morning task reminder.',
              ),
            ],
          ),
          const SizedBox(height: 22),
          _PreferenceGroup(
            title: 'Summaries',
            values: values,
            items: const [
              _PreferenceItem(
                'morning_digest',
                'Morning digest',
                'Appointments, tasks and outstanding money.',
              ),
              _PreferenceItem(
                'weekly_summary',
                'Weekly business summary',
                'A calm Monday overview.',
              ),
              _PreferenceItem(
                'quiet_hours_enabled',
                'Quiet hours',
                'Suppress non-urgent alerts overnight.',
              ),
              _PreferenceItem(
                'quiet_sundays',
                'Quiet Sundays',
                'Protect a day off.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferenceGroup extends ConsumerWidget {
  final String title;
  final Map<String, dynamic> values;
  final List<_PreferenceItem> items;

  const _PreferenceGroup({
    required this.title,
    required this.values,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.t3,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _PreferenceRow(
                  item: items[i],
                  value: values[items[i].key] as bool? ?? false,
                  onChanged: (next) async {
                    final workspaceId = await ref.read(
                      workspaceIdProvider.future,
                    );
                    if (workspaceId == null) return;
                    await ref
                        .read(notificationsRepositoryProvider)
                        .upsertPreferences(workspaceId, {items[i].key: next});
                    ref.invalidate(notificationPreferencesProvider);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsProvider);
                  },
                ),
                if (i < items.length - 1)
                  Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceItem {
  final String key;
  final String title;
  final String subtitle;
  const _PreferenceItem(this.key, this.title, this.subtitle);
}

class _PreferenceRow extends StatelessWidget {
  final _PreferenceItem item;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceRow({
    required this.item,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: AppColors.t3, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

List<Widget> _groupedNotificationChildren(List<SlateNotification> items) {
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayItems = items.where((item) {
    final created = item.createdAt?.toLocal();
    return created != null && !created.isBefore(todayStart);
  }).toList();
  final earlierItems = items
      .where((item) => !todayItems.contains(item))
      .toList();

  return [
    if (todayItems.isNotEmpty) ...[
      const _NotificationGroupLabel('Today'),
      ...todayItems.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _NotificationTile(item: item),
        ),
      ),
    ],
    if (earlierItems.isNotEmpty) ...[
      const SizedBox(height: 10),
      const _NotificationGroupLabel('Earlier'),
      ...earlierItems.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _NotificationTile(item: item),
        ),
      ),
    ],
  ];
}

class _NotificationGroupLabel extends StatelessWidget {
  final String label;
  const _NotificationGroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final SlateNotification item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        if (!item.read) {
          await ref.read(notificationsRepositoryProvider).markRead(item.id);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationsProvider);
        }
        if (context.mounted && item.deepLink?.isNotEmpty == true) {
          _openDeepLink(context, item.deepLink!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.read ? AppColors.bgCard : AppColors.greenDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.read ? AppColors.border : AppColors.green,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconForType(item.type),
              color: item.read ? AppColors.t3 : AppColors.green,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!item.read) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: AppColors.t1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: const TextStyle(color: AppColors.t2, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (item.deepLink?.isNotEmpty == true) ...[
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'payment' ||
      'payment_received' ||
      'invoice_overdue' => LucideIcons.banknote,
      'booking' ||
      'new_booking' ||
      'booking_request' => LucideIcons.calendarPlus,
      'task' || 'task_due' => LucideIcons.checkSquare,
      'no_show' => LucideIcons.userX,
      _ => LucideIcons.bell,
    };
  }

  void _openDeepLink(BuildContext context, String deepLink) {
    if (deepLink == '/notifications') return;
    if (deepLink == '/payments' ||
        deepLink == '/tasks' ||
        deepLink == '/work' ||
        deepLink == '/booking-requests') {
      context.push(deepLink);
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyNotifications({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.bell, color: AppColors.t3, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.t1,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.t3),
            ),
          ],
        ),
      ),
    );
  }
}
