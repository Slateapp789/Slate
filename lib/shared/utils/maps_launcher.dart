import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../providers/maps_preference_provider.dart';
import '../widgets/slate_ui.dart';

class MapLaunchChoice {
  final MapsAppPreference app;
  final bool remember;

  const MapLaunchChoice({required this.app, required this.remember});
}

Uri mapsDirectionsUri(MapsAppPreference app, String address) {
  final destination = address.trim();
  return switch (app) {
    MapsAppPreference.appleMaps => Uri.https('maps.apple.com', '/', {
      'daddr': destination,
      'dirflg': 'd',
    }),
    MapsAppPreference.googleMaps => Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    }),
    MapsAppPreference.askEveryTime => throw ArgumentError(
      'Choose a maps app before creating a directions URL.',
    ),
  };
}

Future<bool> launchMapDirections(MapsAppPreference app, String address) async {
  if (address.trim().isEmpty || app == MapsAppPreference.askEveryTime) {
    return false;
  }
  return launchUrl(
    mapsDirectionsUri(app, address),
    mode: LaunchMode.externalApplication,
  );
}

Future<MapLaunchChoice?> showMapLaunchSheet(
  BuildContext context,
  String address,
) {
  var remember = false;
  return showModalBottomSheet<MapLaunchChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open directions',
              style: TextStyle(
                color: AppColors.t1,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.t3,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MapOptionRow(
              icon: LucideIcons.map,
              label: 'Apple Maps',
              onTap: () => Navigator.pop(
                sheetContext,
                MapLaunchChoice(
                  app: MapsAppPreference.appleMaps,
                  remember: remember,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _MapOptionRow(
              icon: LucideIcons.navigation,
              label: 'Google Maps',
              onTap: () => Navigator.pop(
                sheetContext,
                MapLaunchChoice(
                  app: MapsAppPreference.googleMaps,
                  remember: remember,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => setModalState(() => remember = !remember),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      remember ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: remember ? AppColors.accentPrimary : AppColors.t3,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'Use my choice as the default',
                      style: TextStyle(
                        color: AppColors.t2,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<MapsAppPreference?> showMapsPreferenceSheet(
  BuildContext context, {
  required MapsAppPreference selected,
}) {
  return showModalBottomSheet<MapsAppPreference>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (sheetContext) => SlateSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Default maps app',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Used when opening directions from a saved address.',
            style: TextStyle(color: AppColors.t3, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final preference in MapsAppPreference.values) ...[
            _MapOptionRow(
              icon: switch (preference) {
                MapsAppPreference.askEveryTime => LucideIcons.mousePointerClick,
                MapsAppPreference.appleMaps => LucideIcons.map,
                MapsAppPreference.googleMaps => LucideIcons.navigation,
              },
              label: preference.label,
              selected: preference == selected,
              onTap: () => Navigator.pop(sheetContext, preference),
            ),
            if (preference != MapsAppPreference.values.last)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    ),
  );
}

class _MapOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MapOptionRow({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgInteract,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.t2, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.t1,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                LucideIcons.check,
                color: AppColors.accentPrimary,
                size: 18,
              )
            else
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
