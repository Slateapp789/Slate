import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/repositories/slate_repositories.dart';
import 'widgets/appointment_detail_widgets.dart';

const List<String> _cancelReasons = [
  'Client cancelled',
  'Client no show',
  'Rescheduled',
  'Emergency',
  'Weather',
  'Other',
];

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  late Map<String, dynamic> _appt;
  bool _loading = false;
  bool _editing = false;

  String? _selectedClientId;
  String? _selectedServiceId;
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 9;
  int _selectedMinute = 0;
  late TextEditingController _serviceTitleController;
  late TextEditingController _durationController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _priceController;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _appt = Map<String, dynamic>.from(widget.appointment);
    _notesController = TextEditingController(
      text: _appt['notes'] as String? ?? '',
    );
    _serviceTitleController = TextEditingController(
      text:
          _appt['services']?['name'] as String? ??
          _appt['title'] as String? ??
          '',
    );
    _priceController = TextEditingController(
      text: _appt['price']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: _appt['location'] as String? ?? '',
    );
    final startTime = DateTime.tryParse(
      _appt['start_time'] as String? ?? '',
    )?.toLocal();
    final endTime = DateTime.tryParse(
      _appt['end_time'] as String? ?? '',
    )?.toLocal();
    if (startTime != null) {
      _selectedDate = startTime;
      _selectedHour = startTime.hour;
      _selectedMinute = startTime.minute;
    }
    _durationController = TextEditingController(
      text: startTime != null && endTime != null
          ? '${endTime.difference(startTime).inMinutes}'
          : '60',
    );
    _selectedClientId = _appt['contact_id'] as String?;
    _selectedServiceId = _appt['service_id'] as String? ?? '__custom__';
    _loadServices();
  }

  @override
  void dispose() {
    _serviceTitleController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadServices() async {
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return;
    final data = await ref
        .read(servicesRepositoryProvider)
        .listRows(workspaceId);
    setState(() => _services = data);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _updateStatus(String status, {String? cancelReason}) async {
    setState(() => _loading = true);
    try {
      final updates = {'status': status};
      if (cancelReason != null) updates['notes'] = cancelReason;
      await ref
          .read(appointmentsRepositoryProvider)
          .update(_appt['id'] as String, updates);
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId != null &&
          (status == 'cancelled' || status == 'no_show')) {
        final name = _appt['contacts']?['name'] as String? ?? 'Client';
        await ref
            .read(notificationsRepositoryProvider)
            .create(
              workspaceId: workspaceId,
              type: status == 'no_show' ? 'no_show' : 'booking',
              title: status == 'no_show'
                  ? 'Booking no-show'
                  : 'Booking cancelled',
              body: cancelReason?.isNotEmpty == true
                  ? '$name: $cancelReason'
                  : '$name booking was updated.',
              deepLink: '/work',
            );
      }
      setState(() {
        _appt['status'] = status;
        if (cancelReason != null) _appt['notes'] = cancelReason;
        _loading = false;
      });
      ref.invalidate(appointmentsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _snack('Error: $e');
    }
  }

  Future<void> _saveEdit() async {
    setState(() => _loading = true);
    try {
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
        _selectedMinute,
      ).toUtc();
      int durationMins = int.tryParse(_durationController.text.trim()) ?? 60;
      if (_selectedServiceId != null && _selectedServiceId != '__custom__') {
        final svc = _services.firstWhere(
          (s) => s['id'] == _selectedServiceId,
          orElse: () => {},
        );
        durationMins =
            int.tryParse(_durationController.text.trim()) ??
            (svc['duration_mins'] as int? ?? 60);
      }
      final endTime = startTime.add(Duration(minutes: durationMins));
      final updates = {
        'contact_id': _selectedClientId,
        'service_id': _selectedServiceId == '__custom__'
            ? null
            : _selectedServiceId,
        'title': _serviceTitleController.text.trim().isEmpty
            ? 'Booking'
            : _serviceTitleController.text.trim(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? _appt['price'],
      };
      await ref
          .read(appointmentsRepositoryProvider)
          .update(_appt['id'] as String, updates);
      setState(() {
        _appt = {
          ..._appt,
          ...updates,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
        };
        _editing = false;
        _loading = false;
      });
      ref.invalidate(appointmentsProvider);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _snack('Error: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _addLinkedTask(String title) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return;
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return;
    await ref
        .read(tasksRepositoryProvider)
        .create(
          workspaceId: workspaceId,
          title: cleaned,
          priority: 'medium',
          dueDate: _selectedDate,
          contactId: _appt['contact_id'] as String?,
          appointmentId: _appt['id'] as String,
        );
    ref.invalidate(appointmentTasksProvider(_appt['id'] as String));
    ref.invalidate(tasksProvider);
    ref.invalidate(allTasksProvider);
  }

  void _showAddTaskSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add booking task',
              style: TextStyle(
                color: AppColors.t1,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.t1),
              decoration: InputDecoration(
                hintText: 'e.g. Confirm address',
                hintStyle: const TextStyle(color: AppColors.t3),
                filled: true,
                fillColor: AppColors.bgInteract,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.green),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await _addLinkedTask(controller.text);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.green,
            surface: AppColors.bgCard,
            onSurface: AppColors.t1,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    int tempHour = _selectedHour;
    int tempMinute = _selectedMinute;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => SizedBox(
          height: 280,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.t1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHour = tempHour;
                          _selectedMinute = tempMinute;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 48,
                        perspective: 0.003,
                        diameterRatio: 1.8,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: tempHour,
                        ),
                        onSelectedItemChanged: (i) =>
                            setModal(() => tempHour = i),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 24,
                          builder: (context, i) {
                            final selected = i == tempHour;
                            return Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: selected ? 24 : 18,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w400,
                                  color: selected ? AppColors.t1 : AppColors.t3,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.t1,
                      ),
                    ),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 48,
                        perspective: 0.003,
                        diameterRatio: 1.8,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: tempMinute ~/ 15,
                        ),
                        onSelectedItemChanged: (i) =>
                            setModal(() => tempMinute = i * 15),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 4,
                          builder: (context, i) {
                            final min = i * 15;
                            final selected = min == tempMinute;
                            return Center(
                              child: Text(
                                min.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: selected ? 24 : 18,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w400,
                                  color: selected ? AppColors.t1 : AppColors.t3,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelSheet() {
    String? selectedReason;
    final otherController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cancel Booking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Why is this being cancelled?',
                style: TextStyle(fontSize: 14, color: AppColors.t3),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cancelReasons.map((reason) {
                  final active = selectedReason == reason;
                  return GestureDetector(
                    onTap: () => setModal(() => selectedReason = reason),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.errorDim
                            : AppColors.bgInteract,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? AppColors.error : AppColors.border,
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.error : AppColors.t2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: otherController,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.t1),
                  decoration: InputDecoration(
                    hintText: 'Enter reason...',
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
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          final reason = selectedReason == 'Other'
                              ? otherController.text.trim()
                              : selectedReason!;
                          Navigator.pop(context);
                          _updateStatus(
                            'cancelled',
                            cancelReason: reason.isEmpty
                                ? selectedReason
                                : reason,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor: AppColors.bgInteract,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = _appt['status'] as String? ?? 'scheduled';
    final clientName = _appt['contacts']?['name'] as String? ?? 'Walk-in';
    final serviceName =
        _appt['services']?['name'] as String? ??
        _appt['title'] as String? ??
        'Booking';
    final startTime = DateTime.tryParse(
      _appt['start_time'] as String? ?? '',
    )?.toLocal();
    final endTime = DateTime.tryParse(
      _appt['end_time'] as String? ?? '',
    )?.toLocal();
    final notes = _appt['notes'] as String? ?? '';
    final price = _appt['price'];
    final recurrenceRule = _appt['recurrence_rule'] as String?;
    final clients = ref.watch(clientsProvider);
    final linkedTasks = ref.watch(
      appointmentTasksProvider(_appt['id'] as String),
    );
    final statusColor = status == 'completed'
        ? AppColors.success
        : status == 'cancelled'
        ? AppColors.error
        : status == 'no_show'
        ? AppColors.warning
        : AppColors.green;
    final initials = clientName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        color: AppColors.t2,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Booking',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.t1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (status == 'scheduled')
                    GestureDetector(
                      onTap: () => _editing
                          ? _saveEdit()
                          : setState(() => _editing = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _editing ? AppColors.green : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _editing
                                ? AppColors.green
                                : AppColors.border,
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _editing ? 'Save' : 'Edit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _editing ? Colors.white : AppColors.t2,
                                ),
                              ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Hero card ─────────────────────────────────────────────────
              AppointmentHeroCard(
                editing: _editing,
                clientName: clientName,
                serviceName: serviceName,
                price: price as num?,
                initials: initials,
                contactId: _appt['contact_id'] as String?,
                appt: _appt,
                clients: clients.whenData(
                  (data) => data.map((client) => client.toMap()).toList(),
                ),
                services: _services,
                selectedClientId: _selectedClientId,
                selectedServiceId: _selectedServiceId,
                priceController: _priceController,
                serviceTitleController: _serviceTitleController,
                durationController: _durationController,
                onClientChanged: (v) => setState(() => _selectedClientId = v),
                onServiceChanged: (v) {
                  if (v == null) return;
                  if (v == '__custom__') {
                    setState(() => _selectedServiceId = v);
                    return;
                  }
                  final service = _services.firstWhere(
                    (s) => s['id'] == v,
                    orElse: () => {},
                  );
                  setState(() {
                    _selectedServiceId = v;
                    _serviceTitleController.text =
                        service['name'] as String? ?? '';
                    final price = (service['price'] as num?)?.toDouble();
                    if (price != null) {
                      _priceController.text = price.toStringAsFixed(0);
                    }
                    final duration = service['duration_mins'] as int?;
                    if (duration != null) {
                      _durationController.text = '$duration';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // ── Date + time ───────────────────────────────────────────────
              AppointmentDateTimeCard(
                editing: _editing,
                startTime: startTime,
                endTime: endTime,
                selectedDate: _selectedDate,
                selectedHour: _selectedHour,
                selectedMinute: _selectedMinute,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _editing
                    ? TextField(
                        controller: _locationController,
                        style: const TextStyle(color: AppColors.t1),
                        decoration: InputDecoration(
                          labelText: 'Location',
                          labelStyle: const TextStyle(
                            color: AppColors.t3,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.bgInteract,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.green,
                              width: 1.5,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            color: AppColors.t3,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Location',
                            style: TextStyle(fontSize: 13, color: AppColors.t3),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              (_appt['location'] as String?)?.isNotEmpty == true
                                  ? _appt['location'] as String
                                  : 'Not set',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.t1,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              if (recurrenceRule != null && recurrenceRule.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.repeat,
                        color: AppColors.t3,
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _repeatLabel(recurrenceRule),
                        style: const TextStyle(
                          color: AppColors.t2,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Notes ─────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _editing
                    ? TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: AppColors.t1,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          labelStyle: const TextStyle(
                            color: AppColors.t3,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.bgInteract,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.green,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.fileText,
                            color: AppColors.t3,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: notes.isEmpty
                                ? const Text(
                                    'No notes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.t3,
                                    ),
                                  )
                                : Text(
                                    notes,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.t2,
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              _BookingTasksCard(
                tasks: linkedTasks,
                onAddTask: _showAddTaskSheet,
                onToggle: (task) async {
                  final done = task.status == 'done';
                  await ref
                      .read(tasksRepositoryProvider)
                      .updateStatus(task.id, done ? 'open' : 'done');
                  ref.invalidate(
                    appointmentTasksProvider(_appt['id'] as String),
                  );
                  ref.invalidate(tasksProvider);
                  ref.invalidate(allTasksProvider);
                },
              ),
              const SizedBox(height: 24),

              // ── Actions ───────────────────────────────────────────────────
              AppointmentActionSection(
                status: status,
                notes: notes,
                loading: _loading,
                onComplete: () => _updateStatus('completed'),
                onCancel: _showCancelSheet,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _repeatLabel(String rule) {
    if (rule.contains('FREQ=MONTHLY')) return 'Repeats monthly';
    if (rule.contains('INTERVAL=2')) return 'Repeats fortnightly';
    if (rule.contains('FREQ=WEEKLY')) return 'Repeats weekly';
    return 'Repeating booking';
  }
}

class _BookingTasksCard extends StatelessWidget {
  final AsyncValue<List<SlateTask>> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<SlateTask> onToggle;

  const _BookingTasksCard({
    required this.tasks,
    required this.onAddTask,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.listChecks, color: AppColors.t3, size: 16),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Booking tasks',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddTask,
                icon: const Icon(LucideIcons.plus, size: 15),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          tasks.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, __) => const Text(
              'Could not load booking tasks',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text(
                  'Add prep, follow-up, or payment tasks for this booking.',
                  style: TextStyle(color: AppColors.t3, fontSize: 13),
                );
              }
              return Column(
                children: items.map((task) {
                  final done = task.status == 'done';
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onToggle(task),
                    leading: Icon(
                      done ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      color: done ? AppColors.success : AppColors.t3,
                      size: 19,
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        color: done ? AppColors.t3 : AppColors.t1,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
