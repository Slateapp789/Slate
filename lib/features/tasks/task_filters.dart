import '../../shared/models/slate_models.dart';

enum TaskDateBucket { overdue, today, upcoming, noDate, done }

TaskDateBucket taskDateBucketFor(SlateTask task, {DateTime? now}) {
  if (task.status.toLowerCase() == 'done') return TaskDateBucket.done;
  final due = task.dueDate;
  if (due == null) return TaskDateBucket.noDate;

  final today = _localDateOnly(now ?? DateTime.now());
  final dueDay = _localDateOnly(due);
  if (dueDay.isBefore(today)) return TaskDateBucket.overdue;
  if (dueDay == today) return TaskDateBucket.today;
  return TaskDateBucket.upcoming;
}

bool taskIsWithinNextSevenDays(SlateTask task, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (taskDateBucketFor(task, now: current) != TaskDateBucket.upcoming) {
    return false;
  }
  final today = _localDateOnly(current);
  final lastDay = DateTime(today.year, today.month, today.day + 7);
  return !_localDateOnly(task.dueDate!).isAfter(lastDay);
}

int compareTasksForDisplay(SlateTask first, SlateTask second) {
  final firstDone = first.status.toLowerCase() == 'done';
  final secondDone = second.status.toLowerCase() == 'done';
  if (firstDone != secondDone) return firstDone ? 1 : -1;

  final firstDate = first.dueDate;
  final secondDate = second.dueDate;
  if (firstDate != null && secondDate != null) {
    final dateComparison = _localDateOnly(
      firstDate,
    ).compareTo(_localDateOnly(secondDate));
    if (dateComparison != 0) return dateComparison;
  } else if (firstDate != null) {
    return -1;
  } else if (secondDate != null) {
    return 1;
  }

  final priorityComparison = taskPriorityRank(
    first.priority,
  ).compareTo(taskPriorityRank(second.priority));
  if (priorityComparison != 0) return priorityComparison;

  final titleComparison = first.title.toLowerCase().compareTo(
    second.title.toLowerCase(),
  );
  if (titleComparison != 0) return titleComparison;
  return first.id.compareTo(second.id);
}

int taskPriorityRank(String priority) {
  return switch (priority.toLowerCase()) {
    'high' => 0,
    'medium' => 1,
    _ => 2,
  };
}

DateTime _localDateOnly(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}
