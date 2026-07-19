part of 'tasks_screen.dart';

class _TaskFormSectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;

  const _TaskFormSectionLabel(this.text, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.12,
            color: AppColors.t1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskSaveAction extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _TaskSaveAction({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.modTasks.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: enabled && !loading ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 58, minHeight: 42),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.modTasks,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: enabled ? AppColors.modTasks : AppColors.t3,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TaskTemplatePicker extends StatelessWidget {
  final ValueChanged<_TaskTemplate> onSelect;

  const _TaskTemplatePicker({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Start with',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.t3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _taskTemplates
              .map(
                (template) => _DateChoice(
                  label: template.label,
                  onTap: () => onSelect(template),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DraftChecklistEditor extends StatelessWidget {
  final TextEditingController controller;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _DraftChecklistEditor({
    required this.controller,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.listChecks, size: 15, color: AppColors.t3),
            SizedBox(width: 8),
            Text(
              'Checklist',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.t1,
              ),
            ),
            Spacer(),
            Text(
              'Saved with task',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.t3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
                style: const TextStyle(color: AppColors.t1),
                decoration: const InputDecoration(
                  hintText: 'Add a step',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.slateLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 18,
                  color: AppColors.panelInk,
                ),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.circle, size: 16, color: AppColors.t3),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.t2,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemove(entry.key),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(LucideIcons.x, size: 14, color: AppColors.t3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClientPicker extends StatelessWidget {
  final List<dynamic> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onChanged;

  const _ClientPicker({
    required this.clients,
    required this.selectedClientId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedClient =
        selectedClientId != null &&
        clients.any((client) => client.id == selectedClientId);
    final safeSelectedClientId = hasSelectedClient ? selectedClientId : null;

    return WorkloopPickerField<String?>(
      value: safeSelectedClientId,
      title: 'Link a client',
      hint: 'Link to client',
      searchHint: 'Search clients',
      searchable: true,
      leadingIcon: LucideIcons.users,
      options: [
        const WorkloopPickerOption<String?>(
          value: null,
          label: 'No client',
          subtitle: 'Keep this as a general task',
        ),
        ...clients.map(
          (client) => WorkloopPickerOption<String?>(
            value: client.id as String,
            label: client.name as String,
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _DueDatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onChanged;

  const _DueDatePicker({required this.dueDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final selectedDate = dueDate == null ? null : _dateOnly(dueDate!);
    final customSelected =
        selectedDate != null &&
        selectedDate != today &&
        selectedDate != tomorrow &&
        selectedDate != nextWeek;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.t3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DateChoice(
              label: 'Today',
              selected: selectedDate == today,
              onTap: () => onChanged(today),
            ),
            _DateChoice(
              label: 'Tomorrow',
              selected: selectedDate == tomorrow,
              onTap: () => onChanged(tomorrow),
            ),
            _DateChoice(
              label: 'Next week',
              selected: selectedDate == nextWeek,
              onTap: () => onChanged(nextWeek),
            ),
            _DateChoice(
              label: 'Custom',
              selected: customSelected,
              onTap: () => _pickCustomDate(context),
            ),
            if (dueDate != null)
              _DateChoice(label: 'Clear date', onTap: () => onChanged(null)),
          ],
        ),
        if (dueDate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${_formatDate(dueDate!)}',
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) onChanged(_dateOnly(picked));
  }
}

class _TaskOptionsDisclosure extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _TaskOptionsDisclosure({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(
              LucideIcons.slidersHorizontal,
              size: 16,
              color: AppColors.t3,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'More options',
                style: TextStyle(
                  color: AppColors.t2,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AppMotion.standard,
              child: const Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: AppColors.t3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderPicker extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _ReminderPicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('none', 'No reminder'),
      ('today', 'On due day'),
      ('day_before', 'Day before'),
      ('week_before', 'Week before'),
    ];

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: AppMotion.fast,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.t3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final active = value == option.$1;
                return GestureDetector(
                  onTap: () => onChanged(option.$1),
                  child: AnimatedContainer(
                    duration: AppMotion.standard,
                    curve: AppMotion.curve,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.slateLight
                          : AppColors.t1.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: active
                            ? AppColors.borderStrong
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      option.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.panelInk : AppColors.t2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (!enabled) ...[
              const SizedBox(height: 8),
              const Text(
                'Choose a due date before adding a reminder.',
                style: TextStyle(fontSize: 12, color: AppColors.t3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateChoice({
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.modTasks.withValues(alpha: 0.14)
              : AppColors.t1.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? AppColors.modTasks.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.modTasks : AppColors.t2,
          ),
        ),
      ),
    );
  }
}

class _PriorityChoice extends StatelessWidget {
  final String value;
  final String label;
  final String selected;
  final Color color;
  final ValueChanged<String> onTap;

  const _PriorityChoice({
    required this.value,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : AppColors.bgInteract,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: active ? color : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? color : AppColors.t2,
          ),
        ),
      ),
    );
  }
}
