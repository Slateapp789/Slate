import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                  child: Row(
                    children: [
                      WorkloopIconButton(
                        icon: LucideIcons.chevronLeft,
                        semanticLabel: 'Back to profile',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            color: AppColors.t1,
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
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
