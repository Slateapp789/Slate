import 'package:flutter/material.dart';

import '../../shared/widgets/slate_ui.dart';

enum WorkWorkspaceSection { schedule, tasks, notes }

class WorkWorkspaceSwitcher extends StatelessWidget {
  final WorkWorkspaceSection selected;
  final ValueChanged<WorkWorkspaceSection> onChanged;

  const WorkWorkspaceSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopSegmentedControl<WorkWorkspaceSection>(
      selected: selected,
      onChanged: onChanged,
      quiet: true,
      segments: const [
        WorkloopSegment(
          value: WorkWorkspaceSection.schedule,
          label: 'Schedule',
        ),
        WorkloopSegment(value: WorkWorkspaceSection.tasks, label: 'Tasks'),
        WorkloopSegment(value: WorkWorkspaceSection.notes, label: 'Notes'),
      ],
    );
  }
}
