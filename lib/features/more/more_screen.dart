import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slate_ui.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  final VoidCallback onOpenMoney;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotes;

  const MoreScreen({
    super.key,
    required this.onOpenMoney,
    required this.onOpenTasks,
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            AppSpacing.lg,
            AppSpacing.pageX,
            AppSpacing.bottomNavClearance,
          ),
          children: [
            const WorkloopPageHeader(
              icon: LucideIcons.menu,
              title: 'More',
              subtitle: 'Everything else, kept close without the clutter.',
              color: AppColors.accentPrimary,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _MoreSection(
              label: 'Business',
              children: [
                _MoreRow(
                  icon: LucideIcons.banknote,
                  title: 'Money',
                  subtitle: 'Income, expenses, and payments',
                  color: AppColors.modFinance,
                  onTap: onOpenMoney,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _MoreSection(
              label: 'Organise',
              children: [
                _MoreRow(
                  icon: LucideIcons.listChecks,
                  title: 'Tasks',
                  subtitle: 'Follow-ups and business admin',
                  color: AppColors.modTasks,
                  onTap: onOpenTasks,
                ),
                _MoreRow(
                  icon: LucideIcons.stickyNote,
                  title: 'Notes',
                  subtitle: 'Business and client context',
                  color: AppColors.modNotes,
                  onTap: onOpenNotes,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _MoreSection(
              label: 'You',
              children: [
                _MoreRow(
                  icon: LucideIcons.userCircle,
                  title: 'Profile',
                  subtitle: 'Business details and public profile',
                  color: AppColors.accentPrimary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                _MoreRow(
                  icon: LucideIcons.settings,
                  title: 'Settings',
                  subtitle: 'Alerts, account, and app preferences',
                  color: AppColors.t2,
                  onTap: () => _openSettings(context, initialTab: 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context, {required int initialTab}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(initialTab: initialTab)),
    );
  }
}

class _MoreSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _MoreSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.t3,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...children,
      ],
    );
  }
}

class _MoreRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
