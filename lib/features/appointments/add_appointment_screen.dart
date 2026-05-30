import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_settings_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/working_hours.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  String? _selectedClientId;
  String? _selectedServiceId;
  String? _selectedServiceName;
  double? _selectedPrice;
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 9;
  int _selectedMinute = 0;
  int _selectedDuration = 60;
  String _repeatMode = 'none';
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    if (_selectedClientId == null || _selectedServiceId == null) return;
    setState(() => _saving = true);
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) return;

      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
        _selectedMinute,
      ).toUtc();
      final endTime = startTime.add(Duration(minutes: _selectedDuration));
      final recurrenceRule = _recurrenceRuleFor(_repeatMode);
      final repeatOccurrences = _repeatOccurrencesFor(_repeatMode);

      await ref
          .read(appointmentsRepositoryProvider)
          .create(
            workspaceId: workspaceId,
            contactId: _selectedClientId!,
            serviceId: _selectedServiceId!,
            title: _selectedServiceName,
            startTime: startTime,
            endTime: endTime,
            price: _selectedPrice ?? 0,
            notes: _notesController.text,
            recurrenceRule: recurrenceRule,
            repeatOccurrences: repeatOccurrences,
          );
      await ref
          .read(notificationsRepositoryProvider)
          .create(
            workspaceId: workspaceId,
            type: 'new_booking',
            title: repeatOccurrences > 1
                ? 'Repeating booking created'
                : 'New booking created',
            body: repeatOccurrences > 1
                ? 'Created $repeatOccurrences appointments for ${_selectedServiceName ?? 'this service'}.'
                : '${_selectedServiceName ?? 'Appointment'} booked for ${_formatDate(_selectedDate)}.',
            deepLink: '/work',
          );

      ref.invalidate(appointmentsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final services = ref.watch(servicesProvider);
    final workspaceSettings = ref.watch(workspaceSettingsProvider);
    final existingAppointments = ref.watch(appointmentsProvider);

    final appointmentStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
      _selectedMinute,
    );
    final endTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
      _selectedMinute,
    ).add(Duration(minutes: _selectedDuration));
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final workingHours = workspaceSettings.value?['working_hours'] is Map
        ? Map<String, dynamic>.from(
            workspaceSettings.value!['working_hours'] as Map,
          )
        : <String, dynamic>{};
    final insideWorkingHours =
        workingHours.isEmpty ||
        isWithinWorkingHours(
          hours: workingHours,
          start: appointmentStart,
          end: endTime,
        );
    final dayHoursLabel = workingHours.isEmpty
        ? null
        : formatWorkingHourValue(
            workingHoursValueForDate(workingHours, appointmentStart),
          );
    final conflicts = (existingAppointments.value ?? const []).where((
      appointment,
    ) {
      if (appointment['status'] == 'cancelled') return false;
      final start = DateTime.tryParse(
        appointment['start_time']?.toString() ?? '',
      )?.toLocal();
      final end = DateTime.tryParse(
        appointment['end_time']?.toString() ?? '',
      )?.toLocal();
      if (start == null || end == null) return false;
      return start.isBefore(endTime) && end.isAfter(appointmentStart);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
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
                        Icons.close_rounded,
                        color: AppColors.t2,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'New Appointment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.t1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        (_selectedClientId != null &&
                            _selectedServiceId != null &&
                            !_saving)
                        ? _save
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_selectedClientId != null &&
                                _selectedServiceId != null)
                            ? AppColors.green
                            : AppColors.bgInteract,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _repeatOccurrencesFor(_repeatMode) > 1
                                  ? 'Book ${_repeatOccurrencesFor(_repeatMode)}'
                                  : 'Book',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    (_selectedClientId != null &&
                                        _selectedServiceId != null)
                                    ? Colors.white
                                    : AppColors.t3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Client ──────────────────────────────────────
                    _label('CLIENT'),
                    const SizedBox(height: 8),
                    clients.when(
                      loading: () => _skeleton(54),
                      error: (_, __) => _errorBox('Error loading clients'),
                      data: (data) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClientId,
                            isExpanded: true,
                            dropdownColor: AppColors.bgRaised,
                            icon: const Padding(
                              padding: EdgeInsets.only(right: 14),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.t3,
                              ),
                            ),
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Select client',
                                style: TextStyle(
                                  color: AppColors.t3,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            items: data
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          color: AppColors.t1,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedClientId = v),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Service ──────────────────────────────────────
                    _label('SERVICE'),
                    const SizedBox(height: 8),
                    services.when(
                      loading: () => _skeleton(54),
                      error: (_, __) => _errorBox('Error loading services'),
                      data: (data) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedServiceId,
                            isExpanded: true,
                            dropdownColor: AppColors.bgRaised,
                            icon: const Padding(
                              padding: EdgeInsets.only(right: 14),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.t3,
                              ),
                            ),
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Select service',
                                style: TextStyle(
                                  color: AppColors.t3,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            items: data
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s['id'] as String,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s['name'] as String,
                                            style: const TextStyle(
                                              color: AppColors.t1,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            '£${(s['price'] as num).toStringAsFixed(0)} · ${s['duration_mins']}min',
                                            style: const TextStyle(
                                              color: AppColors.t3,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              final svc = data.firstWhere(
                                (s) => s['id'] == v,
                                orElse: () => {},
                              );
                              setState(() {
                                _selectedServiceId = v;
                                _selectedServiceName = svc['name'] as String?;
                                _selectedPrice = (svc['price'] as num?)
                                    ?.toDouble();
                                _selectedDuration =
                                    svc['duration_mins'] as int? ?? 60;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Date ─────────────────────────────────────────
                    _label('DATE'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.t3,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.t1,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.t3,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Time ─────────────────────────────────────────
                    _label('TIME'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.t3,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.t1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '– $endStr',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.t3,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.t3,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!insideWorkingHours && dayHoursLabel != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warningDim,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${weekdayName(appointmentStart)} hours are $dayHoursLabel. This booking falls outside your working blocks.',
                                style: const TextStyle(
                                  color: AppColors.t2,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (conflicts.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorDim,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.event_busy_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This overlaps ${conflicts.length} existing appointment${conflicts.length == 1 ? '' : 's'}. You can still book it, but it may create a clash.',
                                style: const TextStyle(
                                  color: AppColors.t2,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Repeat ───────────────────────────────────────
                    _label('REPEAT'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _repeatMode,
                          isExpanded: true,
                          dropdownColor: AppColors.bgRaised,
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.t3,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'none',
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "Doesn't repeat",
                                  style: TextStyle(
                                    color: AppColors.t1,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Weekly · next 12 weeks',
                                  style: TextStyle(
                                    color: AppColors.t1,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'fortnightly',
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Fortnightly · next 12 weeks',
                                  style: TextStyle(
                                    color: AppColors.t1,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Monthly · next 3 months',
                                  style: TextStyle(
                                    color: AppColors.t1,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _repeatMode = value ?? 'none'),
                        ),
                      ),
                    ),
                    if (_repeatMode != 'none') ...[
                      const SizedBox(height: 8),
                      Text(
                        _repeatSummary,
                        style: const TextStyle(
                          color: AppColors.t3,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Price ─────────────────────────────────────────
                    if (_selectedPrice != null) ...[
                      _label('PRICE'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_money_rounded,
                              color: AppColors.t3,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '£${_selectedPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.t1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Notes ─────────────────────────────────────────
                    _label('NOTES (OPTIONAL)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.t1, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Add any notes...',
                        hintStyle: const TextStyle(color: AppColors.t3),
                        filled: true,
                        fillColor: AppColors.bgCard,
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
                          borderSide: const BorderSide(
                            color: AppColors.green,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: AppColors.t3,
    ),
  );

  Widget _skeleton(double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
    ),
  );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      msg,
      style: const TextStyle(color: AppColors.error, fontSize: 13),
    ),
  );

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

  String? _recurrenceRuleFor(String mode) {
    return switch (mode) {
      'weekly' => 'FREQ=WEEKLY;INTERVAL=1',
      'fortnightly' => 'FREQ=WEEKLY;INTERVAL=2',
      'monthly' => 'FREQ=MONTHLY;INTERVAL=1',
      _ => null,
    };
  }

  int _repeatOccurrencesFor(String mode) {
    return switch (mode) {
      'weekly' => 12,
      'fortnightly' => 6,
      'monthly' => 3,
      _ => 1,
    };
  }

  String get _repeatSummary {
    final count = _repeatOccurrencesFor(_repeatMode);
    final label = switch (_repeatMode) {
      'weekly' => 'weekly',
      'fortnightly' => 'every 2 weeks',
      'monthly' => 'monthly',
      _ => '',
    };
    return 'Creates $count appointments $label from the selected date.';
  }
}
