part of 'tasks_screen.dart';

class _TaskCard extends StatefulWidget {
  final SlateTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _toggling = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDone = task.status == 'done';
    final priority = task.priority;
    final dueDate = task.dueDate;
    final clientName = task.clientName;

    final priorityColor = priority == 'high'
        ? AppColors.error
        : priority == 'medium'
        ? AppColors.warning
        : AppColors.t3;

    return GestureDetector(
      onLongPress: widget.onDelete,
      child: AnimatedScale(
        scale: _toggling ? 0.985 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: _toggling
              ? null
              : () async {
                  setState(() => _toggling = true);
                  await Future.delayed(const Duration(milliseconds: 80));
                  widget.onToggle();
                  if (mounted) setState(() => _toggling = false);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.t1.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.standard,
                  curve: AppMotion.curve,
                  width: 22,
                  height: 22,
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
                          size: 13,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDone ? AppColors.t3 : AppColors.t1,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (clientName != null || dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (clientName != null) ...[
                              const Icon(
                                LucideIcons.user,
                                size: 11,
                                color: AppColors.t3,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.t3,
                                ),
                              ),
                              if (dueDate != null)
                                const Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.t3,
                                  ),
                                ),
                            ],
                            if (dueDate != null)
                              Text(
                                _formatDue(dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isOverdue(dueDate) && !isDone
                                      ? AppColors.error
                                      : _isDueToday(dueDate) && !isDone
                                      ? AppColors.warning
                                      : AppColors.t3,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.t3 : priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isDueToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isOverdue(DateTime dt) {
    final today = DateTime.now();
    return dt.isBefore(DateTime(today.year, today.month, today.day));
  }

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff == -1) return 'Due yesterday';
    if (diff < 0) return 'Overdue ${-diff}d';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
