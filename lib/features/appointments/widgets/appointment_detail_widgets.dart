import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/utils/currency_format.dart';
import '../../../shared/utils/duration_format.dart';
import '../../../shared/widgets/slate_ui.dart';

// ── Hero card (client + service) ──────────────────────────────────────────────
class AppointmentHeroCard extends StatelessWidget {
  // Shared
  final bool editing;
  // View mode
  final String clientName;
  final String serviceName;
  final List<ServiceItemSnapshot> serviceItems;
  final num? price;
  final String initials;
  final String? contactId;
  final bool openingClient;
  final VoidCallback onOpenClient;
  // Edit mode
  final AsyncValue<List<Map<String, dynamic>>> clients;
  final AsyncValue<List<Map<String, dynamic>>> services;
  final String? selectedClientId;
  final String? selectedServiceId;
  final TextEditingController priceController;
  final TextEditingController serviceTitleController;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onServiceChanged;
  final VoidCallback onRetryClients;
  final VoidCallback? onRetryServices;

  const AppointmentHeroCard({
    super.key,
    required this.editing,
    required this.clientName,
    required this.serviceName,
    this.serviceItems = const [],
    this.price,
    required this.initials,
    this.contactId,
    this.openingClient = false,
    required this.onOpenClient,
    required this.clients,
    required this.services,
    this.selectedClientId,
    this.selectedServiceId,
    required this.priceController,
    required this.serviceTitleController,
    required this.onClientChanged,
    required this.onServiceChanged,
    required this.onRetryClients,
    this.onRetryServices,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: WorkloopSurface(
        radius: AppRadius.lg,
        color: AppColors.bgCard.withValues(alpha: 0.72),
        borderColor: AppColors.border,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: editing ? _buildEditMode() : _buildViewMode(context),
      ),
    );
  }

