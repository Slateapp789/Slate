import 'package:flutter/material.dart';

import '../models/slate_models.dart';
import '../utils/currency_format.dart';
import '../utils/duration_format.dart';
import 'slate_ui.dart';

/// Adds catalogue services to the existing primary service for one booking.
/// The first ID stays the primary relationship used by older app versions.
class AdditionalServicesPicker extends StatelessWidget {
  final List<Service> services;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const AdditionalServicesPicker({
    super.key,
    required this.services,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedIds.isEmpty) return const SizedBox.shrink();
    final remaining = services.where(
      (service) => !selectedIds.contains(service.id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedIds.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final id in selectedIds.skip(1))
                InputChip(
                  label: Text(
                    services
                            .where((service) => service.id == id)
                            .firstOrNull
                            ?.name ??
                        'Service',
                  ),
                  onDeleted: () => onChanged(
                    selectedIds.where((value) => value != id).toList(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (remaining.isNotEmpty && selectedIds.length < 8)
          WorkloopPickerField<String>(
            value: null,
            title: 'Add another service',
            hint: 'Add another service',
            searchHint: 'Search services',
            options: [
              for (final service in remaining)
                WorkloopPickerOption(
                  value: service.id,
                  label: service.name,
                  subtitle:
                      '${formatFriendlyDuration(service.durationMins)} · ${formatPounds(service.price)}',
                ),
            ],
            onChanged: (id) {
              onChanged([...selectedIds, id]);
            },
          ),
      ],
    );
  }
}
