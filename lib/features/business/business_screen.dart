import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/utils/public_booking_url.dart';
import '../../shared/widgets/slate_ui.dart';
import '../profile/booking_page_screen.dart';
import '../profile/profile_editor_screen.dart';
import '../profile/profile_screen.dart';
import '../public_profile/booking_requests_screen.dart';
import '../settings/providers/settings_providers.dart';
import '../settings/settings_screen.dart';
import '../settings/widgets/settings_business_tab.dart';

class BusinessScreen extends ConsumerWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = SlateTheme.of(context);
    final workspace = ref.watch(workspaceProvider);
    final profile = ref.watch(settingsBusinessProfileProvider);
    final settings = ref.watch(settingsWorkspaceSettingsProvider);
    final services = ref.watch(settingsServicesProvider);
    final requests = ref.watch(bookingRequestsProvider);

    final businessName = workspace.value?['name']?.toString().trim() ?? '';
    final handle = profile.value?.handle.trim() ?? '';
    final acceptingRequests = profile.value?.bookingMode == 'manual';
    final publicServices =
        services.value
            ?.where(
              (service) =>
                  service['active'] != false &&
                  service['show_on_profile'] != false,
            )
            .length ??
        0;
    final workingHours = settings.value?['working_hours'] is Map
        ? Map<String, dynamic>.from(settings.value!['working_hours'] as Map)
        : <String, dynamic>{};
    final hasWorkingHours = workingHours.values.any((value) {
      if (value is! Map) return false;
      return Map<String, dynamic>.from(value)['enabled'] == true;
    });
    final waitingRequests =
        requests.value
            ?.where(
              (request) =>
                  request.status == 'pending' || request.status == 'contacted',
            )
            .length ??
        0;
    final coreLoading =
        workspace.isLoading ||
        profile.isLoading ||
        settings.isLoading ||
        services.isLoading;
    final hasFailure =
        workspace.hasError ||
        profile.hasError ||
        settings.hasError ||
        services.hasError ||
        requests.hasError;
    final status = _bookingPageStatus(
      handle: handle,
      businessName: businessName,
      serviceCount: publicServices,
      hasWorkingHours: hasWorkingHours,
      acceptingRequests: acceptingRequests,
    );

    return Scaffold(
      backgroundColor: tokens.background,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: tokens.accent,
              onRefresh: () => _refresh(ref),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.screenTop,
                  AppSpacing.pageX,
                  AppSpacing.shellBottomClearance(context),
                ),
                children: [
                  WorkloopPageHeader(
                    title: 'Business',
                    subtitle: 'Shape how customers find and book you.',
                    color: tokens.accentInk,
                    trailing: WorkloopIconButton(
                      icon: LucideIcons.settings,
                      semanticLabel: 'Settings',
                      color: tokens.textSecondary,
                      backgroundColor: tokens.surfaceRaised,
                      borderColor: tokens.divider,
                      size: AppSpacing.minTouch,
                      onTap: () => _open(context, const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (coreLoading)
                    const SlateLoadingBlock(height: 232, radius: AppRadius.xl)
                  else
                    _BookingPageFeature(
                      status: status,
                      handle: handle,
                      waitingRequests: waitingRequests,
                      onOpen: () => _open(context, const BookingPageScreen()),
                      onOpenRequests: () =>
                          _open(context, const BookingRequestsScreen()),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                  const WorkloopSectionHeader(label: 'Run your business'),
                  const SizedBox(height: AppSpacing.xs),
                  WorkloopModuleRow(
                    key: const ValueKey('business-services'),
                    icon: LucideIcons.briefcaseBusiness,
                    title: 'Services',
                    subtitle: publicServices == 0
                        ? 'Add what customers can book'
                        : '$publicServices ${publicServices == 1 ? 'service' : 'services'} visible',
                    color: tokens.accent,
                    onTap: () =>
                        _openEditor(context, SettingsBusinessSection.services),
                  ),
                  WorkloopModuleRow(
                    key: const ValueKey('business-hours'),
                    icon: LucideIcons.clock3,
                    title: 'Working hours',
                    subtitle: hasWorkingHours
                        ? profileWorkingHoursSummary(workingHours)
                        : 'Set when you usually work',
                    color: tokens.accent,
                    onTap: () => _openEditor(
                      context,
                      SettingsBusinessSection.workingHours,
                    ),
                  ),
                  WorkloopModuleRow(
                    key: const ValueKey('business-profile'),
                    icon: LucideIcons.store,
                    title: 'Business profile',
                    subtitle: businessName.isEmpty
                        ? 'Add your business identity'
                        : businessName,
                    color: tokens.accent,
                    showDivider: false,
                    onTap: () => _open(context, const ProfileScreen()),
                  ),
                  if (hasFailure) ...[
                    const SizedBox(height: AppSpacing.xl),
                    SlateErrorState(
                      message:
                          'Some business details could not be refreshed. Your saved information is unchanged.',
                      onRetry: () => _refresh(ref).ignore(),
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

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openEditor(BuildContext context, SettingsBusinessSection section) {
    _open(context, ProfileEditorScreen(section: section));
  }
}

enum _BookingPageStatus { live, needsAttention, paused }

_BookingPageStatus _bookingPageStatus({
  required String handle,
  required String businessName,
  required int serviceCount,
  required bool hasWorkingHours,
  required bool acceptingRequests,
}) {
  if (handle.isEmpty ||
      businessName.isEmpty ||
      serviceCount == 0 ||
      !hasWorkingHours) {
    return _BookingPageStatus.needsAttention;
  }
  if (!acceptingRequests) return _BookingPageStatus.paused;
  return _BookingPageStatus.live;
}

class _BookingPageFeature extends StatelessWidget {
  final _BookingPageStatus status;
  final String handle;
  final int waitingRequests;
  final VoidCallback onOpen;
  final VoidCallback onOpenRequests;

  const _BookingPageFeature({
    required this.status,
    required this.handle,
    required this.waitingRequests,
    required this.onOpen,
    required this.onOpenRequests,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final statusColor = switch (status) {
      _BookingPageStatus.live => tokens.success,
      _BookingPageStatus.needsAttention => tokens.warning,
      _BookingPageStatus.paused => tokens.textTertiary,
    };
    final statusLabel = switch (status) {
      _BookingPageStatus.live => 'Live',
      _BookingPageStatus.needsAttention => 'Needs attention',
      _BookingPageStatus.paused => 'Requests paused',
    };
    final supportingText = switch (status) {
      _BookingPageStatus.live =>
        'Customers can view your services and request a time that works.',
      _BookingPageStatus.needsAttention =>
        'Finish the essentials so customers can book with confidence.',
      _BookingPageStatus.paused =>
        'Your page is available, but new booking requests are turned off.',
    };

    return WorkloopSurface(
      elevated: true,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  LucideIcons.calendarCheck2,
                  color: tokens.accentInk,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.capsule),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            statusLabel,
                            maxLines: 2,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your booking page',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            handle.isEmpty
                ? 'Choose your public booking address'
                : publicBookingPageDisplayUrl(handle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: handle.isEmpty ? tokens.textTertiary : tokens.accentInk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            supportingText,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (waitingRequests > 0) ...[
            const SizedBox(height: AppSpacing.md),
            WorkloopListRow(
              flat: true,
              showDivider: false,
              onTap: onOpenRequests,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              leading: Icon(
                LucideIcons.inbox,
                color: tokens.accentInk,
                size: 18,
              ),
              title: Text(
                '$waitingRequests ${waitingRequests == 1 ? 'request' : 'requests'} waiting',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                LucideIcons.chevronRight,
                color: tokens.textTertiary,
                size: 17,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: WorkloopPrimaryButton(
              label: 'Manage booking page',
              icon: LucideIcons.arrowUpRight,
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}
