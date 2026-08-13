import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/notifications/local_reminder_service.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAllRead = false;

  Future<void> _markAllRead() async {
    if (_markingAllRead) return;
    setState(() => _markingAllRead = true);
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) {
        throw StateError('No active workspace');
      }
      await ref.read(notificationsRepositoryProvider).markAllRead(workspaceId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications could not be marked as read. Try again.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAllRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    AppSpacing.screenTop,
                    AppSpacing.pageX,
                    AppSpacing.xs,
                  ),
                  child: WorkloopRouteHeader(
                    title: 'Notifications',
                    trailing: notifications.maybeWhen(
                      data: (items) {
                        final unread = items.where((item) => !item.read).length;
                        if (unread == 0) return null;
                        return WorkloopTextButton(
                          label: _markingAllRead ? 'Marking…' : 'Mark all read',
                          onPressed: _markingAllRead ? null : _markAllRead,
                        );
                      },
                      orElse: () => null,
                    ),
                  ),
                ),
                Expanded(
                  child: notifications.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                    error: (_, _) => Center(
                      child: WorkloopEmptyState(
                        icon: LucideIcons.wifiOff,
                        title: 'Could not load notifications',
                        subtitle: 'Check your connection, then try again.',
                        action: WorkloopTextButton(
                          label: 'Try again',
                          onPressed: () =>
                              ref.invalidate(notificationsProvider),
                        ),
                      ),
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
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageX,
                            AppSpacing.sm,
                            AppSpacing.pageX,
                            AppSpacing.xxl,
                          ),
                          children: _groupedNotificationChildren(items),
                        ),
                      );
                    },
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

