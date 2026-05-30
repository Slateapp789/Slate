part of 'tasks_screen.dart';

class _TaskCard extends StatelessWidget {
  final SlateTask task;
  final VoidCallback onOpen;
  final VoidCallback onCompleteRequest;
  final VoidCallback onReopen;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onOpen,
    required this.onCompleteRequest,
    required this.onReopen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == 'done';
    final priorityColor = _priorityColor(task.priority);

    return Dismissible(
      key: ValueKey(task.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (isDone) {
            onReopen();
          } else {
            onCompleteRequest();
          }
        } else {
          onDelete();
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        icon: isDone ? LucideIcons.rotateCcw : LucideIcons.checkCircle,
        label: isDone ? 'Reopen' : 'Complete',
        color: AppColors.green,
      ),
      secondaryBackground: const _SwipeBackground(
        alignment: Alignment.centerRight,
        icon: LucideIcons.trash2,
        label: 'Delete',
        color: AppColors.error,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.t1.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isDone ? onReopen : onCompleteRequest,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12, bottom: 18),
                  child: AnimatedContainer(
                    duration: AppMotion.standard,
                    curve: AppMotion.curve,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.green : Colors.transparent,
                      border: Border.all(
                        color: isDone ? AppColors.green : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDone ? AppColors.t3 : AppColors.t1,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PriorityDot(
                          color: isDone ? AppColors.t3 : priorityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _MetaPill(
                          icon: LucideIcons.flag,
                          label: _priorityLabel(task.priority),
                          color: isDone ? AppColors.t3 : priorityColor,
                        ),
                        if (task.dueDate != null)
                          _MetaPill(
                            icon: LucideIcons.calendar,
                            label: _formatDue(task.dueDate!),
                            color: !isDone && _isOverdue(task.dueDate!)
                                ? AppColors.error
                                : !isDone && _isDueToday(task.dueDate!)
                                ? AppColors.warning
                                : AppColors.t3,
                          ),
                        if (task.clientName != null)
                          _MetaPill(
                            icon: LucideIcons.user,
                            label: task.clientName!,
                            color: AppColors.t3,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.t3,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: color.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final Color color;
  const _PriorityDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
