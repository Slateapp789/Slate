import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slate_ui.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _supportEmail = 'support@workloop.app';

  @override
  Widget build(BuildContext context) {
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
                      semanticLabel: 'Back to settings',
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Help & support',
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
                const SizedBox(height: AppSpacing.xxl),
                const WorkloopSectionHeader(label: 'Get help'),
                const SizedBox(height: AppSpacing.xs),
                _SupportRow(
                  icon: LucideIcons.mail,
                  title: 'Contact support',
                  subtitle: 'Open a new email with basic app information.',
                  onTap: () => _contactSupport(context),
                ),
                _SupportRow(
                  icon: LucideIcons.copy,
                  title: 'Copy diagnostic information',
                  subtitle: 'Version and platform only—never client data.',
                  onTap: () => _copyDiagnostics(context),
                  showDivider: false,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const WorkloopSectionHeader(label: 'Privacy'),
                const SizedBox(height: AppSpacing.xs),
                const WorkloopSurface(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Workloop keeps business records inside your workspace. Imports are reviewed before saving, and account export and deletion controls are available under Account settings.',
                    style: TextStyle(
                      color: AppColors.t2,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Center(
                  child: Text(
                    'Workloop 1.0.0 (1)',
                    style: TextStyle(
                      color: AppColors.t4,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    SlateHaptics.action();
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Workloop support',
        'body': '${_diagnostics()}\n\nPlease describe what happened:\n',
      },
    );
    if (await launchUrl(uri)) return;
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Support email copied')));
  }

  Future<void> _copyDiagnostics(BuildContext context) async {
    SlateHaptics.action();
    await Clipboard.setData(ClipboardData(text: _diagnostics()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostic information copied')),
    );
  }

  String _diagnostics() {
    return 'Workloop 1.0.0 (1)\nPlatform: ${defaultTargetPlatform.name}\nMode: ${kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug'}';
  }
}

class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SupportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopListRow(
      onTap: onTap,
      showDivider: showDivider,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: tokens.textTertiary,
          fontSize: 13,
          height: 1.35,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: tokens.textTertiary,
        size: 16,
      ),
    );
  }
}