class NotificationSettingsView extends ConsumerWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    return prefs.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
        child: SlateLoadingBlock(height: 180, radius: AppRadius.lg),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
        child: SlateErrorState(
          message: 'Could not load notification settings.',
          onRetry: () => ref.invalidate(notificationPreferencesProvider),
        ),
      ),
      data: (values) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          0,
          AppSpacing.pageX,
          AppSpacing.xxl,
        ),
        children: [
          const WorkloopSurface(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Business activity stays in Workloop’s in-app centre. Task reminders you choose and optional booking reminders are scheduled on this device. Remote push is not enabled.',
              style: TextStyle(color: AppColors.t2, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _DeviceReminderStatus(),
          const SizedBox(height: AppSpacing.xl),
          _PreferenceGroup(
            title: 'Scheduled on this device',
            values: values,
            items: const [
              _PreferenceItem(
                'appointment_reminder_15',
                'Upcoming bookings',
                'Alert me about 15 minutes before each booking.',
                requiresDevicePermission: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Task reminders are chosen inside each task and normally arrive at 09:00 on the selected reminder day.',
            style: TextStyle(color: AppColors.t3, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xl),
          _PreferenceGroup(
            title: 'Business activity',
            values: values,
            items: const [
              _PreferenceItem(
                'all_notifications',
                'All notifications',
                'Turn all in-app activity notifications off at once.',
              ),
              _PreferenceItem(
                'payment_received',
                'Payment received',
                'A payment has been recorded.',
              ),
              _PreferenceItem(
                'new_booking',
                'New booking',
                'A booking has been confirmed.',
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
          const SizedBox(height: AppSpacing.xl),
          _PreferenceGroup(
            title: 'Follow-ups',
            values: values,
            items: const [
              _PreferenceItem(
                'no_show',
                'No-show check',
                'Booking has not been completed.',
              ),
              _PreferenceItem(
                'lead_followup',
                'Lead follow-up',
                'A lead has gone quiet.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceReminderStatus extends ConsumerStatefulWidget {
  const _DeviceReminderStatus();

  @override
  ConsumerState<_DeviceReminderStatus> createState() =>
      _DeviceReminderStatusState();
}

class _DeviceReminderStatusState extends ConsumerState<_DeviceReminderStatus> {
  late Future<LocalReminderPermission> _status;

  @override
  void initState() {
    super.initState();
    _status = ref.read(localReminderServiceProvider).permissionStatus();
  }

  Future<void> _requestPermission() async {
    final request = ref.read(localReminderServiceProvider).requestPermission();
    setState(() => _status = request);
    final result = await request;
    if (!mounted || result == LocalReminderPermission.granted) return;
    final message = result == LocalReminderPermission.unsupported
        ? 'Scheduled reminders are available in the iOS and Android apps.'
        : 'Notifications are still off. You can enable them in your device settings.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalReminderPermission>(
      future: _status,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final ready = status == LocalReminderPermission.granted;
        final unsupported = status == LocalReminderPermission.unsupported;
        final title = ready
            ? 'Device reminders ready'
            : unsupported
            ? 'Device reminders unavailable here'
            : 'Device reminders are off';
        final subtitle = ready
            ? 'Chosen reminders can appear even when Workloop is closed.'
            : unsupported
            ? 'Use the Workloop iOS or Android app for scheduled alerts.'
            : 'Turn them on so chosen task and booking reminders can arrive.';

        return WorkloopSurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                ready ? LucideIcons.bellRing : LucideIcons.bellOff,
                size: 18,
                color: ready ? AppColors.accentInk : AppColors.t3,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.t1,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.t3,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (!ready && !unsupported) ...[
                const SizedBox(width: AppSpacing.sm),
                WorkloopTextButton(
                  label: 'Turn on',
                  onPressed: snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : _requestPermission,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PreferenceGroup extends ConsumerStatefulWidget {
  final String title;
  final Map<String, dynamic> values;
  final List<_PreferenceItem> items;

  const _PreferenceGroup({
    required this.title,
    required this.values,
    required this.items,
  });

  @override
  ConsumerState<_PreferenceGroup> createState() => _PreferenceGroupState();
}

class _PreferenceGroupState extends ConsumerState<_PreferenceGroup> {
  final Set<String> _savingKeys = {};

  Future<void> _updatePreference(_PreferenceItem item, bool next) async {
    if (_savingKeys.contains(item.key)) return;
    setState(() => _savingKeys.add(item.key));
    try {
      if (next && item.requiresDevicePermission) {
        final permission = await ref
            .read(localReminderServiceProvider)
            .requestPermission();
        if (!mounted) return;
        if (permission != LocalReminderPermission.granted) {
          final message = permission == LocalReminderPermission.unsupported
              ? 'Scheduled reminders are available in the iOS and Android apps.'
              : 'Notifications are off. Enable them in your device settings to receive reminders.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          return;
        }
      }
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) {
        throw StateError('No active workspace');
      }
      await ref.read(notificationsRepositoryProvider).upsertPreferences(
        workspaceId,
        {item.key: next},
      );
      ref.invalidate(notificationPreferencesProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    } catch (_) {
      ref.invalidate(notificationPreferencesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'That notification setting could not be saved. Try again.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingKeys.remove(item.key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkloopSectionHeader(label: widget.title),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < widget.items.length; i++) ...[
          _PreferenceRow(
            item: widget.items[i],
            value: widget.values[widget.items[i].key] as bool? ?? false,
            onChanged: _savingKeys.contains(widget.items[i].key)
                ? null
                : (next) => _updatePreference(widget.items[i], next),
          ),
          if (i < widget.items.length - 1)
            const WorkloopDivider(margin: EdgeInsets.zero),
        ],
      ],
    );
  }
}

class _PreferenceItem {
  final String key;
  final String title;
  final String subtitle;
  final bool requiresDevicePermission;

  const _PreferenceItem(
    this.key,
    this.title,
    this.subtitle, {
    this.requiresDevicePermission = false,
  });
}

class _PreferenceRow extends StatelessWidget {
  final _PreferenceItem item;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _PreferenceRow({
    required this.item,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                    fontWeight: FontWeight.w600,
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
          Switch.adaptive(value: value, onChanged: onChanged),
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
      for (var index = 0; index < todayItems.length; index++) ...[
        _NotificationTile(item: todayItems[index]),
        if (index != todayItems.length - 1)
          const WorkloopDivider(margin: EdgeInsets.zero),
      ],
    ],
    if (earlierItems.isNotEmpty) ...[
      const SizedBox(height: AppSpacing.lg),
      const _NotificationGroupLabel('Earlier'),
      for (var index = 0; index < earlierItems.length; index++) ...[
        _NotificationTile(item: earlierItems[index]),
        if (index != earlierItems.length - 1)
          const WorkloopDivider(margin: EdgeInsets.zero),
      ],
    ],
  ];
}

class _NotificationGroupLabel extends StatelessWidget {
  final String label;
  const _NotificationGroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: 2),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
    final hasDeepLink = item.deepLink?.isNotEmpty == true;
    final isInteractive = !item.read || hasDeepLink;

    Future<void> activate() async {
      if (!item.read) {
        try {
          await ref.read(notificationsRepositoryProvider).markRead(item.id);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationsProvider);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This notification could not be marked as read.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
      if (context.mounted && hasDeepLink) {
        _openDeepLink(context, item.deepLink!);
      }
    }

    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    _iconForType(item.type),
                    color: item.read ? AppColors.t3 : AppColors.t1,
                    size: 18,
                  ),
                ),
                if (!item.read)
                  const Positioned(
                    right: 1,
                    top: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 7, height: 7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 14,
                    fontWeight: item.read ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: AppColors.t2,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (item.deepLink?.isNotEmpty == true) ...[
            const SizedBox(width: AppSpacing.xs),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 15,
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      button: isInteractive,
      label:
          '${item.read ? '' : 'Unread notification. '}${item.title}. '
          '${item.body}',
      hint: switch ((item.read, hasDeepLink)) {
        (false, true) => 'Marks as read and opens the related item',
        (false, false) => 'Marks as read',
        (true, true) => 'Opens the related item',
        (true, false) => null,
      },
      onTap: isInteractive ? activate : null,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: isInteractive ? activate : null,
            child: tile,
          ),
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
                fontWeight: FontWeight.w600,
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
