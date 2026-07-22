import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/slate_ui.dart';
import '../../clients/client_detail_screen.dart';

// ── Hero card (client + service) ──────────────────────────────────────────────
class AppointmentHeroCard extends StatelessWidget {
  // Shared
  final bool editing;
  // View mode
  final String clientName;
  final String serviceName;
  final num? price;
  final String initials;
  final String? contactId;
  final Map<String, dynamic> appt;
  // Edit mode
  final AsyncValue<List<Map<String, dynamic>>> clients;
  final List<Map<String, dynamic>> services;
  final String? selectedClientId;
  final String? selectedServiceId;
  final TextEditingController priceController;
  final TextEditingController serviceTitleController;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onServiceChanged;

  const AppointmentHeroCard({
    super.key,
    required this.editing,
    required this.clientName,
    required this.serviceName,
    this.price,
    required this.initials,
    this.contactId,
    required this.appt,
    required this.clients,
    required this.services,
    this.selectedClientId,
    this.selectedServiceId,
    required this.priceController,
    required this.serviceTitleController,
    required this.onClientChanged,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SlateGlassSurface(
        blur: 18,
        radius: AppRadius.lg,
        color: AppColors.bgCard.withValues(alpha: 0.72),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: editing ? _buildEditMode() : _buildViewMode(context),
      ),
    );
  }

  Widget _buildViewMode(BuildContext context) {
    return Row(
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
                fontWeight: FontWeight.w800,
                color: AppColors.green,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openClient(context),
                child: Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.t1,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: contactId == null ? null : () => _openClient(context),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.t3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (contactId != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'View client',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                  ],
                ),
              ),
            ],
          ),
        ),
        if (price != null)
          Text(
            '£${price!.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.t1,
            ),
          ),
      ],
    );
  }

  void _openClient(BuildContext context) {
    if (contactId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(
          client: {
            'id': contactId,
            'name': clientName,
            'phone': appt['contacts']?['phone'] ?? '',
            'email': appt['contacts']?['email'] ?? '',
            'notes': appt['contacts']?['notes'] ?? '',
            'status': appt['contacts']?['status'] ?? 'active',
          },
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    final serviceValues = {
      ...services.map((service) => service['id'] as String),
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
              const CircularProgressIndicator(color: AppColors.green),
          error: (_, __) => const Text(
            'Error loading clients',
            style: TextStyle(color: AppColors.error),
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Service'),
        const SizedBox(height: 8),
        WorkloopPickerField<String>(
          value: serviceValue,
          title: 'Choose a service',
          hint: 'Select service',
          searchHint: 'Search services',
          leadingIcon: LucideIcons.briefcase,
          options: [
            ...services.map(
              (s) => WorkloopPickerOption(
                value: s['id'] as String,
                label: s['name'] as String,
                subtitle: s['duration_mins'] == null
                    ? null
                    : '${s['duration_mins']} min',
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
          keyboardType: TextInputType.number,
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
      fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: editing ? _buildEditMode() : _buildViewMode(),
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

  Widget _buildEditMode() {
    return Column(
      children: [
        GestureDetector(
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
        GestureDetector(
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
        _durationEditor(),
      ],
    );
  }

  Widget _durationEditor() {
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
            return GestureDetector(
              onTap: () => onDurationSelected(minutes),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.slateLight : AppColors.bgInteract,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.borderStrong : AppColors.border,
                  ),
                ),
                child: Text(
                  '${minutes}m',
                  style: TextStyle(
                    color: selected ? AppColors.panelInk : AppColors.t2,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
    return Row(
      children: [
        Icon(icon, color: AppColors.t3, size: 16),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.t3)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.t1,
          ),
        ),
      ],
    );
  }

  Widget _editRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.t3, size: 16),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.t3)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 14),
      ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.onBrandAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text(
                'Mark as Complete',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(LucideIcons.x, size: 18),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
          borderRadius: BorderRadius.circular(14),
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
                fontWeight: FontWeight.w600,
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
          borderRadius: BorderRadius.circular(14),
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
                      fontWeight: FontWeight.w600,
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
