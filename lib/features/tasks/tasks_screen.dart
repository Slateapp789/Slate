import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';

part 'task_card.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _filter = 'Open';

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddTask(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.plus, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: ['Open', 'Done', 'All'].map((f) {
                  final active = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.green : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? AppColors.green : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.t2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: tasks.when(
                loading: () => _skeletonList(),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (data) {
                  final filtered = data.where((t) {
                    if (_filter == 'Open') return t.status == 'open';
                    if (_filter == 'Done') return t.status == 'done';
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.t3,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'Open'
                                ? 'No open tasks'
                                : _filter == 'Done'
                                ? 'No completed tasks'
                                : 'No tasks yet',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.t2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap New to add one',
                            style: TextStyle(fontSize: 13, color: AppColors.t3),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(allTasksProvider),
                    color: AppColors.green,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final task = filtered[i];
                        return _TaskCard(
                          task: task,
                          onToggle: () => _toggleTask(task),
                          onDelete: () => _confirmDelete(context, task),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _toggleTask(SlateTask task) async {
    final newStatus = task.status == 'done' ? 'open' : 'done';
    await ref.read(tasksRepositoryProvider).updateStatus(task.id, newStatus);
    ref.invalidate(allTasksProvider);
    ref.invalidate(tasksProvider);
  }

  void _confirmDelete(BuildContext context, SlateTask task) {
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(tasksRepositoryProvider).delete(task.id);
                    ref.invalidate(allTasksProvider);
                    ref.invalidate(tasksProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Delete Task',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
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

  void _showAddTask(BuildContext context) {
    final titleController = TextEditingController();
    String priority = 'medium';
    DateTime? dueDate;
    String? selectedClientId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final clients = ref.watch(clientsProvider);
          return Padding(
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'New Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.t1,
                  ),
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
                clients.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgInteract,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedClientId,
                        isExpanded: true,
                        dropdownColor: AppColors.bgRaised,
                        icon: const Icon(
                          LucideIcons.chevronDown,
                          color: AppColors.t3,
                          size: 16,
                        ),
                        hint: const Text(
                          'Link to client (optional)',
                          style: TextStyle(color: AppColors.t3, fontSize: 14),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'No client',
                              style: TextStyle(
                                color: AppColors.t3,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ...data.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppColors.t1,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setModal(() => selectedClientId = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.t3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _priorityChip(
                      'high',
                      'High',
                      AppColors.error,
                      priority,
                      (v) => setModal(() => priority = v),
                    ),
                    const SizedBox(width: 8),
                    _priorityChip(
                      'medium',
                      'Medium',
                      AppColors.warning,
                      priority,
                      (v) => setModal(() => priority = v),
                    ),
                    const SizedBox(width: 8),
                    _priorityChip(
                      'low',
                      'Low',
                      AppColors.t3,
                      priority,
                      (v) => setModal(() => priority = v),
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
                          color: dueDate != null
                              ? AppColors.green
                              : AppColors.t3,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          dueDate == null
                              ? 'Set due date (optional)'
                              : _formatDate(dueDate!),
                          style: TextStyle(
                            color: dueDate != null
                                ? AppColors.t1
                                : AppColors.t3,
                            fontSize: 14,
                          ),
                        ),
                        if (dueDate != null) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setModal(() => dueDate = null),
                            child: const Icon(
                              LucideIcons.x,
                              color: AppColors.t3,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _saveTask(
                      ctx,
                      titleController.text,
                      priority,
                      dueDate,
                      selectedClientId,
                    ),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _priorityChip(
    String value,
    String label,
    Color color,
    String selected,
    Function(String) onTap,
  ) {
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

  Future<void> _saveTask(
    BuildContext ctx,
    String title,
    String priority,
    DateTime? dueDate,
    String? clientId,
  ) async {
    if (title.trim().isEmpty) return;
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return;
    await ref
        .read(tasksRepositoryProvider)
        .create(
          workspaceId: workspaceId,
          title: title,
          priority: priority,
          dueDate: dueDate,
          contactId: clientId,
        );
    if (dueDate != null) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (!dueDateOnly.isAfter(todayDate.add(const Duration(days: 1)))) {
        await ref
            .read(notificationsRepositoryProvider)
            .create(
              workspaceId: workspaceId,
              type: 'task_due',
              title: 'Task due soon',
              body: title.trim(),
              deepLink: '/tasks',
            );
      }
    }
    ref.invalidate(allTasksProvider);
    ref.invalidate(tasksProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    if (ctx.mounted) Navigator.pop(ctx);
  }

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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
