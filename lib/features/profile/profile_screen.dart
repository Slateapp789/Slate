import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import '../public_profile/booking_requests_screen.dart';
import '../public_profile/public_profile_screen.dart';
import '../settings/providers/settings_providers.dart';
import '../settings/widgets/settings_business_tab.dart';
import 'profile_editor_screen.dart';

String profileWorkingHoursSummary(Map<String, dynamic> workingHours) {
  const dayOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final enabled = dayOrder.where((day) {
    final value = workingHours[day];
    if (value is! Map) return false;
    return Map<String, dynamic>.from(value)['enabled'] == true;
  }).toList();
  if (enabled.isEmpty) return 'Working hours not set';
  if (enabled.length == 7) return 'Open every day';
  return '${enabled.length} working ${enabled.length == 1 ? 'day' : 'days'}';
}

String profileServicesSummary(int count) {
  if (count == 0) return 'No services added';
  return '$count ${count == 1 ? 'service' : 'services'} available';
}

String profileRequestSummary(int count) {
  if (count == 0) return 'No requests waiting';
  return '$count ${count == 1 ? 'request' : 'requests'} waiting';
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final profile = ref.watch(settingsBusinessProfileProvider);
    final settings = ref.watch(settingsWorkspaceSettingsProvider);
    final services = ref.watch(settingsServicesProvider);
    final requests = ref.watch(bookingRequestsProvider);
    final auth = ref.watch(authRepositoryProvider);

    final workspaceData = workspace.value;
    final profileData = profile.value;
    final settingsData = settings.value;
    final servicesData = services.value ?? const <Map<String, dynamic>>[];
    final requestsData = requests.value ?? const [];
    final businessName = workspaceData?['name']?.toString().trim();
    final displayName = businessName?.isNotEmpty == true
        ? businessName!
        : 'Your business';
    final industry = workspaceData?['industry']?.toString().trim();
    final ownerName = auth.currentFirstName?.trim();
    final handle = profileData?.handle.trim() ?? '';
    final workingHours = settingsData?['working_hours'] is Map
        ? Map<String, dynamic>.from(settingsData!['working_hours'] as Map)
        : <String, dynamic>{};
    final pendingRequests = requestsData
        .where(
          (request) =>
              request.status == 'pending' || request.status == 'contacted',
        )
        .length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.accentPrimary,
              onRefresh: () => _refresh(ref),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.lg,
                  AppSpacing.pageX,
                  AppSpacing.xxl,
                ),
                children: [
                  _ProfileHeader(
                    onEdit: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.business,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ProfileIdentity(
                    businessName: displayName,
                    industry: industry?.isNotEmpty == true
                        ? industry!
                        : 'Add your industry',
                    ownerName: ownerName,
                    onBusinessTap: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.business,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ProfileSnapshot(
                    services: servicesData.length,
                    workingDays: workingHours.values.where((value) {
                      if (value is! Map) return false;
                      return Map<String, dynamic>.from(value)['enabled'] ==
                          true;
                    }).length,
                    requests: pendingRequests,
                    onServices: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.services,
                    ),
                    onHours: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.workingHours,
                    ),
                    onRequests: () => context.push('/booking-requests'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const WorkloopSectionHeader(label: 'Business'),
                  const SizedBox(height: AppSpacing.xs),
                  _ProfileRow(
                    icon: LucideIcons.briefcase,
                    title: 'Business details',
                    subtitle: industry?.isNotEmpty == true
                        ? '$displayName · $industry'
                        : 'Name, industry, and public description',
                    onTap: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.business,
                    ),
                  ),
                  _ProfileRow(
                    icon: LucideIcons.slidersHorizontal,
                    title: 'Services',
                    subtitle: profileServicesSummary(servicesData.length),
                    onTap: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.services,
                    ),
                  ),
                  _ProfileRow(
                    icon: LucideIcons.clock3,
                    title: 'Working hours',
                    subtitle: profileWorkingHoursSummary(workingHours),
                    onTap: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.workingHours,
                    ),
                    showDivider: false,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const WorkloopSectionHeader(label: 'Online'),
                  const SizedBox(height: AppSpacing.xs),
                  _ProfileRow(
                    icon: LucideIcons.globe,
                    title: 'Public profile',
                    subtitle: handle.isEmpty
                        ? 'Set up your public booking page'
                        : 'workloop.app/$handle',
                    trailingLabel: handle.isEmpty ? 'Set up' : 'Edit',
                    onTap: () => _openProfileEditor(
                      context,
                      ref,
                      SettingsBusinessSection.publicProfile,
                    ),
                  ),
                  if (handle.isNotEmpty)
                    _ProfileRow(
                      icon: LucideIcons.globe,
                      title: 'Preview public profile',
                      subtitle: 'See the page your clients will open',
                      onTap: () => _openPublicPreview(
                        context,
                        handle: handle,
                        businessName: displayName,
                        industry: industry,
                        profile: profileData!,
                        workingHours: workingHours,
                        services: servicesData,
                      ),
                    ),
                  if (handle.isNotEmpty)
                    _ProfileRow(
                      icon: LucideIcons.copy,
                      title: 'Copy profile link',
                      subtitle: 'Share your booking page with clients',
                      onTap: () => _copyProfileLink(context, handle),
                    ),
                  _ProfileRow(
                    icon: LucideIcons.inbox,
                    title: 'Booking requests',
                    subtitle: profileRequestSummary(pendingRequests),
                    trailingLabel: pendingRequests == 0
                        ? null
                        : pendingRequests.toString(),
                    onTap: () => context.push('/booking-requests'),
                    showDivider: false,
                  ),
                  if (workspace.isLoading ||
                      profile.isLoading ||
                      settings.isLoading ||
                      services.isLoading ||
                      requests.isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(workspaceProvider);
    ref.invalidate(settingsBusinessProfileProvider);
    ref.invalidate(settingsWorkspaceSettingsProvider);
    ref.invalidate(settingsServicesProvider);
    ref.invalidate(bookingRequestsProvider);
    await Future.wait([
      ref.read(workspaceProvider.future),
      ref.read(settingsBusinessProfileProvider.future),
      ref.read(settingsWorkspaceSettingsProvider.future),
      ref.read(settingsServicesProvider.future),
      ref.read(bookingRequestsProvider.future),
    ]);
  }

  Future<void> _openProfileEditor(
    BuildContext context,
    WidgetRef ref,
    SettingsBusinessSection section,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditorScreen(section: section)),
    );
    if (!context.mounted) return;
    ref.invalidate(workspaceProvider);
    ref.invalidate(settingsBusinessProfileProvider);
    ref.invalidate(settingsWorkspaceSettingsProvider);
    ref.invalidate(settingsServicesProvider);
  }

  Future<void> _copyProfileLink(BuildContext context, String handle) async {
    await Clipboard.setData(
      ClipboardData(text: 'https://workloop.app/$handle'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile link copied')));
  }

  Future<void> _openPublicPreview(
    BuildContext context, {
    required String handle,
    required String businessName,
    required String? industry,
    required BusinessProfile profile,
    required Map<String, dynamic> workingHours,
    required List<Map<String, dynamic>> services,
  }) {
    final publicServices = services
        .where(
          (service) =>
              service['active'] != false && service['show_on_profile'] != false,
        )
        .map(Service.fromMap)
        .toList();
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          handle: handle,
          previewProfile: PublicProfile(
            profile: profile,
            businessName: businessName,
            industry: industry,
            workingHours: workingHours,
            services: publicServices,
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onEdit;

  const _ProfileHeader({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        WorkloopIconButton(
          icon: LucideIcons.chevronLeft,
          semanticLabel: 'Back to more',
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        WorkloopTextButton(label: 'Edit', onPressed: onEdit),
      ],
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  final String businessName;
  final String industry;
  final String? ownerName;
  final VoidCallback onBusinessTap;

  const _ProfileIdentity({
    required this.businessName,
    required this.industry,
    required this.ownerName,
    required this.onBusinessTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = businessName.trim().isEmpty
        ? 'W'
        : businessName.trim()[0].toUpperCase();
    return Column(
      children: [
        InkWell(
          onTap: onBusinessTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.accentPrimaryStrong,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.t1,
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        industry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.t3,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ownerName?.isNotEmpty == true
                            ? ownerName!
                            : 'Add your name in Business details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.t3,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color: AppColors.t3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSnapshot extends StatelessWidget {
  final int services;
  final int workingDays;
  final int requests;
  final VoidCallback onServices;
  final VoidCallback onHours;
  final VoidCallback onRequests;

  const _ProfileSnapshot({
    required this.services,
    required this.workingDays,
    required this.requests,
    required this.onServices,
    required this.onHours,
    required this.onRequests,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopSurface(
      color: AppColors.panelSoft.withValues(alpha: 0.82),
      borderColor: AppColors.border.withValues(alpha: 0.82),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SnapshotItem(
              value: services.toString(),
              label: 'Services',
              onTap: onServices,
            ),
          ),
          const _SnapshotDivider(),
          Expanded(
            child: _SnapshotItem(
              value: workingDays.toString(),
              label: 'Work days',
              onTap: onHours,
            ),
          ),
          const _SnapshotDivider(),
          Expanded(
            child: _SnapshotItem(
              value: requests.toString(),
              label: 'Requests',
              onTap: onRequests,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotDivider extends StatelessWidget {
  const _SnapshotDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.border);
  }
}

class _SnapshotItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;

  const _SnapshotItem({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.t1,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.t3,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingLabel;
  final bool showDivider;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingLabel,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopListRow(
      onTap: onTap,
      showDivider: showDivider,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.modBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.t2),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 13,
          height: 1.3,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingLabel != null) ...[
            Text(
              trailingLabel!,
              style: const TextStyle(
                color: AppColors.accentPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.t3),
        ],
      ),
    );
  }
}
