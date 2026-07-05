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

part 'task_logic.dart';
part 'task_card.dart';
part 'task_detail_widgets.dart';
part 'task_editor_widgets.dart';

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
    final taskCounts = tasks.maybeWhen(
      data: (data) => _countsForTasks(data),
      orElse: () => const _TaskCounts(
        overdue: 0,
        today: 0,
        upcoming: 0,
        noDate: 0,
        done: 0,
        open: 0,
      ),
    );

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
              child: SlateFeatureHeader(
                icon: LucideIcons.listChecks,
                title: 'Tasks',
                subtitle: 'Keep follow-ups and admin from slipping.',
                color: AppColors.modTasks,
                trailing: SlateIconButton(
                  icon: LucideIcons.plus,
                  semanticLabel: 'New task',
                  color: AppColors.modTasks,
                  backgroundColor: AppColors.modTasks.withValues(alpha: 0.10),
                  onTap: () => _showTaskEditor(context),
                ),
                stats: [
                  SlateHeaderStat(
                    value: '${taskCounts.urgent}',
                    label: 'Urgent',
                    color: AppColors.modTasks,
                  ),
                  SlateHeaderStat(
                    value: '${taskCounts.upcoming}',
                    label: 'Upcoming',
                    color: AppColors.warning,
                  ),
                  SlateHeaderStat(
                    value: '${taskCounts.done}',
                    label: 'Done',
                    color: AppColors.statusSuccess,
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
                  final sections = _sectionsForView(sorted, _view);
                  final counts = _countsForTasks(sorted);

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
                          counts: counts,
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

  void _showTaskDetails(SlateTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final checklist = ref.watch(taskChecklistProvider(task.id));

          return SlateSheetFrame(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.78,
              ),
              child: SingleChildScrollView(
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
                        _TaskDetailChip(
                          icon: LucideIcons.bell,
                          label: _reminderLabel(task.reminderTiming),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _TaskContextPanel(task: task),
                    const SizedBox(height: 18),
                    _TaskChecklistPanel(
                      items: checklist,
                      onAdd: () => _showChecklistEditor(task),
                      onToggle: (item) => _toggleChecklistItem(task, item),
                      onEdit: (item) => _showChecklistEditor(task, item: item),
                      onDelete: (item) => _deleteChecklistItem(task, item),
                    ),
                    const SizedBox(height: 22),
                    SlateButton(
                      label: task.status == 'done'
                          ? 'Reopen Task'
                          : 'Mark Complete',
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
                    Row(
                      children: [
                        Expanded(
                          child: SlateButton(
                            label: 'Edit',
                            icon: LucideIcons.pencil,
                            secondary: true,
                            onPressed: () {
                              Navigator.pop(ctx);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  _showTaskEditor(context, task: task);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SlateButton(
                            label: 'Delete',
                            destructive: true,
                            onPressed: () {
                              Navigator.pop(ctx);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _confirmDelete(task);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTaskEditor(BuildContext context, {SlateTask? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final checklistController = TextEditingController();
    String priority = task?.priority ?? 'medium';
    DateTime? dueDate = task?.dueDate;
    String? selectedClientId = task?.contactId;
    String reminderTiming = task?.reminderTiming ?? 'none';
    final draftChecklist = <String>[];
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.78,
              ),
              child: SingleChildScrollView(
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
                    if (task == null) ...[
                      _TaskTemplatePicker(
                        onSelect: (template) {
                          setModal(() {
                            if (titleController.text.trim().isEmpty) {
                              titleController.text = template.title;
                            }
                            priority = template.priority;
                            if (template.dueInDays != null) {
                              dueDate = _dateOnly(
                                DateTime.now().add(
                                  Duration(days: template.dueInDays!),
                                ),
                              );
                              reminderTiming = template.dueInDays == 0
                                  ? 'today'
                                  : 'day_before';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
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
                    const SizedBox(height: 16),
                    _ReminderPicker(
                      value: reminderTiming,
                      enabled: dueDate != null,
                      onChanged: (value) =>
                          setModal(() => reminderTiming = value),
                    ),
                    if (task == null) ...[
                      const SizedBox(height: 16),
                      _DraftChecklistEditor(
                        controller: checklistController,
                        items: draftChecklist,
                        onAdd: () {
                          final title = checklistController.text.trim();
                          if (title.isEmpty) return;
                          setModal(() {
                            draftChecklist.add(title);
                            checklistController.clear();
                          });
                        },
                        onRemove: (index) =>
                            setModal(() => draftChecklist.removeAt(index)),
                      ),
                    ],
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
                              final saved = await _saveTask(
                                ctx,
                                task: task,
                                title: titleController.text,
                                priority: priority,
                                dueDate: dueDate,
                                clientId: selectedClientId,
                                reminderTiming: reminderTiming,
                                checklistTitles: draftChecklist,
                              );
                              if (!saved && ctx.mounted) {
                                setModal(() => saving = false);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _disposeControllerAfterSheetClose(titleController);
      _disposeControllerAfterSheetClose(checklistController);
    });
  }

  Future<bool> _saveTask(
    BuildContext ctx, {
    SlateTask? task,
    required String title,
    required String priority,
    required DateTime? dueDate,
    required String? clientId,
    required String reminderTiming,
    required List<String> checklistTitles,
  }) async {
    if (title.trim().isEmpty) return false;
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    if (task == null) {
      final taskId = await ref
          .read(tasksRepositoryProvider)
          .create(
            workspaceId: workspaceId,
            title: title,
            priority: priority,
            dueDate: dueDate,
            contactId: clientId,
            reminderTiming: dueDate == null ? 'none' : reminderTiming,
          );
      await ref
          .read(tasksRepositoryProvider)
          .addChecklistItems(
            workspaceId: workspaceId,
            taskId: taskId,
            titles: checklistTitles,
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
            reminderTiming: dueDate == null ? 'none' : reminderTiming,
          );
    }
    await _maybeCreateDueNotification(
      workspaceId,
      title,
      dueDate,
      dueDate == null ? 'none' : reminderTiming,
    );
    if (ctx.mounted) Navigator.pop(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshTasks();
      _refreshTaskNotifications();
    });
    return true;
  }

  Future<void> _maybeCreateDueNotification(
    String workspaceId,
    String title,
    DateTime? dueDate,
    String reminderTiming,
  ) async {
    if (dueDate == null || reminderTiming == 'none') return;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final shouldCreateNow = switch (reminderTiming) {
      'today' => dueDateOnly == todayDate,
      'day_before' => !dueDateOnly.isAfter(
        todayDate.add(const Duration(days: 1)),
      ),
      'week_before' => !dueDateOnly.isAfter(
        todayDate.add(const Duration(days: 7)),
      ),
      _ => false,
    };
    if (shouldCreateNow) {
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

  void _showChecklistEditor(SlateTask task, {TaskChecklistItem? item}) {
    final controller = TextEditingController(text: item?.title ?? '');
    var saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
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
                  item == null ? 'Add checklist item' : 'Edit checklist item',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: AppColors.t1),
                  decoration: const InputDecoration(
                    hintText: 'What needs checking off?',
                  ),
                ),
                const SizedBox(height: 18),
                SlateButton(
                  label: saving
                      ? 'Saving...'
                      : item == null
                      ? 'Add Item'
                      : 'Save Item',
                  icon: item == null ? LucideIcons.plus : LucideIcons.check,
                  onPressed: saving
                      ? null
                      : () async {
                          final title = controller.text.trim();
                          if (title.isEmpty) return;
                          setModal(() => saving = true);
                          if (item == null) {
                            final existing = await ref.read(
                              taskChecklistProvider(task.id).future,
                            );
                            await ref
                                .read(tasksRepositoryProvider)
                                .addChecklistItem(
                                  workspaceId: task.workspaceId,
                                  taskId: task.id,
                                  title: title,
                                  position: existing.length,
                                );
                          } else {
                            await ref
                                .read(tasksRepositoryProvider)
                                .updateChecklistItem(
                                  itemId: item.id,
                                  title: title,
                                );
                          }
                          ref.invalidate(taskChecklistProvider(task.id));
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => _disposeControllerAfterSheetClose(controller));
  }

  void _disposeControllerAfterSheetClose(TextEditingController controller) {
    Future.delayed(AppMotion.deliberate + AppMotion.fast, controller.dispose);
  }

  Future<void> _toggleChecklistItem(
    SlateTask task,
    TaskChecklistItem item,
  ) async {
    await ref
        .read(tasksRepositoryProvider)
        .updateChecklistItemStatus(itemId: item.id, completed: !item.completed);
    ref.invalidate(taskChecklistProvider(task.id));
  }

  Future<void> _deleteChecklistItem(
    SlateTask task,
    TaskChecklistItem item,
  ) async {
    await ref.read(tasksRepositoryProvider).deleteChecklistItem(item.id);
    ref.invalidate(taskChecklistProvider(task.id));
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
  final _TaskCounts counts;
  final ValueChanged<_TaskView> onChanged;

  const _TaskViewSwitcher({
    required this.value,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _TaskView.values.map((view) {
          final active = value == view;
          final count = _viewCount(view, counts);
          return GestureDetector(
            onTap: () {
              SlateHaptics.tap();
              onChanged(view);
            },
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
                '${_viewLabel(view)} $count',
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
