import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

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

    final profileDataReady =
        workspace.hasValue &&
        profile.hasValue &&
        settings.hasValue &&
        services.hasValue &&
        requests.hasValue;
    final profileHasFailure =
        workspace.hasError ||
        profile.hasError ||
        settings.hasError ||
        services.hasError ||
        requests.hasError;
    if (!profileDataReady) {
      return _ProfileInitialState(
        failed: profileHasFailure,
        onRetry: () => _refresh(ref),
      );
    }

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
                  if (profileHasFailure) ...[
                    const SizedBox(height: AppSpacing.xl),
                    SlateErrorState(
                      message:
                          'Some profile details could not be refreshed. Existing details are still shown.',
                      onRetry: () => _refresh(ref).ignore(),
                    ),
                  ],
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

class _ProfileInitialState extends StatelessWidget {
  final bool failed;
  final Future<void> Function() onRetry;

  const _ProfileInitialState({required this.failed, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.accentPrimary,
              onRefresh: onRetry,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.lg,
                  AppSpacing.pageX,
                  AppSpacing.xxl,
                ),
                children: [
                  const _ProfileHeader(onEdit: null),
                  const SizedBox(height: AppSpacing.xl),
                  if (failed)
                    SlateErrorState(
                      message:
                          'Could not load your profile. Check your connection.',
                      onRetry: () => onRetry().ignore(),
                    )
                  else ...[
                    const SlateLoadingBlock(height: 92, radius: AppRadius.lg),
                    const SizedBox(height: AppSpacing.md),
                    const SlateLoadingBlock(height: 86, radius: AppRadius.lg),
                    const SizedBox(height: AppSpacing.xl),
                    const SlateLoadingBlock(height: 210, radius: AppRadius.lg),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback? onEdit;

  const _ProfileHeader({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return WorkloopRouteHeader(
      title: 'Profile',
      backSemanticLabel: 'Back to Home',
      trailing: WorkloopTextButton(label: 'Edit', onPressed: onEdit),
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
                      color: AppColors.onBrandAccent,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
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
                          fontWeight: FontWeight.w600,
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
                          fontWeight: FontWeight.w500,
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
                          fontWeight: FontWeight.w400,
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
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w400,
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
                fontWeight: FontWeight.w600,
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
