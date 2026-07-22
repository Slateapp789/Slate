import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/working_hours.dart';
import '../../shared/widgets/slate_ui.dart';
import '../settings/providers/settings_providers.dart';

class WorkingHoursEditor extends ConsumerStatefulWidget {
  const WorkingHoursEditor({super.key});

  @override
  ConsumerState<WorkingHoursEditor> createState() => _WorkingHoursEditorState();
}

class _WorkingHoursEditorState extends ConsumerState<WorkingHoursEditor> {
  final Map<String, bool> _enabled = {};
  final Map<String, List<_HoursBlock>> _blocks = {};
  bool _hydrated = false;
  bool _saving = false;
  bool _allowPop = false;
  String _initialSnapshot = '';

  void _hydrate(Map<String, dynamic> settings) {
    if (_hydrated) return;
    final rawHours = Map<String, dynamic>.from(
      settings['working_hours'] as Map? ?? {},
    );
    for (final day in workingHourDays) {
      final shortDay = shortToLongDay.entries
          .firstWhere((entry) => entry.value == day)
          .key;
      final rawDay = rawHours[day] ?? rawHours[shortDay];
      final value = rawDay is Map
          ? Map<String, dynamic>.from(rawDay)
          : <String, dynamic>{};
      final source = value.isEmpty ? defaultWorkingHours()[day] : value;
      final parsed = workingHourBlocks(source)
          .map(
            (block) => _HoursBlock(
              start: _parseTime(
                block.start,
                const TimeOfDay(hour: 9, minute: 0),
              ),
              end: _parseTime(block.end, const TimeOfDay(hour: 17, minute: 0)),
            ),
          )
          .toList();
      _enabled[day] =
          value['enabled'] as bool? ?? parsed.isNotEmpty && day != 'Sunday';
      _blocks[day] = parsed.isEmpty
          ? [
              const _HoursBlock(
                start: TimeOfDay(hour: 9, minute: 0),
                end: TimeOfDay(hour: 17, minute: 0),
              ),
            ]
          : parsed;
    }
    _hydrated = true;
    _initialSnapshot = _snapshot();
  }

  String _snapshot() => jsonEncode({
    for (final day in workingHourDays)
      day: {
        'enabled': _enabled[day] ?? false,
        'blocks': (_blocks[day] ?? const <_HoursBlock>[])
            .map(
              (block) => {
                'start': _storageTime(block.start),
                'end': _storageTime(block.end),
              },
            )
            .toList(),
      },
  });

  bool get _hasChanges =>
      _hydrated &&
      _initialSnapshot.isNotEmpty &&
      _snapshot() != _initialSnapshot;

  Future<void> _attemptExit() async {
    final decision = await showWorkloopDraftConfirmation(
      context,
      title: 'Save working hours?',
      message: 'Your latest availability changes have not been saved yet.',
      saveLabel: 'Save hours',
    );
    if (!mounted) return;
    switch (decision) {
      case WorkloopDraftDecision.save:
        await _save();
        return;
      case WorkloopDraftDecision.discard:
        _allowPop = true;
        Navigator.pop(context);
        return;
      case WorkloopDraftDecision.stay:
        return;
    }
  }

