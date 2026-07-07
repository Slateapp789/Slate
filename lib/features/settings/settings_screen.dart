import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slate_ui.dart';
import 'providers/settings_providers.dart';
import 'widgets/settings_business_tab.dart';
import 'widgets/settings_account_tab.dart';
import 'widgets/settings_app_tab.dart';
import '../notifications/notifications_screen.dart';

export 'providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(settingsServicesProvider);
    });
  }

  void _handleTabChanged() {
    if (_selectedTab == _tabController.index) return;
    setState(() => _selectedTab = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  WorkloopIconButton(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.t1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WorkloopSegmentedControl<int>(
                selected: _selectedTab,
                onChanged: (index) => _tabController.animateTo(index),
                segments: const [
                  WorkloopSegment(value: 0, label: 'Business'),
                  WorkloopSegment(value: 1, label: 'Alerts'),
                  WorkloopSegment(value: 2, label: 'Account'),
                  WorkloopSegment(value: 3, label: 'App'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  SettingsBusinessTab(),
                  NotificationSettingsView(),
                  SettingsAccountTab(),
                  SettingsAppTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
