import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';

part 'task_card.dart';

enum _TaskView { urgent, upcoming, done, all }

class _TaskSection {
  final String title;
  final String subtitle;
  final List<SlateTask> tasks;

  const _TaskSection({
    required this.title,
    required this.subtitle,
    required this.tasks,
  });
}

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _TaskView _view = _TaskView.urgent;

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.lg,
                AppSpacing.pageX,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.t1,
                      letterSpacing: 0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showTaskEditor(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slateLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.plus,
                            color: AppColors.panelInk,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.panelInk,
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
            Expanded(
              child: tasks.when(
                loading: () => _skeletonList(),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageX,
                  ),
                  child: SlateErrorState(message: 'Could not load tasks'),
                ),
                data: (data) {
                  final sorted = [...data]..sort(_taskSort);
                  final sections = _sectionsFor(sorted);

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(allTasksProvider),
                    color: AppColors.green,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageX,
                        0,
                        AppSpacing.pageX,
                        112,
                      ),
                      children: [
                        _TaskViewSwitcher(
                          value: _view,
                          onChanged: (view) => setState(() => _view = view),
                        ),
                        const SizedBox(height: 18),
                        if (sections.every((section) => section.tasks.isEmpty))
                          _emptyState()
                        else
                          ...sections
                              .where((section) => section.tasks.isNotEmpty)
                              .map(
                                (section) => _TaskSectionView(
                                  section: section,
                                  onOpen: _showTaskDetails,
                                  onCompleteRequest: _confirmComplete,
                                  onReopen: _reopenTask,
                                  onDelete: _confirmDelete,
                                ),
                              ),
                      ],
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        40,
      ),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) =>
          const SlateLoadingBlock(height: 80, radius: AppRadius.md),
    );
  }

  Widget _emptyState() {
    final title = switch (_view) {
      _TaskView.urgent => 'Nothing urgent',
      _TaskView.upcoming => 'No upcoming tasks',
      _TaskView.done => 'No completed tasks',
      _TaskView.all => 'No tasks yet',
    };
    final subtitle = switch (_view) {
      _TaskView.urgent => 'Add a task or check upcoming work.',
      _TaskView.upcoming => 'Tasks with future due dates will appear here.',
      _TaskView.done => 'Completed tasks will appear here.',
      _TaskView.all => 'Tap New to add the first task.',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 42),
      child: SlateEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  List<_TaskSection> _sectionsFor(List<SlateTask> tasks) {
    final open = tasks.where((task) => task.status != 'done').toList();
    final done = tasks.where((task) => task.status == 'done').toList();
    final overdue = open.where(_isOverdueTask).toList();
    final today = open.where(_isTodayTask).toList();
    final upcoming = open.where(_isUpcomingTask).toList();
    final noDate = open.where((task) => task.dueDate == null).toList();

    switch (_view) {
      case _TaskView.urgent:
        return [
          _TaskSection(
            title: 'Overdue',
            subtitle: 'Needs a decision',
            tasks: overdue,
          ),
          _TaskSection(title: 'Today', subtitle: 'Due today', tasks: today),
          _TaskSection(
            title: 'No date',
            subtitle: 'Clarify when these matter',
            tasks: noDate,
          ),
        ];
      case _TaskView.upcoming:
        return [
          _TaskSection(
            title: 'Next 7 days',
            subtitle: 'Coming soon',
            tasks: upcoming.where(_isWithinWeekTask).toList(),
          ),
          _TaskSection(
            title: 'Later',
            subtitle: 'Future work',
            tasks: upcoming.where((task) => !_isWithinWeekTask(task)).toList(),
          ),
        ];
      case _TaskView.done:
        return [
          _TaskSection(
            title: 'Completed',
            subtitle: 'Recently done',
            tasks: done,
          ),
        ];
      case _TaskView.all:
        return [
          _TaskSection(title: 'Open', subtitle: 'Still active', tasks: open),
          _TaskSection(title: 'Done', subtitle: 'Completed', tasks: done),
        ];
    }
  }

  void _showTaskDetails(SlateTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: task.status == 'done'
                          ? AppColors.t3
                          : AppColors.t1,
                      decoration: task.status == 'done'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                _PriorityBadge(priority: task.priority),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TaskDetailChip(
                  icon: LucideIcons.circleDot,
                  label: task.status == 'done' ? 'Done' : 'Open',
                ),
                if (task.dueDate != null)
                  _TaskDetailChip(
                    icon: LucideIcons.calendar,
                    label: _formatDue(task.dueDate!),
                  ),
                if (task.clientName != null)
                  _TaskDetailChip(
                    icon: LucideIcons.user,
                    label: task.clientName!,
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SlateButton(
              label: task.status == 'done' ? 'Reopen Task' : 'Mark Complete',
              icon: task.status == 'done'
                  ? LucideIcons.rotateCcw
                  : LucideIcons.checkCircle,
              onPressed: () {
                Navigator.pop(ctx);
                if (task.status == 'done') {
                  _reopenTask(task);
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _confirmComplete(task);
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Edit Task',
              icon: LucideIcons.pencil,
              secondary: true,
              onPressed: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _showTaskEditor(context, task: task);
                });
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Delete Task',
              destructive: true,
              onPressed: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _confirmDelete(task);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskEditor(BuildContext context, {SlateTask? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    String priority = task?.priority ?? 'medium';
    DateTime? dueDate = task?.dueDate;
    String? selectedClientId = task?.contactId;
    var saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final clients = ref.watch(clientsProvider);
          return SlateSheetFrame(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task == null ? 'New task' : 'Edit task',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  autofocus: task == null,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: AppColors.t1),
                  decoration: const InputDecoration(
                    hintText: 'What needs doing?',
                  ),
                ),
                const SizedBox(height: 14),
                clients.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => _ClientPicker(
                    clients: data,
                    selectedClientId: selectedClientId,
                    onChanged: (value) =>
                        setModal(() => selectedClientId = value),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.t3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PriorityChoice(
                      value: 'high',
                      label: 'High',
                      selected: priority,
                      color: AppColors.error,
                      onTap: (value) => setModal(() => priority = value),
                    ),
                    const SizedBox(width: 8),
                    _PriorityChoice(
                      value: 'medium',
                      label: 'Medium',
                      selected: priority,
                      color: AppColors.warning,
                      onTap: (value) => setModal(() => priority = value),
                    ),
                    const SizedBox(width: 8),
                    _PriorityChoice(
                      value: 'low',
                      label: 'Low',
                      selected: priority,
                      color: AppColors.t3,
                      onTap: (value) => setModal(() => priority = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DueDatePicker(
                  dueDate: dueDate,
                  onChanged: (value) => setModal(() => dueDate = value),
                ),
                const SizedBox(height: 22),
                SlateButton(
                  label: saving
                      ? 'Saving...'
                      : task == null
                      ? 'Add Task'
                      : 'Save Changes',
                  icon: task == null ? LucideIcons.plus : LucideIcons.check,
                  onPressed: saving
                      ? null
                      : () async {
                          setModal(() => saving = true);
                          await _saveTask(
                            ctx,
                            task: task,
                            title: titleController.text,
                            priority: priority,
                            dueDate: dueDate,
                            clientId: selectedClientId,
                          );
                          if (ctx.mounted) setModal(() => saving = false);
                        },
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(titleController.dispose);
  }

  Future<void> _saveTask(
    BuildContext ctx, {
    SlateTask? task,
    required String title,
    required String priority,
    required DateTime? dueDate,
    required String? clientId,
  }) async {
    if (title.trim().isEmpty) return;
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return;
    if (task == null) {
      await ref
          .read(tasksRepositoryProvider)
          .create(
            workspaceId: workspaceId,
            title: title,
            priority: priority,
            dueDate: dueDate,
            contactId: clientId,
          );
    } else {
      await ref
          .read(tasksRepositoryProvider)
          .update(
            taskId: task.id,
            title: title,
            priority: priority,
            dueDate: dueDate,
            contactId: clientId,
          );
    }
    await _maybeCreateDueNotification(workspaceId, title, dueDate);
    if (ctx.mounted) Navigator.pop(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshTasks();
      _refreshTaskNotifications();
    });
  }

  Future<void> _maybeCreateDueNotification(
    String workspaceId,
    String title,
    DateTime? dueDate,
  ) async {
    if (dueDate == null) return;
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

  void _confirmComplete(SlateTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Complete this task?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.t1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.t3),
            ),
            const SizedBox(height: 22),
            SlateButton(
              label: 'Mark Complete',
              icon: LucideIcons.checkCircle,
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(tasksRepositoryProvider)
                    .updateStatus(task.id, 'done');
                _refreshTasks();
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reopenTask(SlateTask task) async {
    await ref.read(tasksRepositoryProvider).updateStatus(task.id, 'open');
    _refreshTasks();
  }

  void _confirmDelete(SlateTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete task?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
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
            SlateButton(
              label: 'Delete Task',
              destructive: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(tasksRepositoryProvider).delete(task.id);
                _refreshTasks();
              },
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshTasks() {
    ref.invalidate(allTasksProvider);
    ref.invalidate(tasksProvider);
  }

  void _refreshTaskNotifications() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }
}

class _TaskViewSwitcher extends StatelessWidget {
  final _TaskView value;
  final ValueChanged<_TaskView> onChanged;

  const _TaskViewSwitcher({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _TaskView.values.map((view) {
          final active = value == view;
          return GestureDetector(
            onTap: () => onChanged(view),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.t1.withValues(alpha: 0.12)
                    : AppColors.t1.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: active
                      ? AppColors.t1.withValues(alpha: 0.18)
                      : AppColors.t1.withValues(alpha: 0.07),
                ),
              ),
              child: Text(
                _viewLabel(view),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? AppColors.t1 : AppColors.t2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskSectionView extends StatelessWidget {
  final _TaskSection section;
  final ValueChanged<SlateTask> onOpen;
  final ValueChanged<SlateTask> onCompleteRequest;
  final ValueChanged<SlateTask> onReopen;
  final ValueChanged<SlateTask> onDelete;

  const _TaskSectionView({
    required this.section,
    required this.onOpen,
    required this.onCompleteRequest,
    required this.onReopen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                section.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${section.tasks.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            section.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.t3),
          ),
          const SizedBox(height: 8),
          ...section.tasks.map(
            (task) => _TaskCard(
              task: task,
              onOpen: () => onOpen(task),
              onCompleteRequest: () => onCompleteRequest(task),
              onReopen: () => onReopen(task),
              onDelete: () => onDelete(task),
            ),
          ),
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

int _taskSort(SlateTask a, SlateTask b) {
  if (a.status != b.status) {
    if (a.status == 'done') return 1;
    if (b.status == 'done') return -1;
  }
  final aDate = a.dueDate;
  final bDate = b.dueDate;
  if (aDate != null && bDate != null) {
    final dateCompare = aDate.compareTo(bDate);
    if (dateCompare != 0) return dateCompare;
  } else if (aDate != null) {
    return -1;
  } else if (bDate != null) {
    return 1;
  }
  return _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
}

int _priorityRank(String priority) {
  return switch (priority) {
    'high' => 0,
    'medium' => 1,
    _ => 2,
  };
}

Color _priorityColor(String priority) {
  return switch (priority) {
    'high' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.t3,
  };
}

String _priorityLabel(String priority) {
  return switch (priority) {
    'high' => 'High',
    'medium' => 'Medium',
    _ => 'Low',
  };
}

String _viewLabel(_TaskView view) {
  return switch (view) {
    _TaskView.urgent => 'Urgent',
    _TaskView.upcoming => 'Upcoming',
    _TaskView.done => 'Done',
    _TaskView.all => 'All',
  };
}

bool _isOverdueTask(SlateTask task) {
  final due = task.dueDate;
  if (due == null || task.status == 'done') return false;
  return _dateOnly(due).isBefore(_dateOnly(DateTime.now()));
}

bool _isTodayTask(SlateTask task) {
  final due = task.dueDate;
  if (due == null || task.status == 'done') return false;
  final today = _dateOnly(DateTime.now());
  return _dateOnly(due) == today;
}

bool _isUpcomingTask(SlateTask task) {
  final due = task.dueDate;
  if (due == null || task.status == 'done') return false;
  return _dateOnly(due).isAfter(_dateOnly(DateTime.now()));
}

bool _isWithinWeekTask(SlateTask task) {
  final due = task.dueDate;
  if (due == null) return false;
  final today = _dateOnly(DateTime.now());
  final week = today.add(const Duration(days: 7));
  final dueDay = _dateOnly(due);
  return dueDay.isAfter(today) && !dueDay.isAfter(week);
}

bool _isDueToday(DateTime dt) => _dateOnly(dt) == _dateOnly(DateTime.now());

bool _isOverdue(DateTime dt) =>
    _dateOnly(dt).isBefore(_dateOnly(DateTime.now()));

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _formatDue(DateTime dt) {
  final today = _dateOnly(DateTime.now());
  final d = _dateOnly(dt);
  final diff = d.difference(today).inDays;
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  if (diff == -1) return 'Due yesterday';
  if (diff < 0) return 'Overdue ${-diff}d';
  return _formatDate(dt);
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
  return '${dt.day} ${months[dt.month - 1]}';
}
