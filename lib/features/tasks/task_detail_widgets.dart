part of 'tasks_screen.dart';

class _TaskContextPanel extends StatelessWidget {
  final SlateTask task;

  const _TaskContextPanel({required this.task});

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      color: AppColors.t1.withValues(alpha: 0.035),
      borderColor: AppColors.t1.withValues(alpha: 0.05),
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _TaskContextRow(
            icon: LucideIcons.calendarClock,
            label: 'Timing',
            value: task.dueDate == null
                ? 'No due date'
                : _formatDue(task.dueDate!),
          ),
          const SizedBox(height: 12),
          _TaskContextRow(
            icon: LucideIcons.user,
            label: 'Client',
            value: task.clientName ?? 'Not linked',
          ),
          const SizedBox(height: 12),
          _TaskContextRow(
            icon: LucideIcons.bell,
            label: 'Reminder',
            value: _reminderLabel(task.reminderTiming),
          ),
          if (task.updatedAt != null || task.createdAt != null) ...[
            const SizedBox(height: 12),
            _TaskContextRow(
              icon: LucideIcons.history,
              label: task.updatedAt != null ? 'Updated' : 'Created',
              value: _formatDate(task.updatedAt ?? task.createdAt!),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskContextRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TaskContextRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.t3),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.t3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.t2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskChecklistPanel extends StatelessWidget {
  final AsyncValue<List<TaskChecklistItem>> items;
  final VoidCallback onAdd;
  final ValueChanged<TaskChecklistItem> onToggle;
  final ValueChanged<TaskChecklistItem> onEdit;
  final ValueChanged<TaskChecklistItem> onDelete;

  const _TaskChecklistPanel({
    required this.items,
    required this.onAdd,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      color: AppColors.bgRaised.withValues(alpha: 0.52),
      borderColor: AppColors.t1.withValues(alpha: 0.06),
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.listChecks, size: 16, color: AppColors.t3),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Checklist',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.t1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slateLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: AppColors.panelInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          items.when(
            loading: () =>
                const SlateLoadingBlock(height: 48, radius: AppRadius.md),
            error: (_, __) => const Text(
              'Checklist could not load',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
            data: (data) {
              if (data.isEmpty) {
                return const Text(
                  'Break this task into smaller steps.',
                  style: TextStyle(color: AppColors.t3, fontSize: 13),
                );
              }
              return Column(
                children: data
                    .map(
                      (item) => _ChecklistRow(
                        item: item,
                        onToggle: () => onToggle(item),
                        onEdit: () => onEdit(item),
                        onDelete: () => onDelete(item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final TaskChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChecklistRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.completed ? AppColors.green : Colors.transparent,
                border: Border.all(
                  color: item.completed ? AppColors.green : AppColors.border,
                  width: 2,
                ),
              ),
              child: item.completed
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: item.completed ? AppColors.t3 : AppColors.t1,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  decoration: item.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(LucideIcons.x, size: 15, color: AppColors.t3),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TaskDetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.t1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.t3),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.t2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _priorityLabel(priority),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