  TimeOfDay _parseTime(String value, TimeOfDay fallback) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return fallback;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _storageTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime(String day, int index, {required bool start}) async {
    final block = _blocks[day]![index];
    final picked = await _showScrollingTimePicker(
      start ? block.start : block.end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _blocks[day]![index] = start
          ? block.copyWith(start: picked)
          : block.copyWith(end: picked);
    });
  }

  Future<TimeOfDay?> _showScrollingTimePicker(TimeOfDay initial) async {
    return showWorkloopTimePicker(context: context, initialTime: initial);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) return;
      final nextHours = <String, dynamic>{};
      for (final day in workingHourDays) {
        final blocks = _blocks[day]!
            .map(
              (block) => {
                'start': _storageTime(block.start),
                'end': _storageTime(block.end),
              },
            )
            .toList();
        nextHours[day] = {
          'enabled': _enabled[day] ?? false,
          'blocks': blocks,
          if (blocks.isNotEmpty) 'start': blocks.first['start'],
          if (blocks.isNotEmpty) 'end': blocks.last['end'],
        };
      }
      await ref.read(workspaceSettingsRepositoryProvider).update(workspaceId, {
        'working_hours': nextHours,
      });
      ref.invalidate(settingsWorkspaceSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Working hours updated')));
      _allowPop = true;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save working hours')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsWorkspaceSettingsProvider);
    return PopScope(
      canPop: _allowPop || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _attemptExit();
      },
      child: settings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
        error: (_, __) => WorkloopEmptyState(
          icon: LucideIcons.clock3,
          title: 'Could not load working hours',
          subtitle: 'Try again in a moment.',
          action: WorkloopTextButton(
            label: 'Try again',
            onPressed: () => ref.invalidate(settingsWorkspaceSettingsProvider),
          ),
        ),
        data: (data) {
          _hydrate(data ?? const {});
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageX,
              0,
              AppSpacing.pageX,
              AppSpacing.xxl,
            ),
            children: [
              const Text(
                'Set when you usually work. These hours appear on your public profile and guide booking checks.',
                style: TextStyle(
                  color: AppColors.t3,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (
                var dayIndex = 0;
                dayIndex < workingHourDays.length;
                dayIndex++
              ) ...[
                _DayHoursEditor(
                  day: workingHourDays[dayIndex],
                  enabled: _enabled[workingHourDays[dayIndex]] ?? false,
                  blocks: _blocks[workingHourDays[dayIndex]] ?? const [],
                  onEnabled: (value) => setState(
                    () => _enabled[workingHourDays[dayIndex]] = value,
                  ),
                  onPickStart: (index) =>
                      _pickTime(workingHourDays[dayIndex], index, start: true),
                  onPickEnd: (index) =>
                      _pickTime(workingHourDays[dayIndex], index, start: false),
                  onAddBlock: () => setState(
                    () => _blocks[workingHourDays[dayIndex]]!.add(
                      const _HoursBlock(
                        start: TimeOfDay(hour: 16, minute: 0),
                        end: TimeOfDay(hour: 20, minute: 0),
                      ),
                    ),
                  ),
                  onRemoveBlock: (index) => setState(
                    () => _blocks[workingHourDays[dayIndex]]!.removeAt(index),
                  ),
                ),
                if (dayIndex != workingHourDays.length - 1)
                  const WorkloopDivider(
                    margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
              WorkloopPrimaryButton(
                label: _saving ? 'Saving' : 'Save hours',
                icon: LucideIcons.check,
                onPressed: _saving ? null : _save,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayHoursEditor extends StatelessWidget {
  final String day;
  final bool enabled;
  final List<_HoursBlock> blocks;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<int> onPickStart;
  final ValueChanged<int> onPickEnd;
  final VoidCallback onAddBlock;
  final ValueChanged<int> onRemoveBlock;

  const _DayHoursEditor({
    required this.day,
    required this.enabled,
    required this.blocks,
    required this.onEnabled,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onAddBlock,
    required this.onRemoveBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                day,
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              enabled ? 'Working' : 'Off',
              style: const TextStyle(
                color: AppColors.t3,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Switch.adaptive(
              value: enabled,
              activeThumbColor: AppColors.accentPrimary,
              onChanged: onEnabled,
            ),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < blocks.length; index++) ...[
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Start',
                    time: blocks[index].start,
                    onTap: () => onPickStart(index),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TimeButton(
                    label: 'End',
                    time: blocks[index].end,
                    onTap: () => onPickEnd(index),
                  ),
                ),
                if (blocks.length > 1) ...[
                  const SizedBox(width: AppSpacing.xs),
                  WorkloopIconButton(
                    icon: LucideIcons.x,
                    semanticLabel: 'Remove time block',
                    size: 40,
                    onTap: () => onRemoveBlock(index),
                  ),
                ],
              ],
            ),
            if (index != blocks.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          WorkloopTextButton(label: 'Add working block', onPressed: onAddBlock),
        ],
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.bgRaised.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.t3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time.format(context),
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.clock3, color: AppColors.t3, size: 16),
          ],
        ),
      ),
    );
  }
}

class _HoursBlock {
  final TimeOfDay start;
  final TimeOfDay end;

  const _HoursBlock({required this.start, required this.end});

  _HoursBlock copyWith({TimeOfDay? start, TimeOfDay? end}) {
    return _HoursBlock(start: start ?? this.start, end: end ?? this.end);
  }
}
