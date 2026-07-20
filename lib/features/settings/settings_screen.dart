import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import '../notifications/notifications_screen.dart';
import '../imports/import_data_screen.dart';
import 'support_screen.dart';
import 'widgets/settings_account_tab.dart';
import 'widgets/settings_app_tab.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final name = auth.currentFirstName?.trim();
    final email = auth.currentEmail;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.lg,
                AppSpacing.pageX,
                AppSpacing.xxl,
              ),
              children: [
                Row(
                  children: [
                    WorkloopIconButton(
                      icon: LucideIcons.chevronLeft,
                      semanticLabel: 'Back to more',
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: AppColors.t1,
                          fontSize: 26,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _AccountIdentity(name: name, email: email),
                const SizedBox(height: AppSpacing.xxl),
                const WorkloopSectionHeader(label: 'Your account'),
                const SizedBox(height: AppSpacing.xs),
                _SettingsRow(
                  icon: LucideIcons.user,
                  title: 'Account',
                  subtitle: 'Personal details, password, data and sign out',
                  onTap: () => _open(
                    context,
                    ref,
                    title: 'Account',
                    child: const SettingsAccountTab(),
                  ),
                ),
                _SettingsRow(
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  subtitle: 'Choose the alerts and summaries you receive',
                  onTap: () => _open(
                    context,
                    ref,
                    title: 'Notifications',
                    child: const NotificationSettingsView(),
                  ),
                ),
                _SettingsRow(
                  icon: LucideIcons.slidersHorizontal,
                  title: 'App preferences',
                  subtitle: 'Maps, calendar and Workloop information',
                  showDivider: false,
                  onTap: () => _open(
                    context,
                    ref,
                    title: 'App preferences',
                    child: const SettingsAppTab(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const WorkloopSectionHeader(label: 'Support'),
                const SizedBox(height: AppSpacing.xs),
                _SettingsRow(
                  icon: LucideIcons.lifeBuoy,
                  title: 'Help & support',
                  subtitle: 'Contact support or copy safe diagnostics',
                  showDivider: false,
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const WorkloopSectionHeader(label: 'Your data'),
                const SizedBox(height: AppSpacing.xs),
                _SettingsRow(
                  icon: LucideIcons.import,
                  title: 'Import data',
                  subtitle: 'Contacts, calendar events and selected files',
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportDataScreen()),
                  ),
                ),
                _SettingsRow(
                  icon: LucideIcons.shieldCheck,
                  title: 'Privacy and data',
                  subtitle: 'Export your workspace or request account deletion',
                  showDivider: false,
                  onTap: () => _open(
                    context,
                    ref,
                    title: 'Account',
                    child: const SettingsAccountTab(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'Workloop 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.t4,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Widget child,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _SettingsDestinationScreen(title: title, child: child),
      ),
    );
    ref.invalidate(authRepositoryProvider);
  }
}

class _SettingsDestinationScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsDestinationScreen({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    AppSpacing.lg,
                    AppSpacing.pageX,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      WorkloopIconButton(
                        icon: LucideIcons.chevronLeft,
                        semanticLabel: 'Back to settings',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.t1,
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountIdentity extends StatelessWidget {
  final String? name;
  final String email;

  const _AccountIdentity({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final label = name?.isNotEmpty == true ? name! : 'Your account';
    final initial = label[0].toUpperCase();
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.modBg,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.t3,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onTap,
      showDivider: showDivider,
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
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.t3,
        size: 16,
      ),
    );
  }
}
