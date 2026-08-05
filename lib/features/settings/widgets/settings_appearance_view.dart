import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../../shared/widgets/slate_ui.dart';

class SettingsAppearanceView extends ConsumerWidget {
  const SettingsAppearanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(workloopAppearanceProvider).value ??
        WorkloopAppearance.system;
    final effectiveLabel = Theme.of(context).brightness == Brightness.dark
        ? 'Dark'
        : 'Light';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        AppSpacing.xxl,
      ),
      children: [
        WorkloopSurface(
          color: SlateTheme.of(context).surfaceRaised,
          borderColor: SlateTheme.of(context).dividerStrong,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: SlateTheme.of(context).surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _appearanceIcon(appearance),
                  color: SlateTheme.of(context).accentInk,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appearance.label} appearance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      appearance == WorkloopAppearance.system
                          ? 'Your phone is currently using $effectiveLabel.'
                          : appearance.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SlateTheme.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const WorkloopSectionHeader(label: 'Choose appearance'),
        const SizedBox(height: AppSpacing.sm),
        for (final option in WorkloopAppearance.values) ...[
          _AppearanceOption(
            option: option,
            selected: appearance == option,
            onTap: () => _setAppearance(context, ref, option),
          ),
          if (option != WorkloopAppearance.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Light mode uses a softened paper canvas rather than pure white, so it stays comfortable while keeping text and controls clear.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SlateTheme.of(context).textTertiary,
          ),
        ),
      ],
    );
  }

  Future<void> _setAppearance(
    BuildContext context,
    WidgetRef ref,
    WorkloopAppearance appearance,
  ) async {
    try {
      await ref
          .read(workloopAppearanceProvider.notifier)
          .setAppearance(appearance);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appearance could not be saved.')),
      );
    }
  }
}

class _AppearanceOption extends StatelessWidget {
  final WorkloopAppearance option;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label} appearance',
      child: WorkloopSurface(
        key: ValueKey('appearance-${option.name}'),
        onTap: onTap,
        color: selected ? tokens.surfaceRaised : tokens.surface,
        borderColor: selected ? tokens.accentInk : tokens.divider,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? tokens.accentStrong : tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                _appearanceIcon(option),
                color: selected ? tokens.onAccent : tokens.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    option.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              selected ? LucideIcons.circleCheck : LucideIcons.circle,
              color: selected ? tokens.accentInk : tokens.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _appearanceIcon(WorkloopAppearance appearance) => switch (appearance) {
  WorkloopAppearance.system => LucideIcons.monitor,
  WorkloopAppearance.light => LucideIcons.sun,
  WorkloopAppearance.dark => LucideIcons.moon,
};
