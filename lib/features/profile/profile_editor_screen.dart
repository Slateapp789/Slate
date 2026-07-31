import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slate_ui.dart';
import '../settings/widgets/settings_business_tab.dart';
import 'working_hours_editor.dart';

class ProfileEditorScreen extends StatelessWidget {
  final SettingsBusinessSection section;

  const ProfileEditorScreen({super.key, required this.section});

  String get _title => switch (section) {
    SettingsBusinessSection.business => 'Business details',
    SettingsBusinessSection.workingHours => 'Working hours',
    SettingsBusinessSection.publicProfile => 'Public profile',
    SettingsBusinessSection.services => 'Services',
  };

  @override
  Widget build(BuildContext context) {
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
                    AppSpacing.xl,
                  ),
                  child: WorkloopRouteHeader(
                    title: _title,
                    backSemanticLabel: 'Back to profile',
                  ),
                ),
                Expanded(
                  child: section == SettingsBusinessSection.workingHours
                      ? const WorkingHoursEditor()
                      : SettingsBusinessTab(
                          initialSection: section,
                          showOnlySelected: true,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
