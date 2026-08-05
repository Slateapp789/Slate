import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/utils/currency_format.dart';
import '../../shared/widgets/slate_ui.dart';

class MoreScreen extends ConsumerWidget {
  final VoidCallback onOpenMoney;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotes;
  final VoidCallback? onCreateMoney;
  final VoidCallback? onCreateTask;
  final VoidCallback? onCreateNote;

  const MoreScreen({
    super.key,
    required this.onOpenMoney,
    required this.onOpenTasks,
    required this.onOpenNotes,
    this.onCreateMoney,
    this.onCreateTask,
    this.onCreateNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = SlateTheme.of(context);
    final payments = ref.watch(invoicesProvider);
    final tasks = ref.watch(allTasksProvider);
    final notes = ref.watch(allNotesProvider);

    final moneyStatus = payments.when(
      data: (items) {
        final owed = items.fold<double>(
          0,
          (total, payment) => total + outstandingAmountFor(payment),
        );
        return owed > 0 ? '${formatPounds(owed)} to collect' : 'Nothing owed';
      },
      loading: () => 'Checking your ledger',
      error: (_, _) => 'Open Money to retry',
    );
    final taskStatus = tasks.when(
      data: (items) {
        final open = items.where((task) => task.status != 'done').length;
        return open == 0
            ? 'No open tasks'
            : '$open open ${open == 1 ? 'task' : 'tasks'}';
      },
      loading: () => 'Checking your next actions',
      error: (_, _) => 'Open Tasks to retry',
    );
    final noteStatus = notes.when(
      data: (items) => items.isEmpty
          ? 'Ready for your first note'
          : '${items.length} saved ${items.length == 1 ? 'note' : 'notes'}',
      loading: () => 'Checking your notes',
      error: (_, _) => 'Open Notes to retry',
    );

    return Scaffold(
      backgroundColor: tokens.background,
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
                WorkloopPageHeader(
                  title: 'Tools',
                  subtitle:
                      'Capture the admin around your work, then get back to your day.',
                  color: tokens.accentInk,
                ),
                const SizedBox(height: AppSpacing.xl),
                _QuickCaptureSection(
                  onCreateMoney: onCreateMoney ?? onOpenMoney,
                  onCreateTask: onCreateTask ?? onOpenTasks,
                  onCreateNote: onCreateNote ?? onOpenNotes,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _WorkspaceSection(
                  moneyStatus: moneyStatus,
                  taskStatus: taskStatus,
                  noteStatus: noteStatus,
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

class _QuickCaptureSection extends StatelessWidget {
  final VoidCallback onCreateMoney;
  final VoidCallback onCreateTask;
  final VoidCallback onCreateNote;

  const _QuickCaptureSection({
    required this.onCreateMoney,
    required this.onCreateTask,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        key: const ValueKey('tools-quick-money'),
        icon: LucideIcons.circlePoundSterling,
        label: 'Record money',
        onTap: onCreateMoney,
      ),
      _QuickActionData(
        key: const ValueKey('tools-quick-task'),
        icon: LucideIcons.listPlus,
        label: 'New task',
        onTap: onCreateTask,
      ),
      _QuickActionData(
        key: const ValueKey('tools-quick-note'),
        icon: LucideIcons.filePlus,
        label: 'New note',
        onTap: onCreateNote,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkloopSectionHeader(label: 'Quick capture'),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackActions =
                constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.35;
            if (stackActions) {
              return Column(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    _QuickAction(data: actions[index], compact: true),
                    if (index != actions.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  Expanded(child: _QuickAction(data: actions[index])),
                  if (index != actions.length - 1)
                    const SizedBox(width: AppSpacing.xs),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionData {
  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _QuickAction extends StatelessWidget {
  final _QuickActionData data;
  final bool compact;

  const _QuickAction({required this.data, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);

    void handleTap() {
      SlateHaptics.action();
      data.onTap();
    }

    return Semantics(
      button: true,
      label: data.label,
      onTap: handleTap,
      child: ExcludeSemantics(
        child: Material(
          key: data.key,
          color: tokens.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: tokens.divider),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: handleTap,
            child: SizedBox(
              height: compact ? 58 : 96,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? AppSpacing.md : AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: compact
                    ? Row(
                        children: [
                          _QuickActionIcon(icon: data.icon),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _QuickActionLabel(label: data.label)),
                          Icon(
                            LucideIcons.arrowUpRight,
                            color: tokens.textTertiary,
                            size: 16,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _QuickActionIcon(icon: data.icon),
                          const SizedBox(height: AppSpacing.xs),
                          _QuickActionLabel(label: data.label),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;

  const _QuickActionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tokens.accentStrong,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: tokens.accentBorder, width: 1),
      ),
      child: Icon(icon, color: tokens.onAccent, size: 17),
    );
  }
}

class _QuickActionLabel extends StatelessWidget {
  final String label;

  const _QuickActionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: SlateTheme.of(context).textPrimary,
        fontSize: 12,
        height: 1.15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WorkspaceSection extends StatelessWidget {
  final String moneyStatus;
  final String taskStatus;
  final String noteStatus;
  final VoidCallback onOpenMoney;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenNotes;

  const _WorkspaceSection({
    required this.moneyStatus,
    required this.taskStatus,
    required this.noteStatus,
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
        _WorkspaceLauncher(
          key: const ValueKey('more-workspace-money'),
          icon: LucideIcons.banknote,
          title: 'Money',
          subtitle: 'See what came in, went out, and is still owed',
          status: moneyStatus,
          semanticLabel: 'Open Money workspace',
          onTap: onOpenMoney,
        ),
        const SizedBox(height: AppSpacing.sm),
        _WorkspaceLauncher(
          key: const ValueKey('more-workspace-tasks'),
          icon: LucideIcons.listChecks,
          title: 'Tasks',
          subtitle: 'Plan follow-ups and the work that needs doing',
          status: taskStatus,
          semanticLabel: 'Open Tasks workspace',
          onTap: onOpenTasks,
        ),
        const SizedBox(height: AppSpacing.sm),
        _WorkspaceLauncher(
          key: const ValueKey('more-workspace-notes'),
          icon: LucideIcons.stickyNote,
          title: 'Notes',
          subtitle: 'Keep useful client and business context close',
          status: noteStatus,
          semanticLabel: 'Open Notes workspace',
          onTap: onOpenNotes,
        ),
      ],
    );
  }
}

class _WorkspaceLauncher extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final String semanticLabel;
  final VoidCallback onTap;

  const _WorkspaceLauncher({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);

    void handleTap() {
      onTap();
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      hint: status,
      onTap: handleTap,
      child: ExcludeSemantics(
        child: SlateSurface(
          padding: EdgeInsets.zero,
          color: tokens.surface,
          borderColor: tokens.divider,
          onTap: handleTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 108),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tokens.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: tokens.accentInk, size: 21),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.arrowUpRight,
                              color: tokens.textTertiary,
                              size: 17,
                            ),
                          ],
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
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.accentInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
