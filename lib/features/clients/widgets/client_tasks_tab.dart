import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/providers/notifications_provider.dart';
import '../../../shared/providers/tasks_provider.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/repositories/slate_repositories.dart';
import '../../../shared/widgets/slate_ui.dart';
import '../providers/client_detail_providers.dart';

class ClientTasksTab extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const ClientTasksTab({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<ClientTasksTab> createState() => _ClientTasksTabState();
}

class _ClientTasksTabState extends ConsumerState<ClientTasksTab> {
  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    String priority = 'medium';
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              const SizedBox(height: 20),
              const Text(
                'New Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    LucideIcons.user,
                    size: 12,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Linked to ${widget.clientName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: AppColors.t1),
                decoration: InputDecoration(
                  hintText: 'Task title',
                  hintStyle: const TextStyle(color: AppColors.t3),
                  filled: true,
                  fillColor: AppColors.bgInteract,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PriorityChip(
                    value: 'high',
                    label: 'High',
                    color: AppColors.error,
                    selected: priority,
                    onTap: (v) => setModal(() => priority = v),
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    value: 'medium',
                    label: 'Medium',
                    color: AppColors.warning,
                    selected: priority,
                    onTap: (v) => setModal(() => priority = v),
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    value: 'low',
                    label: 'Low',
                    color: AppColors.t3,
                    selected: priority,
                    onTap: (v) => setModal(() => priority = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppColors.green,
                          surface: AppColors.bgCard,
                          onSurface: AppColors.t1,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        color: dueDate != null ? AppColors.green : AppColors.t3,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dueDate == null
                            ? 'Set due date (optional)'
                            : _formatDate(dueDate!),
                        style: TextStyle(
                          color: dueDate != null ? AppColors.t1 : AppColors.t3,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final workspaceId = await ref.read(
                      workspaceIdProvider.future,
                    );
                    if (workspaceId == null) return;
                    await ref
                        .read(tasksRepositoryProvider)
                        .create(
                          workspaceId: workspaceId,
                          title: titleController.text.trim(),
                          priority: priority,
                          contactId: widget.clientId,
                          dueDate: dueDate,
                        );
                    if (dueDate != null) {
                      final today = DateTime.now();
                      final todayDate = DateTime(
                        today.year,
                        today.month,
                        today.day,
                      );
                      final dueDateOnly = DateTime(
                        dueDate!.year,
                        dueDate!.month,
                        dueDate!.day,
                      );
                      if (!dueDateOnly.isAfter(
                        todayDate.add(const Duration(days: 1)),
                      )) {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .create(
                              workspaceId: workspaceId,
                              type: 'task_due',
                              title: 'Client task due soon',
                              body:
                                  '${widget.clientName}: ${titleController.text.trim()}',
                              deepLink: '/tasks',
                            );
                      }
                    }
                    ref.invalidate(clientTasksProvider(widget.clientId));
                    ref.invalidate(allTasksProvider);
                    ref.invalidate(tasksProvider);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Add Task',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTask(SlateTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              const SizedBox(height: 24),
              const Text(
                'Delete task?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: const TextStyle(fontSize: 14, color: AppColors.t3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _actionBtn(
                label: 'Delete Task',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(tasksRepositoryProvider).delete(task.id);
                  ref.invalidate(clientTasksProvider(widget.clientId));
                  ref.invalidate(allTasksProvider);
                  ref.invalidate(tasksProvider);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.t3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskActions(SlateTask task) {
    final isDone = task.status == 'done';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDone ? AppColors.t3 : AppColors.t1,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.dueDate == null ? 'No due date' : _formatDue(task.dueDate!),
              style: const TextStyle(fontSize: 13, color: AppColors.t3),
            ),
            const SizedBox(height: 20),
            SlateButton(
              label: isDone ? 'Reopen Task' : 'Mark Complete',
              icon: isDone ? LucideIcons.rotateCcw : LucideIcons.checkCircle,
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(tasksRepositoryProvider)
                    .updateStatus(task.id, isDone ? 'open' : 'done');
                ref.invalidate(clientTasksProvider(widget.clientId));
                ref.invalidate(allTasksProvider);
                ref.invalidate(tasksProvider);
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Delete Task',
              destructive: true,
              onPressed: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _confirmDeleteTask(task);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(clientTasksProvider(widget.clientId));

    return tasks.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (tks) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: GestureDetector(
              onTap: _showAddTaskSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus, color: AppColors.green, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Add Task',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (tks.isEmpty)
            const Expanded(child: _EmptyState())
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(clientTasksProvider(widget.clientId)),
                color: AppColors.green,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: tks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final task = tks[i];
                    final priority = task.priority;
                    final isDone = task.status == 'done';
                    final dueDate = task.dueDate;
                    final priorityColor = priority == 'high'
                        ? AppColors.error
                        : priority == 'medium'
                        ? AppColors.warning
                        : AppColors.t3;

                    return GestureDetector(
                      onTap: () => _showTaskActions(task),
                      onLongPress: () => _confirmDeleteTask(task),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? AppColors.green
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.green
                                      : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 12,
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
                                      color: isDone
                                          ? AppColors.t3
                                          : AppColors.t1,
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (dueDate != null) ...[
                                    const SizedBox(height: 3),
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
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Date helpers ─────────────────────────────────────────────────────────────
  String _formatDate(DateTime dt) {
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

  bool _isDueToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isOverdue(DateTime dt) {
    final today = DateTime.now();
    return dt.isBefore(DateTime(today.year, today.month, today.day));
  }
}

// ── Priority chip ─────────────────────────────────────────────────────────────
class _PriorityChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final String selected;
  final Function(String) onTap;

  const _PriorityChip({
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
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
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? color : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? color : AppColors.t2,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.checkSquare, color: AppColors.t3, size: 32),
          SizedBox(height: 12),
          Text(
            'No tasks linked to this client',
            style: TextStyle(fontSize: 14, color: AppColors.t3),
          ),
        ],
      ),
    );
  }
}

// ── Shared sheet helpers ──────────────────────────────────────────────────────
Widget _handle() => Center(
  child: Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

Widget _actionBtn({
  required String label,
  required VoidCallback onTap,
  Color color = AppColors.green,
}) => SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  ),
);
