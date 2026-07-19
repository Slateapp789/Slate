import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/maps_preference_provider.dart';
import '../../../shared/utils/maps_launcher.dart';
import '../../../shared/widgets/slate_ui.dart';

class SettingsAppTab extends ConsumerWidget {
  const SettingsAppTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsPreference = ref.watch(preferredMapsAppProvider);
    final preference = mapsPreference.value ?? MapsAppPreference.askEveryTime;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        AppSpacing.xxl,
      ),
      children: [
        const WorkloopSectionHeader(label: 'General'),
        const SizedBox(height: AppSpacing.xs),
        _PreferenceRow(
          icon: LucideIcons.navigation,
          title: 'Default maps app',
          subtitle: preference.label,
          onTap: () async {
            final selected = await showMapsPreferenceSheet(
              context,
              selected: preference,
            );
            if (selected == null) return;
            await ref
                .read(preferredMapsAppProvider.notifier)
                .setPreference(selected);
          },
        ),
        const WorkloopDivider(margin: EdgeInsets.zero),
        _PreferenceRow(
          icon: LucideIcons.calendarClock,
          title: 'Calendar',
          subtitle: 'Export and calendar connection options',
          onTap: () => context.push('/calendar-sync'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const WorkloopSectionHeader(label: 'About Workloop'),
        const SizedBox(height: AppSpacing.xs),
        const _InformationRow(label: 'Version', value: '1.0.0'),
        const WorkloopDivider(margin: EdgeInsets.zero),
        const _InformationRow(label: 'Build', value: 'MVP'),
        const WorkloopDivider(margin: EdgeInsets.zero),
        const _InformationRow(label: 'Technology', value: 'Flutter + Supabase'),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onTap,
      showDivider: false,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.modBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.t2, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.t3, fontSize: 13),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.t3,
        size: 16,
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final String label;
  final String value;

  const _InformationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.t2, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
