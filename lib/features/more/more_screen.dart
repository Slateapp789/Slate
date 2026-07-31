import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slate_ui.dart';

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
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.screenTop,
                AppSpacing.pageX,
                AppSpacing.bottomNavClearance,
              ),
              children: [
                const WorkloopPageHeader(
                  title: 'Tools',
                  subtitle: 'Useful tools that support your day-to-day.',
                  color: AppColors.accentPrimary,
                ),
                const SizedBox(height: AppSpacing.xl),
                _WorkspaceSection(
                  onOpenMoney: onOpenMoney,
                  onOpenTasks: onOpenTasks,
                  onOpenNotes: onOpenNotes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSection extends StatelessWidget {
  final VoidCallback onOpenMoney;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotes;

  const _WorkspaceSection({
    required this.onOpenMoney,
    required this.onOpenTasks,
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkloopSectionHeader(label: 'Business tools'),
        const SizedBox(height: AppSpacing.sm),
        SlateSurface(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              _WorkspaceLauncher(
                key: const ValueKey('more-workspace-money'),
                icon: LucideIcons.banknote,
                title: 'Money',
                subtitle: 'Track what came in, went out, and is still owed',
                semanticLabel: 'Open Money workspace',
                onTap: onOpenMoney,
              ),
              _WorkspaceLauncher(
                key: const ValueKey('more-workspace-tasks'),
                icon: LucideIcons.listChecks,
                title: 'Tasks',
                subtitle: 'Plan follow-ups and work that needs doing',
                semanticLabel: 'Open Tasks workspace',
                onTap: onOpenTasks,
              ),
              _WorkspaceLauncher(
                key: const ValueKey('more-workspace-notes'),
                icon: LucideIcons.stickyNote,
                title: 'Notes',
                subtitle: 'Keep useful client and business context',
                semanticLabel: 'Open Notes workspace',
                showDivider: false,
                onTap: onOpenNotes,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkspaceLauncher extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final bool showDivider;
  final VoidCallback onTap;

  const _WorkspaceLauncher({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    this.showDivider = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);

    void handleTap() {
      SlateHaptics.tap();
      onTap();
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: handleTap,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: handleTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 82),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: tokens.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(icon, color: tokens.accentInk, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tokens.textTertiary,
                                  fontSize: 12,
                                  height: 1.3,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          LucideIcons.chevronRight,
                          color: tokens.textTertiary,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showDivider)
              Divider(height: 1, color: tokens.divider.withValues(alpha: 0.66)),
          ],
        ),
      ),
    );
  }
}
