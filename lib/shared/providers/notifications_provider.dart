import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/slate_models.dart';
import '../repositories/slate_repositories.dart';
import 'workspace_provider.dart';

final notificationsProvider = FutureProvider<List<SlateNotification>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  return ref.watch(notificationsRepositoryProvider).list(workspaceId);
});

final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return 0;
  return ref.watch(notificationsRepositoryProvider).unreadCount(workspaceId);
});

final notificationPreferencesProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return defaultNotificationPrefs;
  return await ref
          .watch(notificationsRepositoryProvider)
          .preferences(workspaceId) ??
      defaultNotificationPrefs;
});

const defaultNotificationPrefs = {
  'all_notifications': true,
  'payment_received': true,
  'new_booking': true,
  'booking_request': true,
  'no_show': true,
  'invoice_overdue': true,
  'lead_followup': true,
  'appointment_reminder_15': false,
  'task_due_morning': false,
  'morning_digest': true,
  'weekly_summary': true,
  'quiet_hours_enabled': true,
  'quiet_sundays': false,
};
