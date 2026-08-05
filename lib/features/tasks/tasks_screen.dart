import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/notifications/local_reminder_plan.dart';
import '../../shared/notifications/local_reminder_service.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/workflow_idempotency.dart';
import '../../shared/widgets/slate_ui.dart';
import 'task_filters.dart';
import '../imports/text_import_screen.dart';

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
  void initState() {
    super.initState();
    if (widget.createRequest != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showTaskEditor(context);
      });
    }
  }

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
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    AppSpacing.screenTop,
                    AppSpacing.pageX,
                    0,
                  ),
                  child: WorkloopPageHeader(
                    title: 'Tasks',
                    subtitle: 'Know what needs doing next.',
                    color: AppColors.modTasks,
                    trailing: WorkloopTopAction(
                      label: 'New task',
                      semanticLabel: 'New task',
                      onTap: () => _showTaskEditor(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: tasks.when(
                    loading: () => _skeletonList(),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageX,
                      ),
                      child: SlateErrorState(
                        message: 'Could not load tasks',
                        onRetry: () => ref.invalidate(allTasksProvider),
                      ),
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
                            AppSpacing.bottomNavClearance,
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
                              _emptyState(context)
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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) =>
          const SlateLoadingBlock(height: 80, radius: AppRadius.md),
    );
  }

  Widget _emptyState(BuildContext context) {
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
      child: Column(
        children: [
          WorkloopEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: title,
            subtitle: subtitle,
          ),
          if (_view != _TaskView.done) ...[
            const SizedBox(height: AppSpacing.xs),
            WorkloopTextButton(
              label: 'Import a task list',
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TextImportScreen(type: TextImportType.tasks),
                  ),
                );
                ref.invalidate(allTasksProvider);
              },
            ),
          ],
        ],
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
                          child: WorkloopRouteHeader(
                            title: 'Task',
                            backSemanticLabel: 'Back to tasks',
                            trailing: WorkloopIconButton(
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
                                    fontWeight: FontWeight.w600,
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
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.t3,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _TaskContextPanel(task: task),
                                const SizedBox(height: AppSpacing.xl),
                                _TaskChecklistPanel(
                                  items: checklist,
                                  onAdd: () => _showChecklistEditor(task),
                                  onRetry: () => ref.invalidate(
                                    taskChecklistProvider(task.id),
                                  ),
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
                                  onPressed: () async {
                                    final changed = task.status == 'done'
                                        ? await _reopenTask(task)
                                        : await _confirmComplete(task);
                                    if (changed && ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SlateButton(
                                  label: 'Delete Task',
                                  destructive: true,
                                  onPressed: () async {
                                    final deleted = await _confirmDelete(task);
                                    if (deleted && ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
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
    final createIdempotencyKey = task == null
        ? createWorkflowIdempotencyKey()
        : null;
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

    bool canScheduleReminder(String timing) {
      if (timing == 'none') return true;
      return planTaskReminder(
            SlateTask(
              id: task?.id ?? 'draft',
              workspaceId: task?.workspaceId ?? '',
              title: titleController.text.trim(),
              dueDate: dueDate,
              reminderTiming: timing,
            ),
            now: DateTime.now(),
          ) !=
          null;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) {
            final clients = ref.watch(clientsProvider);
            Future<void> save() async {
              if (saving || titleController.text.trim().isEmpty) return;
              final reminderChanged =
                  task == null ||
                  reminderTiming != task.reminderTiming ||
                  dueDate != task.dueDate;
              if (reminderTiming != 'none' && reminderChanged) {
                if (!canScheduleReminder(reminderTiming)) {
                  setModal(() => showOptions = true);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'That 09:00 reminder time has passed. Choose a later due date or No reminder.',
                      ),
                    ),
                  );
                  return;
                }
                final permission = await ref
                    .read(localReminderServiceProvider)
                    .requestPermission();
                if (!ctx.mounted) return;
                if (permission != LocalReminderPermission.granted) {
                  setModal(() => showOptions = true);
                  final message =
                      permission == LocalReminderPermission.unsupported
                      ? 'Choose No reminder to save this task outside the iOS or Android app.'
                      : 'Allow notifications, or choose No reminder before saving this task.';
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text(message)));
                  return;
                }
              }
              setModal(() => saving = true);
              try {
                final saved = await _saveTask(
                  task: task,
                  title: titleController.text,
                  priority: priority,
                  dueDate: dueDate,
                  clientId: selectedClientId,
                  reminderTiming: reminderTiming,
                  checklistTitles: draftChecklist,
                  createIdempotencyKey: createIdempotencyKey,
                );
                if (!ctx.mounted) return;
                if (!saved) {
                  setModal(() => saving = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not access this workspace. Your task was not saved.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
              } catch (_) {
                if (!ctx.mounted) return;
                setModal(() => saving = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      task == null
                          ? 'Could not create this task. Nothing was added. Please try again.'
                          : 'Could not save these task changes. Please try again.',
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
                            child: WorkloopRouteHeader(
                              title: task == null ? 'New task' : 'Edit task',
                              backSemanticLabel: 'Back to tasks',
                              onBack: handleBack,
                              trailing: _TaskSaveAction(
                                label: task == null ? 'Add' : 'Save',
                                loading: saving,
                                enabled: titleController.text.trim().isNotEmpty,
                                onTap: save,
                              ),
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
                                            showOptions = true;
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
                                    loading: () => const SlateLoadingBlock(
                                      height: 58,
                                      radius: AppRadius.md,
                                    ),
                                    error: (_, _) => SlateErrorState(
                                      message: 'Could not load clients.',
                                      onRetry: () =>
                                          ref.invalidate(clientsProvider),
                                    ),
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
                                        fontWeight: FontWeight.w600,
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
                                      onChanged: (value) async {
                                        if (value != 'none') {
                                          if (!canScheduleReminder(value)) {
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'That 09:00 reminder time has passed. Choose a later due date.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          final permission = await ref
                                              .read(
                                                localReminderServiceProvider,
                                              )
                                              .requestPermission();
                                          if (!ctx.mounted) return;
                                          if (permission !=
                                              LocalReminderPermission.granted) {
                                            final message =
                                                permission ==
                                                    LocalReminderPermission
                                                        .unsupported
                                                ? 'Scheduled reminders are available in the iOS and Android apps.'
                                                : 'Enable notifications in your device settings to use task reminders.';
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              SnackBar(content: Text(message)),
                                            );
                                            return;
                                          }
                                        }
                                        setModal(() => reminderTiming = value);
                                      },
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
    required String? createIdempotencyKey,
  }) async {
    if (title.trim().isEmpty) return false;
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    final savedReminderTiming = dueDate == null ? 'none' : reminderTiming;
    final reminderChanged =
        task == null ||
        task.reminderTiming != savedReminderTiming ||
        task.dueDate != dueDate;
    if (task == null) {
      await ref
          .read(tasksRepositoryProvider)
          .createWithChecklist(
            workspaceId: workspaceId,
            title: title,
            priority: priority,
            dueDate: dueDate,
            contactId: clientId,
            reminderTiming: savedReminderTiming,
            checklistTitles: checklistTitles,
            idempotencyKey: createIdempotencyKey!,
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
            reminderTiming: savedReminderTiming,
          );
    }
    if (reminderChanged) {
      await _maybeCreateDueNotification(
        workspaceId,
        title,
        dueDate,
        savedReminderTiming,
      );
    }
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
      try {
        await ref
            .read(notificationsRepositoryProvider)
            .create(
              workspaceId: workspaceId,
              type: 'task_due',
              title: 'Task due soon',
              body: title.trim(),
              deepLink: '/tasks',
            );
      } catch (_) {
        // The saved task is the source of truth. Notification support is
        // additive and must never turn a committed task into a failed save.
      }
    }
  }

  void _showChecklistEditor(SlateTask task, {TaskChecklistItem? item}) {
    final controller = TextEditingController(text: item?.title ?? '');
    var saving = false;
    String? errorMessage;

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
                    fontWeight: FontWeight.w600,
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
                if (errorMessage != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
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
                          setModal(() {
                            saving = true;
                            errorMessage = null;
                          });
                          try {
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
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setModal(() {
                              saving = false;
                              errorMessage = item == null
                                  ? 'Could not add this checklist item. Please try again.'
                                  : 'Could not save this checklist item. Please try again.';
                            });
                          }
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
    try {
      await ref
          .read(tasksRepositoryProvider)
          .updateChecklistItemStatus(
            itemId: item.id,
            completed: !item.completed,
          );
      ref.invalidate(taskChecklistProvider(task.id));
    } catch (_) {
      _showTaskFailure(
        'Could not update this checklist item. Nothing was changed.',
      );
    }
  }

  Future<void> _deleteChecklistItem(
    SlateTask task,
    TaskChecklistItem item,
  ) async {
    try {
      await ref.read(tasksRepositoryProvider).deleteChecklistItem(item.id);
      ref.invalidate(taskChecklistProvider(task.id));
    } catch (_) {
      _showTaskFailure(
        'Could not delete this checklist item. Nothing was removed.',
      );
    }
  }

  Future<bool> _confirmComplete(SlateTask task) async {
    var saving = false;
    String? errorMessage;
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => PopScope(
          canPop: !saving,
          child: SlateSheetFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Complete this task?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.t3),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SlateButton(
                  label: saving ? 'Completing...' : 'Mark Complete',
                  icon: LucideIcons.checkCircle,
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() {
                            saving = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(tasksRepositoryProvider)
                                .updateStatus(task.id, 'done');
                            _refreshTasks();
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setSheetState(() {
                              saving = false;
                              errorMessage =
                                  'Could not complete this task. Nothing was changed. Please try again.';
                            });
                          }
                        },
                ),
                const SizedBox(height: 10),
                SlateButton(
                  label: 'Cancel',
                  secondary: true,
                  onPressed: saving ? null : () => Navigator.pop(ctx, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return completed ?? false;
  }

  Future<bool> _reopenTask(SlateTask task) async {
    try {
      await ref.read(tasksRepositoryProvider).updateStatus(task.id, 'open');
      _refreshTasks();
      return true;
    } catch (_) {
      _showTaskFailure('Could not reopen this task. Nothing was changed.');
      return false;
    }
  }

  Future<bool> _confirmDelete(SlateTask task) async {
    var deleting = false;
    String? errorMessage;
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => PopScope(
          canPop: !deleting,
          child: SlateSheetFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete task?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.t1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.title,
                  style: const TextStyle(fontSize: 14, color: AppColors.t3),
                  textAlign: TextAlign.center,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SlateButton(
                  label: deleting ? 'Deleting...' : 'Delete Task',
                  destructive: true,
                  onPressed: deleting
                      ? null
                      : () async {
                          setSheetState(() {
                            deleting = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(tasksRepositoryProvider)
                                .delete(task.id);
                            _refreshTasks();
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setSheetState(() {
                              deleting = false;
                              errorMessage =
                                  'Could not delete this task. Nothing was removed. Please try again.';
                            });
                          }
                        },
                ),
                const SizedBox(height: 10),
                SlateButton(
                  label: 'Cancel',
                  secondary: true,
                  onPressed: deleting ? null : () => Navigator.pop(ctx, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return deleted ?? false;
  }

  void _refreshTasks() {
    ref.invalidate(allTasksProvider);
    ref.invalidate(tasksProvider);
  }

  void _refreshTaskNotifications() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  void _showTaskFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      emphasized: false,
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
            quiet: true,
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