  Widget _buildViewMode(BuildContext context) {
    final serviceLabel = Text(
      serviceName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.t3,
        fontWeight: FontWeight.w500,
      ),
    );
    Widget clientAction({bool compact = false, bool iconOnly = false}) {
      if (iconOnly && !openingClient) {
        return const Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: AppColors.modClients,
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            openingClient
                ? 'Opening…'
                : compact
                ? 'Client'
                : 'View client',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.modClients,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          const Icon(
            LucideIcons.chevronRight,
            size: 12,
            color: AppColors.modClients,
          ),
        ],
      );
    }

    final clientDetails = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.t1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackAction =
                  contactId != null &&
                  (constraints.maxWidth < 160 ||
                      MediaQuery.textScalerOf(context).scale(11) > 14);
              if (stackAction) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    serviceLabel,
                    const SizedBox(height: AppSpacing.xxs),
                    clientAction(
                      compact: constraints.maxWidth < 145,
                      iconOnly:
                          constraints.maxWidth < 100 ||
                          MediaQuery.textScalerOf(context).scale(11) > 14,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: serviceLabel),
                  if (contactId != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    clientAction(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );

    final addOns = serviceItems.where((item) => item.isAddOn).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.modClients.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: contactId == null
                  ? clientDetails
                  : Semantics(
                      button: true,
                      enabled: !openingClient,
                      label: 'View client $clientName',
                      value: openingClient ? 'Opening' : serviceName,
                      onTap: openingClient ? null : onOpenClient,
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: openingClient ? null : onOpenClient,
                          child: clientDetails,
                        ),
                      ),
                    ),
            ),
            if (price != null)
              Text(
                formatPounds(price!),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.t1,
                ),
              ),
          ],
        ),
        if (addOns.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Text(
            addOns.map((item) => '+ ${item.name}').join('  ·  '),
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditMode() {
    final serviceValues = {
      ...(services.value ?? const <Map<String, dynamic>>[]).map(
        (service) => service['id'] as String,
      ),
      '__custom__',
    };
    final serviceValue = serviceValues.contains(selectedServiceId)
        ? selectedServiceId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Client'),
        const SizedBox(height: 8),
        clients.when(
          data: (data) => WorkloopPickerField<String>(
            value: selectedClientId,
            title: 'Choose a client',
            hint: 'Select client',
            searchHint: 'Search clients',
            searchable: true,
            leadingIcon: LucideIcons.users,
            options: data
                .map(
                  (c) => WorkloopPickerOption(
                    value: c['id'] as String,
                    label: c['name'] as String,
                    subtitle:
                        (c['address'] as String?)?.trim().isNotEmpty == true
                        ? (c['address'] as String).trim()
                        : null,
                  ),
                )
                .toList(),
            onChanged: onClientChanged,
          ),
          loading: () =>
              const SlateLoadingBlock(height: 58, radius: AppRadius.md),
          error: (_, _) => SlateErrorState(
            message: 'Could not load clients.',
            onRetry: onRetryClients,
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Service'),
        const SizedBox(height: 8),
        services.when(
          loading: () =>
              const SlateLoadingBlock(height: 58, radius: AppRadius.md),
          error: (_, _) => SlateErrorState(
            message:
                'Could not load services. Your current booking details are kept.',
            onRetry: onRetryServices,
          ),
          data: (items) => WorkloopPickerField<String>(
            value: serviceValue,
            title: 'Choose a service',
            hint: 'Select service',
            searchHint: 'Search services',
            options: [
              ...items.map(
                (s) => WorkloopPickerOption(
                  value: s['id'] as String,
                  label: s['name'] as String,
                  subtitle: s['duration_mins'] == null
                      ? null
                      : formatFriendlyDuration(
                          (s['duration_mins'] as num).toInt(),
                        ),
                ),
              ),
              const WorkloopPickerOption(
                value: '__custom__',
                label: 'Custom service',
                subtitle: 'Enter a one-off service',
              ),
            ],
            onChanged: onServiceChanged,
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Service name'),
        const SizedBox(height: 8),
        TextField(
          controller: serviceTitleController,
          style: const TextStyle(color: AppColors.t1),
          decoration: _inputDecoration('Service name'),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Price (£)'),
        const SizedBox(height: 8),
        TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.t1),
          decoration: _inputDecoration('0'),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.t2,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.t3),
    filled: true,
    fillColor: AppColors.bgInteract,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ── Date / time card ──────────────────────────────────────────────────────────
class AppointmentDateTimeCard extends StatelessWidget {
  final bool editing;
  final DateTime? startTime;
  final DateTime? endTime;
  // Edit mode
  final DateTime selectedDate;
  final int selectedHour;
  final int selectedMinute;
  final TextEditingController durationController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<int> onDurationSelected;
  final ValueChanged<String> onDurationChanged;

  const AppointmentDateTimeCard({
    super.key,
    required this.editing,
    this.startTime,
    this.endTime,
    required this.selectedDate,
    required this.selectedHour,
    required this.selectedMinute,
    required this.durationController,
    required this.onPickDate,
    required this.onPickTime,
    required this.onDurationSelected,
    required this.onDurationChanged,
  });

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: editing ? _buildEditMode(context) : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return Column(
      children: [
        _row(
          LucideIcons.calendar,
          'Date',
          startTime != null ? _formatDate(startTime!) : '—',
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        _row(
          LucideIcons.clock,
          'Time',
          startTime != null && endTime != null
              ? '${_formatTime(startTime!)} — ${_formatTime(endTime!)}'
              : '—',
        ),
        if (startTime != null && endTime != null) ...[
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          _row(
            LucideIcons.timer,
            'Duration',
            '${endTime!.difference(startTime!).inMinutes} min',
          ),
        ],
      ],
    );
  }

  Widget _buildEditMode(BuildContext context) {
    return Column(
      children: [
        _editAction(
          label: 'Booking date',
          value: _formatDate(selectedDate),
          onTap: onPickDate,
          child: _editRow(
            LucideIcons.calendar,
            'Date',
            _formatDate(selectedDate),
          ),
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        _editAction(
          label: 'Booking time',
          value:
              '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
          onTap: onPickTime,
          child: _editRow(
            LucideIcons.clock,
            'Time',
            '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
          ),
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        _durationEditor(context),
      ],
    );
  }

  Widget _durationEditor(BuildContext context) {
    final selectedDuration = int.tryParse(durationController.text.trim()) ?? 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(LucideIcons.timer, color: AppColors.t3, size: 16),
            SizedBox(width: 12),
            Text(
              'Duration',
              style: TextStyle(fontSize: 13, color: AppColors.t3),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [30, 45, 60, 90, 120].map((minutes) {
            final selected = selectedDuration == minutes;
            return WorkloopFilterChip(
              label: '${minutes}m',
              selected: selected,
              onTap: () => onDurationSelected(minutes),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: durationController,
          keyboardType: TextInputType.number,
          onChanged: onDurationChanged,
          style: const TextStyle(color: AppColors.t1),
          decoration: _inputDecoration('Custom duration').copyWith(
            suffixText: 'min',
            suffixStyle: const TextStyle(color: AppColors.t3),
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Builder(
      builder: (context) {
        final stacked = MediaQuery.textScalerOf(context).scale(13) > 18;
        final labelRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.t3, size: 16),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.t3),
              ),
            ),
          ],
        );
        final valueText = Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: stacked ? TextAlign.start : TextAlign.end,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.t1,
          ),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelRow,
              const SizedBox(height: AppSpacing.xs),
              valueText,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelRow),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: valueText),
          ],
        );
      },
    );
  }

  Widget _editRow(IconData icon, String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
      child: Row(
        children: [
          Icon(icon, color: AppColors.t3, size: 16),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.t3),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.green,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 14),
        ],
      ),
    );
  }

  Widget _editAction({
    required String label,
    required String value,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Semantics(
      button: true,
      label: label,
      value: value,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.t3),
    filled: true,
    fillColor: AppColors.bgInteract,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ── Status banners + action buttons ──────────────────────────────────────────
class AppointmentActionSection extends StatelessWidget {
  final String status;
  final String notes;
  final bool loading;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const AppointmentActionSection({
    super.key,
    required this.status,
    required this.notes,
    required this.loading,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'scheduled') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onComplete,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.onBrandAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text(
                'Mark as Complete',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(LucideIcons.x, size: 18),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successDim,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: AppColors.success, size: 18),
            SizedBox(width: 12),
            Text(
              'This booking is complete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorDim,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.xCircle, color: AppColors.error, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking cancelled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: $notes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
