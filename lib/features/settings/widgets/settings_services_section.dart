import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/slate_ui.dart';
import 'settings_helpers.dart';

class SettingsServicesSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> services;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const SettingsServicesSection({
    super.key,
    required this.services,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            sectionLabel('Services'),
            GestureDetector(
              onTap: () {
                SlateHaptics.tap();
                onAdd();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimaryStrong.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 13,
                      color: AppColors.accentPrimary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        services.when(
          loading: () => skeletonBox(60),
          error: (e, _) => errorBox('Services could not be loaded.'),
          data: (data) => data.isEmpty
              ? _EmptyServices(onAdd: onAdd)
              : _ServicesList(services: data, onEdit: onEdit),
        ),
      ],
    );
  }
}

class _EmptyServices extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyServices({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(LucideIcons.scissors, color: AppColors.t3, size: 24),
          const SizedBox(height: 8),
          const Text(
            'No services yet',
            style: TextStyle(fontSize: 14, color: AppColors.t3),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAdd,
            child: const Text(
              '+ Add your first service',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _ServicesList({required this.services, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: services.asMap().entries.map((entry) {
        final index = entry.key;
        final service = entry.value;
        final isLast = index == services.length - 1;
        final price = service['price'] is num
            ? (service['price'] as num).toStringAsFixed(0)
            : '0';

        return SlateListRow(
          onTap: () => onEdit(service),
          showDivider: !isLast,
          leading: const Icon(
            LucideIcons.scissors,
            size: 17,
            color: AppColors.t3,
          ),
          title: Text(
            service['name'] as String? ?? 'Service',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.t1,
            ),
          ),
          subtitle: Text(
            '${service['duration_mins'] ?? 60} min',
            style: const TextStyle(fontSize: 12, color: AppColors.t3),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '£$price',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(LucideIcons.pencil, size: 14, color: AppColors.t3),
            ],
          ),
        );
      }).toList(),
    );
  }
}
