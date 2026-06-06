part of 'tasks_screen.dart';

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
    return SlateSurface(
      color: AppColors.t1.withValues(alpha: 0.035),
      borderColor: AppColors.t1.withValues(alpha: 0.05),
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
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
                    const Icon(
                      LucideIcons.circle,
                      size: 16,
                      color: AppColors.t3,
                    ),
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
                        child: Icon(
                          LucideIcons.x,
                          size: 14,
                          color: AppColors.t3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeSelectedClientId,
          isExpanded: true,
          dropdownColor: AppColors.bgRaised,
          icon: const Icon(
            LucideIcons.chevronDown,
            color: AppColors.t3,
            size: 16,
          ),
          hint: const Text(
            'Link to client',
            style: TextStyle(color: AppColors.t3, fontSize: 14),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'No client',
                style: TextStyle(color: AppColors.t3, fontSize: 14),
              ),
            ),
            ...clients.map(
              (client) => DropdownMenuItem<String?>(
                value: client.id as String,
                child: Text(
                  client.name as String,
                  style: const TextStyle(color: AppColors.t1, fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DueDatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onChanged;

  const _DueDatePicker({required this.dueDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
              onTap: () => onChanged(_dateOnly(DateTime.now())),
            ),
            _DateChoice(
              label: 'Tomorrow',
              onTap: () => onChanged(
                _dateOnly(DateTime.now().add(const Duration(days: 1))),
              ),
            ),
            _DateChoice(
              label: 'Next week',
              onTap: () => onChanged(
                _dateOnly(DateTime.now().add(const Duration(days: 7))),
              ),
            ),
            _DateChoice(label: 'Custom', onTap: () => _pickCustomDate(context)),
            if (dueDate != null)
              _DateChoice(label: 'Clear date', onTap: () => onChanged(null)),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 2),
            );
            if (picked != null) onChanged(_dateOnly(picked));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgInteract,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  color: dueDate != null ? AppColors.green : AppColors.t3,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dueDate == null ? 'Custom date' : _formatDate(dueDate!),
                    style: TextStyle(
                      color: dueDate != null ? AppColors.t1 : AppColors.t3,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (dueDate != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const Icon(
                      LucideIcons.x,
                      color: AppColors.t3,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
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
  final VoidCallback onTap;

  const _DateChoice({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.t1.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.t2,
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
