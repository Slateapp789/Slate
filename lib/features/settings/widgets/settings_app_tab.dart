import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_providers.dart';
import 'settings_helpers.dart';

class SettingsAppTab extends ConsumerWidget {
  const SettingsAppTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(settingsBusinessProfileProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        sectionLabel('About'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              infoRow('App', 'Slate'),
              Divider(height: 1, color: AppColors.border),
              infoRow('Version', '1.0.0 (MVP)'),
              Divider(height: 1, color: AppColors.border),
              infoRow('Built with', 'Flutter + Supabase'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        sectionLabel('V1 Foundations'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _actionRow(
                context,
                LucideIcons.bell,
                'Notification Centre',
                'Bell centre and V1 alert preferences',
                '/notifications',
              ),
              Divider(height: 1, color: AppColors.border),
              _actionRow(
                context,
                LucideIcons.inbox,
                'Booking Requests',
                'Requests from your public profile',
                '/booking-requests',
              ),
              Divider(height: 1, color: AppColors.border),
              profile.maybeWhen(
                data: (value) {
                  final handle = value?.handle.trim();
                  if (handle == null || handle.isEmpty) {
                    return _comingSoonRow(
                      LucideIcons.globe,
                      'Public Profile Page',
                      'Set a handle in Business settings',
                    );
                  }
                  return _actionRow(
                    context,
                    LucideIcons.globe,
                    'Public Profile Page',
                    '/p/$handle',
                    '/p/$handle',
                  );
                },
                orElse: () => _comingSoonRow(
                  LucideIcons.globe,
                  'Public Profile Page',
                  'Set a handle in Business settings',
                ),
              ),
              Divider(height: 1, color: AppColors.border),
              _actionRow(
                context,
                LucideIcons.calendarClock,
                'Calendar Sync',
                'Contained sync module',
                '/calendar-sync',
              ),
              Divider(height: 1, color: AppColors.border),
              _comingSoonRow(
                LucideIcons.creditCard,
                'Online Payments',
                'Accept card payments via Stripe',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionRow(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    String path,
  ) {
    return GestureDetector(
      onTap: () => context.push(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.t1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.t3),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _comingSoonRow(IconData icon, String label, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.t3, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.t2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.t3),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bgInteract,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Soon',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.t3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
