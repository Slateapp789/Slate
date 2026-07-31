part of 'tasks_screen.dart';

class _TaskContextPanel extends StatelessWidget {
  final SlateTask task;

  const _TaskContextPanel({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
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
            fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
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
  final VoidCallback onRetry;
  final ValueChanged<TaskChecklistItem> onToggle;
  final ValueChanged<TaskChecklistItem> onEdit;
  final ValueChanged<TaskChecklistItem> onDelete;

  const _TaskChecklistPanel({
    required this.items,
    required this.onAdd,
    required this.onRetry,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            WorkloopTextButton(label: 'Add', onPressed: onAdd),
          ],
        ),
        const SizedBox(height: 12),
        items.when(
          loading: () =>
              const SlateLoadingBlock(height: 48, radius: AppRadius.md),
          error: (_, _) => SlateErrorState(
            message: 'Checklist could not load.',
            onRetry: onRetry,
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
          Semantics(
            button: true,
            checked: item.completed,
            label: item.completed
                ? 'Mark ${item.title} incomplete'
                : 'Mark ${item.title} complete',
            onTap: onToggle,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: SizedBox(
                  width: AppSpacing.minTouch,
                  height: AppSpacing.minTouch,
                  child: Center(
                    child: AnimatedContainer(
                      key: ValueKey(Theme.of(context).brightness),
                      duration: AppMotion.responsive(
                        context,
                        AppMotion.standard,
                      ),
                      curve: AppMotion.curve,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.completed
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: item.completed
                              ? AppColors.success
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: item.completed
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.bg,
                              size: 13,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: onEdit,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouch,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.completed ? AppColors.t3 : AppColors.t1,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: item.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Remove ${item.title} from checklist',
            child: WorkloopIconButton(
              icon: LucideIcons.x,
              semanticLabel: 'Remove ${item.title} from checklist',
              size: AppSpacing.minTouch,
              onTap: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
