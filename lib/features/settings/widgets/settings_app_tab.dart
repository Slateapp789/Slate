import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/workloop_app_info.dart';
import '../../../shared/providers/maps_preference_provider.dart';
import '../../../shared/utils/maps_launcher.dart';
import '../../../shared/widgets/slate_ui.dart';
import '../legal_document_screen.dart';

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
        const WorkloopSectionHeader(label: 'Apps and connections'),
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
          subtitle: 'Export bookings to a standard calendar file',
          onTap: () => context.push('/calendar-sync'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const WorkloopSectionHeader(label: 'Legal'),
        const SizedBox(height: AppSpacing.xs),
        _PreferenceRow(
          icon: LucideIcons.shieldCheck,
          title: 'Privacy policy',
          subtitle: 'How Workloop handles and protects data',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalDocumentScreen(
                document: WorkloopLegalDocument.privacy,
              ),
            ),
          ),
        ),
        const WorkloopDivider(margin: EdgeInsets.zero),
        _PreferenceRow(
          icon: LucideIcons.fileText,
          title: 'Terms of use',
          subtitle: 'The agreement for using Workloop',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const LegalDocumentScreen(
                document: WorkloopLegalDocument.terms,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const WorkloopSectionHeader(label: 'About Workloop'),
        const SizedBox(height: AppSpacing.xs),
        _InformationRow(label: 'Version', value: WorkloopAppInfo.version),
        const WorkloopDivider(margin: EdgeInsets.zero),
        _InformationRow(label: 'Build', value: WorkloopAppInfo.buildNumber),
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
    final tokens = SlateTheme.of(context);
    return WorkloopListRow(
      onTap: onTap,
      showDivider: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tokens.surfaceSubtle,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: tokens.textSecondary, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: tokens.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: tokens.textTertiary, fontSize: 13),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: tokens.textTertiary,
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
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: tokens.textSecondary, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
