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
  final int createRequest;

  const TasksScreen({super.key, this.createRequest = 0});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _TaskView _view = _TaskView.now;

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.createRequest == oldWidget.createRequest ||
        widget.createRequest == 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTaskEditor(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(allTasksProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
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
                  child: WorkloopPageHeader(
                    icon: LucideIcons.listChecks,
                    title: 'Tasks',
                    subtitle: 'Keep follow-ups and admin from slipping.',
                    color: AppColors.modTasks,
                    trailing: WorkloopIconButton(
                      icon: LucideIcons.plus,
                      semanticLabel: 'New task',
                      color: AppColors.modTasks,
                      backgroundColor: AppColors.modTasks.withValues(
                        alpha: 0.10,
                      ),
                      onTap: () => _showTaskEditor(context),
                    ),
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
                        color: AppColors.accentPrimary,
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
                            if (sections.every(
                              (section) => section.tasks.isEmpty,
                            ))
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
        ],
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
      _TaskView.now => 'Nothing to do',
      _TaskView.later => 'Nothing planned yet',
      _TaskView.done => 'No completed tasks',
    };
    final subtitle = switch (_view) {
      _TaskView.now => 'Your current list is clear.',
      _TaskView.later => 'Future tasks will appear here.',
      _TaskView.done => 'Completed tasks will appear here.',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 42),
      child: WorkloopEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  Future<void> _showTaskDetails(SlateTask task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => Consumer(
          builder: (context, ref, _) {
            final checklist = ref.watch(taskChecklistProvider(task.id));

            return Scaffold(
              backgroundColor: AppColors.bg,
              body: Stack(
                children: [
                  const Positioned.fill(child: WorkloopTexturedBackdrop()),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageX,
                            AppSpacing.lg,
                            AppSpacing.pageX,
                            0,
                          ),
                          child: Row(
                            children: [
                              WorkloopIconButton(
                                icon: LucideIcons.chevronLeft,
                                semanticLabel: 'Back to tasks',
                                onTap: () => Navigator.pop(ctx),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Expanded(
                                child: Text(
                                  'Task',
                                  style: TextStyle(
                                    color: AppColors.t1,
                                    fontSize: 26,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              WorkloopIconButton(
                                icon: LucideIcons.pencil,
                                semanticLabel: 'Edit task',
                                color: AppColors.modTasks,
                                backgroundColor: AppColors.modTasks.withValues(
                                  alpha: 0.10,
                                ),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  await Future<void>.delayed(Duration.zero);
                                  if (mounted) {
                                    await _showTaskEditor(
                                      this.context,
                                      task: task,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pageX,
                              0,
                              AppSpacing.pageX,
                              AppSpacing.xxl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
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
                                const SizedBox(height: 8),
                                Text(
                                  '${task.status == 'done' ? 'Completed' : _priorityLabel(task.priority)} task',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.t3,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _TaskContextPanel(task: task),
                                const SizedBox(height: AppSpacing.xl),
                                _TaskChecklistPanel(
                                  items: checklist,
                                  onAdd: () => _showChecklistEditor(task),
                                  onToggle: (item) =>
                                      _toggleChecklistItem(task, item),
                                  onEdit: (item) =>
                                      _showChecklistEditor(task, item: item),
                                  onDelete: (item) =>
                                      _deleteChecklistItem(task, item),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
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
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted) _confirmComplete(task);
                                          });
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SlateButton(
                                  label: 'Delete Task',
                                  destructive: true,
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) _confirmDelete(task);
                                        });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    _refreshTasks();
  }

  Future<void> _showTaskEditor(BuildContext context, {SlateTask? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final checklistController = TextEditingController();
    String priority = task?.priority ?? 'medium';
    DateTime? dueDate = task?.dueDate;
    String? selectedClientId = task?.contactId;
    String reminderTiming = task?.reminderTiming ?? 'none';
    final draftChecklist = <String>[];
    var saving = false;
    var allowPop = false;
    var showOptions =
        task?.priority != null && task!.priority != 'medium' ||
        task?.reminderTiming != null && task!.reminderTiming != 'none';

    bool hasChanges() {
      return titleController.text != (task?.title ?? '') ||
          priority != (task?.priority ?? 'medium') ||
          dueDate != task?.dueDate ||
          selectedClientId != task?.contactId ||
          reminderTiming != (task?.reminderTiming ?? 'none') ||
          draftChecklist.isNotEmpty;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) {
            final clients = ref.watch(clientsProvider);
            Future<void> save() async {
              if (saving || titleController.text.trim().isEmpty) return;
              setModal(() => saving = true);
              final saved = await _saveTask(
                task: task,
                title: titleController.text,
                priority: priority,
                dueDate: dueDate,
                clientId: selectedClientId,
                reminderTiming: reminderTiming,
                checklistTitles: draftChecklist,
              );
              if (!ctx.mounted) return;
              if (!saved) {
                setModal(() => saving = false);
                return;
              }
              allowPop = true;
              setModal(() {});
              await Future<void>.delayed(Duration.zero);
              if (ctx.mounted) Navigator.pop(ctx);
            }

            Future<void> handleBack() async {
              if (!hasChanges()) {
                allowPop = true;
                setModal(() {});
                await Future<void>.delayed(Duration.zero);
                if (ctx.mounted) Navigator.pop(ctx);
                return;
              }
              final choice = await _confirmTaskEditorExit(ctx);
              if (!ctx.mounted || choice == null) return;
              if (choice == _TaskEditorExit.keepEditing) return;
              if (choice == _TaskEditorExit.save) {
                await save();
                return;
              }
              allowPop = true;
              setModal(() {});
              await Future<void>.delayed(Duration.zero);
              if (ctx.mounted) Navigator.pop(ctx);
            }

            return PopScope(
              canPop: allowPop || !hasChanges(),
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) handleBack();
              },
              child: Scaffold(
                backgroundColor: AppColors.bg,
                body: Stack(
                  children: [
                    const Positioned.fill(child: WorkloopTexturedBackdrop()),
                    SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pageX,
                              AppSpacing.lg,
                              AppSpacing.pageX,
                              0,
                            ),
                            child: Row(
                              children: [
                                WorkloopIconButton(
                                  icon: LucideIcons.chevronLeft,
                                  semanticLabel: 'Back to tasks',
                                  onTap: handleBack,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    task == null ? 'New task' : 'Edit task',
                                    style: const TextStyle(
                                      color: AppColors.t1,
                                      fontSize: 26,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _TaskSaveAction(
                                  label: task == null ? 'Add' : 'Save',
                                  loading: saving,
                                  enabled: titleController.text
                                      .trim()
                                      .isNotEmpty,
                                  onTap: save,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.pageX,
                                0,
                                AppSpacing.pageX,
                                AppSpacing.xxl,
                              ),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _TaskFormSectionLabel(
                                    'Task details',
                                    subtitle:
                                        'Keep the next action clear and specific.',
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextField(
                                    controller: titleController,
                                    autofocus: task == null,
                                    minLines: 1,
                                    maxLines: 3,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(color: AppColors.t1),
                                    decoration: const InputDecoration(
                                      labelText: 'Task title',
                                      hintText: 'What needs to happen?',
                                    ),
                                    onChanged: (_) => setModal(() {}),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  if (task == null) ...[
                                    _TaskTemplatePicker(
                                      onSelect: (template) {
                                        setModal(() {
                                          if (titleController.text
                                              .trim()
                                              .isEmpty) {
                                            titleController.text =
                                                template.title;
                                          }
                                          priority = template.priority;
                                          if (template.dueInDays != null) {
                                            dueDate = _dateOnly(
                                              DateTime.now().add(
                                                Duration(
                                                  days: template.dueInDays!,
                                                ),
                                              ),
                                            );
                                            reminderTiming =
                                                template.dueInDays == 0
                                                ? 'today'
                                                : 'day_before';
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                  const _TaskFormSectionLabel(
                                    'When and who',
                                    subtitle:
                                        'Add timing and client context when useful.',
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  clients.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                    data: (data) => _ClientPicker(
                                      clients: data,
                                      selectedClientId: selectedClientId,
                                      onChanged: (value) => setModal(
                                        () => selectedClientId = value,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _DueDatePicker(
                                    dueDate: dueDate,
                                    onChanged: (value) =>
                                        setModal(() => dueDate = value),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _TaskOptionsDisclosure(
                                    expanded: showOptions,
                                    onTap: () => setModal(
                                      () => showOptions = !showOptions,
                                    ),
                                  ),
                                  if (showOptions) ...[
                                    const SizedBox(height: AppSpacing.lg),
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
                                          onTap: (value) =>
                                              setModal(() => priority = value),
                                        ),
                                        const SizedBox(width: 8),
                                        _PriorityChoice(
                                          value: 'medium',
                                          label: 'Medium',
                                          selected: priority,
                                          color: AppColors.warning,
                                          onTap: (value) =>
                                              setModal(() => priority = value),
                                        ),
                                        const SizedBox(width: 8),
                                        _PriorityChoice(
                                          value: 'low',
                                          label: 'Low',
                                          selected: priority,
                                          color: AppColors.t3,
                                          onTap: (value) =>
                                              setModal(() => priority = value),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _ReminderPicker(
                                      value: reminderTiming,
                                      enabled: dueDate != null,
                                      onChanged: (value) => setModal(
                                        () => reminderTiming = value,
                                      ),
                                    ),
                                    if (task == null) ...[
                                      const SizedBox(height: AppSpacing.xl),
                                      _DraftChecklistEditor(
                                        controller: checklistController,
                                        items: draftChecklist,
                                        onAdd: () {
                                          final title = checklistController.text
                                              .trim();
                                          if (title.isEmpty) return;
                                          setModal(() {
                                            draftChecklist.add(title);
                                            checklistController.clear();
                                          });
                                        },
                                        onRemove: (index) => setModal(
                                          () => draftChecklist.removeAt(index),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    titleController.dispose();
    checklistController.dispose();
    if (mounted) {
      _refreshTasks();
      _refreshTaskNotifications();
    }
  }

  Future<_TaskEditorExit?> _confirmTaskEditorExit(BuildContext context) {
    return showDialog<_TaskEditorExit>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Save task changes?'),
        content: const Text('You have changes that have not been saved yet.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _TaskEditorExit.keepEditing),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _TaskEditorExit.discard),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _TaskEditorExit.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _saveTask({
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
    return WorkloopNavigationControl<_TaskView>(
      selected: value,
      color: AppColors.modTasks,
      onChanged: onChanged,
      segments: _TaskView.values
          .map(
            (view) => WorkloopSegment<_TaskView>(
              value: view,
              label: _viewLabel(view),
              badge: '${_viewCount(view, counts)}',
            ),
          )
          .toList(),
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
          WorkloopSectionHeader(
            label: '${section.title}  ${section.tasks.length}',
          ),
          const SizedBox(height: 6),
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
