import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/workloop_capabilities.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/maps_preference_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_settings_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/currency_format.dart';
import '../../shared/utils/maps_launcher.dart';
import '../../shared/utils/workflow_idempotency.dart';
import '../../shared/widgets/slate_ui.dart';
import '../clients/client_detail_screen.dart';
import '../clients/widgets/client_form.dart';
import '../finance/add_payment_screen.dart';
import '../finance/payment_collection_sheet.dart';
import 'widgets/appointment_detail_widgets.dart';

part 'appointment_detail_sections.dart';

const List<String> _cancelReasons = [
  'Client cancelled',
  'Client no show',
  'Rescheduled',
  'Emergency',
  'Weather',
  'Other',
];

typedef _BookingEditDraft = ({
  String? clientId,
  String? serviceId,
  String date,
  int hour,
  int minute,
  String duration,
  String title,
  String locationMode,
  String location,
  String notes,
  String price,
});

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _BookingDetailAction extends StatelessWidget {
  final String label;
  final bool loading;
  final bool primary;
  final VoidCallback onTap;

  const _BookingDetailAction({
    required this.label,
    required this.loading,
    this.primary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary
          ? AppColors.accentPrimary.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 58,
            minHeight: AppSpacing.minTouch,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: primary ? AppColors.accentPrimary : AppColors.t2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  late Map<String, dynamic> _appt;
  bool _loading = false;
  bool _editing = false;
  String _locationMode = 'business';

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
  bool _notesExpanded = false;
  bool _paymentExpanded = false;
  bool _tasksExpanded = false;
  bool _openingClient = false;
  bool _allowPop = false;
  final String _completionIdempotencyKey = createWorkflowIdempotencyKey();
  late _BookingEditDraft _savedEditDraft;

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
    final locationText = (_appt['location'] as String? ?? '').toLowerCase();
    if (locationText.contains('client')) {
      _locationMode = 'client';
    } else if (locationText.contains('online') ||
        locationText.contains('phone')) {
      _locationMode = 'online';
    }
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
    for (final controller in [
      _serviceTitleController,
      _durationController,
      _locationController,
      _notesController,
      _priceController,
    ]) {
      controller.addListener(_handleDraftChanged);
    }
    _savedEditDraft = _currentEditDraft;
    _loadServices();
  }

  void _handleDraftChanged() {
    if (mounted) setState(() {});
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

  _BookingEditDraft get _currentEditDraft => (
    clientId: _selectedClientId,
    serviceId: _selectedServiceId,
    date:
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
    hour: _selectedHour,
    minute: _selectedMinute,
    duration: _durationController.text.trim(),
    title: _serviceTitleController.text.trim(),
    locationMode: _locationMode,
    location: _locationController.text.trim(),
    notes: _notesController.text.trim(),
    price: _priceController.text.trim(),
  );

  bool get _hasEditChanges => _currentEditDraft != _savedEditDraft;

  Future<void> _handleBack() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_editing || !_hasEditChanges) {
      await _leaveScreen();
      return;
    }
    final decision = await showWorkloopDraftConfirmation(
      context,
      title: 'Save booking changes?',
      message: 'You changed this booking. Save before returning to Bookings?',
      canSave: !_loading,
    );
    if (!mounted) return;
    switch (decision) {
      case WorkloopDraftDecision.save:
        if (await _saveEdit()) await _leaveScreen();
        return;
      case WorkloopDraftDecision.discard:
        await _leaveScreen();
        return;
      case WorkloopDraftDecision.stay:
        return;
    }
  }

  Future<void> _leaveScreen() async {
    if (!_allowPop && mounted) setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
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

  Future<void> _openLinkedClient() async {
    final clientId = _appt['contact_id'] as String?;
    if (clientId == null || _openingClient) return;
    setState(() => _openingClient = true);
    try {
      final repository = ref.read(clientsRepositoryProvider);
      final client = await repository.getById(clientId);
      if (!mounted) return;
      if (client == null) {
        _snack('This client is no longer available.');
        return;
      }
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ClientDetailScreen(client: client.toMap()),
        ),
      );
      if (!mounted) return;
      ref.invalidate(clientsProvider);
      final refreshedClient = await repository.getById(clientId);
      if (!mounted || refreshedClient == null) return;
      setState(() => _appt['contacts'] = refreshedClient.toMap());
    } catch (_) {
      if (mounted) {
        _snack(
          'Could not open this client. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingClient = false);
    }
  }

  Future<bool> _updateStatus(String status, {String? cancelReason}) async {
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
      return true;
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) _snack('The booking could not be updated.');
      return false;
    }
  }

  Future<void> _completeWithPayment(String paymentMode) async {
    Navigator.pop(context);
    await _runCompletionWorkflow(paymentMode: paymentMode);
  }

  Future<void> _completeWithLinkedPayment({
    Payment? payment,
    bool markPaid = false,
  }) async {
    Navigator.pop(context);
    await _runCompletionWorkflow(
      paymentMode: markPaid ? 'linked_paid' : 'linked_unpaid',
      linkedPayment: payment,
    );
  }

  Future<void> _completeAndCollectPayment(Payment? linkedPayment) async {
    Navigator.pop(context);
    final completed = await _runCompletionWorkflow(
      paymentMode: linkedPayment == null ? 'unpaid' : 'linked_unpaid',
      linkedPayment: linkedPayment,
    );
    if (!completed || !mounted) return;
    final payments = await ref
        .read(paymentsRepositoryProvider)
        .forAppointment(_appt['id'] as String);
    final payment = payments
        .where((item) => item.outstandingAmount > 0)
        .firstOrNull;
    if (payment == null || !mounted) {
      _snack('The booking is complete, but no payment is ready to collect.');
      return;
    }
    final collected = await showPaymentCollectionSheet(
      context: context,
      payment: payment,
    );
    if (collected) _refreshPaymentState();
  }

  Future<bool> _runCompletionWorkflow({
    required String paymentMode,
    Payment? linkedPayment,
  }) async {
    setState(() => _loading = true);
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) {
        throw StateError('No active workspace.');
      }
      final startTime =
          DateTime.tryParse(_appt['start_time'] as String? ?? '') ??
          DateTime.now();
      await ref
          .read(appointmentsRepositoryProvider)
          .completeBookingWorkflow(
            workspaceId: workspaceId,
            appointmentId: _appt['id'] as String,
            idempotencyKey: _completionIdempotencyKey,
            paymentMode: paymentMode,
            linkedPaymentId: linkedPayment?.id,
            paymentDate: startTime.toLocal(),
          );
      if (!mounted) return true;
      setState(() {
        _appt['status'] = 'completed';
        _loading = false;
      });
      ref.invalidate(appointmentsProvider);
      _refreshPaymentState();
      if (paymentMode == 'linked_paid' && linkedPayment != null) {
        _snack('${formatPounds(linkedPayment.total)} marked as received');
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('The booking could not be completed. Please try again.');
      }
      return false;
    }
  }

  Future<void> _markLinkedPaymentPaid(Payment payment) async {
    try {
      await ref.read(paymentsRepositoryProvider).markPaid(payment);
    } catch (_) {
      if (mounted) {
        _snack('The payment could not be updated. Please try again.');
      }
      return;
    }
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .create(
            workspaceId: payment.workspaceId,
            type: 'payment_received',
            title: 'Payment received',
            body:
                '${formatPounds(payment.total)} from ${payment.clientName ?? 'a client'} is now paid.',
            deepLink: '/payments',
          );
    } catch (_) {
      // The confirmed payment remains the source of truth. Notification
      // delivery is best-effort and must not leave the booking visibly stale.
    }
    _refreshPaymentState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatPounds(payment.total)} marked as received',
            style: const TextStyle(color: AppColors.onBrandAccent),
          ),
          backgroundColor: AppColors.brandAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _refreshPaymentState() {
    ref.invalidate(appointmentPaymentsProvider(_appt['id'] as String));
    ref.invalidate(invoicesProvider);
    ref.invalidate(financeSummaryProvider);
    ref.invalidate(dashboardRevenueProvider);
    ref.invalidate(clientCrmRecordsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  void _showCompletionSheet(List<Payment> payments) {
    final paymentCollectionEnabled = ref.read(paymentCollectionEnabledProvider);
    final amount = (_appt['price'] as num?)?.toDouble() ?? 0;
    final hasLinkedPayment = payments.isNotEmpty;
    final unpaidLinkedPayments = payments
        .where((payment) => payment.status != 'paid')
        .toList();
    final unpaidLinkedPayment = unpaidLinkedPayments.isEmpty
        ? null
        : unpaidLinkedPayments.first;
    final hasPaidLinkedPayment = payments.any(
      (payment) => payment.status == 'paid',
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete booking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.t1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unpaidLinkedPayment != null
                  ? 'This booking already has an unpaid Money item linked. Mark it paid now or leave it to follow up later.'
                  : hasPaidLinkedPayment
                  ? 'This booking already has a paid Money item linked.'
                  : amount > 0
                  ? 'How should Workloop handle the ${formatPounds(amount)} payment?'
                  : 'No booking price is set, so you can complete it without recording money.',
              style: const TextStyle(fontSize: 13, color: AppColors.t3),
            ),
            const SizedBox(height: 18),
            if (unpaidLinkedPayment != null) ...[
              if (paymentCollectionEnabled) ...[
                SlateButton(
                  label: 'Take Card Payment',
                  icon: LucideIcons.smartphoneNfc,
                  onPressed: () =>
                      _completeAndCollectPayment(unpaidLinkedPayment),
                ),
                const SizedBox(height: 10),
              ],
              SlateButton(
                label: 'Mark Linked Payment Paid',
                icon: LucideIcons.checkCircle,
                secondary: true,
                onPressed: () => _completeWithLinkedPayment(
                  payment: unpaidLinkedPayment,
                  markPaid: true,
                ),
              ),
              const SizedBox(height: 10),
              SlateButton(
                label: 'Complete, Leave Unpaid',
                icon: LucideIcons.clock3,
                secondary: true,
                onPressed: () =>
                    _completeWithLinkedPayment(payment: unpaidLinkedPayment),
              ),
              const SizedBox(height: 10),
            ] else if (!hasLinkedPayment && amount > 0) ...[
              if (paymentCollectionEnabled) ...[
                SlateButton(
                  label: 'Take Card Payment',
                  icon: LucideIcons.smartphoneNfc,
                  onPressed: () => _completeAndCollectPayment(null),
                ),
                const SizedBox(height: 10),
              ],
              SlateButton(
                label: 'Mark Paid',
                icon: LucideIcons.checkCircle,
                secondary: true,
                onPressed: () => _completeWithPayment('paid'),
              ),
              const SizedBox(height: 10),
              SlateButton(
                label: 'Record Unpaid',
                icon: LucideIcons.clock3,
                secondary: true,
                onPressed: () => _completeWithPayment('unpaid'),
              ),
              const SizedBox(height: 10),
            ],
            if (unpaidLinkedPayment == null)
              SlateButton(
                label: hasLinkedPayment ? 'Complete Booking' : 'Skip Money',
                icon: hasLinkedPayment
                    ? LucideIcons.check
                    : LucideIcons.arrowRight,
                secondary: !hasLinkedPayment,
                onPressed: () => _completeWithPayment('skip'),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _saveEdit() async {
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
      final workspaceId =
          _appt['workspace_id'] as String? ??
          await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) {
        throw const AppointmentScheduleException('Workspace unavailable.');
      }
      final settings = await ref.read(workspaceSettingsProvider.future);
      final workingHours = settings?['working_hours'] is Map
          ? Map<String, dynamic>.from(settings!['working_hours'] as Map)
          : <String, dynamic>{};
      final repository = ref.read(appointmentsRepositoryProvider);
      try {
        await repository.ensureScheduleAvailable(
          workspaceId: workspaceId,
          startTime: startTime,
          endTime: endTime,
          workingHours: workingHours,
          excludeAppointmentId: _appt['id'] as String?,
        );
      } on AppointmentScheduleException catch (error) {
        if (error.issue != AppointmentScheduleIssue.workingHours) rethrow;
        if (!mounted) return false;
        final proceed = await showWorkloopOutsideHoursConfirmation(
          context,
          detail: error.message,
        );
        if (!proceed) {
          if (mounted) setState(() => _loading = false);
          return false;
        }
        await repository.ensureScheduleAvailable(
          workspaceId: workspaceId,
          startTime: startTime,
          endTime: endTime,
          workingHours: workingHours,
          excludeAppointmentId: _appt['id'] as String?,
          enforceWorkingHours: false,
        );
      }
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
        'location': _bookingLocationValue,
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
        _savedEditDraft = _currentEditDraft;
      });
      ref.invalidate(appointmentsProvider);
      return true;
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) _snack('The booking could not be updated.');
      return false;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String? get _bookingLocationValue {
    final custom = _locationController.text.trim();
    if (custom.isNotEmpty) return custom;
    return switch (_locationMode) {
      'client' => 'Client location',
      'online' => 'Online / phone',
      _ => 'Business location',
    };
  }

  String get _locationDisplayValue {
    final location = (_appt['location'] as String?)?.trim();
    if (location?.isNotEmpty == true) return location!;
    return switch (_locationMode) {
      'client' => 'Client location - add address',
      'online' => 'Online / phone - add link',
      _ => 'Business location - add address',
    };
  }

  Future<void> _openDirections() async {
    final address = _locationDisplayValue.trim();
    if (address.isEmpty ||
        address.contains('add address') ||
        address.contains('add link') ||
        address.startsWith('Online')) {
      return;
    }
    final preference = await ref.read(preferredMapsAppProvider.future);
    var selected = preference;
    if (preference == MapsAppPreference.askEveryTime) {
      if (!mounted) return;
      final choice = await showMapLaunchSheet(context, address);
      if (choice == null) return;
      selected = choice.app;
      if (choice.remember) {
        await ref
            .read(preferredMapsAppProvider.notifier)
            .setPreference(selected);
      }
    }
    final launched = await launchMapDirections(selected, address);
    if (!launched && mounted) _snack('Could not open directions');
  }

  void _selectEditClient(String? clientId, List<Client> clients) {
    setState(() {
      _selectedClientId = clientId;
      if (_locationMode != 'client' || clientId == null) return;
      for (final client in clients) {
        final address = client.address?.trim() ?? '';
        if (client.id == clientId && address.isNotEmpty) {
          _locationController.text = address;
          break;
        }
      }
    });
  }

  void _setEditLocationMode(String mode, List<Client> clients) {
    setState(() {
      _locationMode = mode;
      if (mode != 'client' || _selectedClientId == null) return;
      for (final client in clients) {
        final address = client.address?.trim() ?? '';
        if (client.id == _selectedClientId && address.isNotEmpty) {
          _locationController.text = address;
          break;
        }
      }
    });
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
                fontWeight: FontWeight.w600,
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
    final picked = await showWorkloopDatePicker(
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
    final picked = await _showAppointmentDetailTimePicker(
      context: context,
      initialHour: _selectedHour,
      initialMinute: _selectedMinute,
    );
    if (picked == null) return;
    setState(() {
      _selectedHour = picked.hour;
      _selectedMinute = picked.minute;
    });
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
                  fontWeight: FontWeight.w600,
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
                  return Semantics(
                    button: true,
                    selected: active,
                    label: reason,
                    onTap: () => setModal(() => selectedReason = reason),
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setModal(() => selectedReason = reason),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: AppSpacing.minTouch,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.errorDim
                                : AppColors.bgInteract,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: active
                                  ? AppColors.error
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active ? AppColors.error : AppColors.t2,
                            ),
                          ),
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
                    foregroundColor: AppColors.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
    final bookingPrice = price?.toDouble() ?? 0;
    final recurrenceRule = _appt['recurrence_rule'] as String?;
    final clients = ref.watch(clientsProvider);
    final linkedTasks = ref.watch(
      appointmentTasksProvider(_appt['id'] as String),
    );
    final linkedPayments = ref.watch(
      appointmentPaymentsProvider(_appt['id'] as String),
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

    return PopScope(
      canPop: _allowPop || !_editing || !_hasEditChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: WorkloopTexturedBackdrop()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.lg,
                  AppSpacing.pageX,
                  AppSpacing.xxl,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────────────
                    WorkloopRouteHeader(
                      title: 'Booking',
                      backSemanticLabel: 'Back to bookings',
                      onBack: _handleBack,
                      trailing: status == 'scheduled'
                          ? _BookingDetailAction(
                              label: _editing ? 'Save' : 'Edit',
                              loading: _loading,
                              primary: _editing,
                              onTap: () => _editing
                                  ? _saveEdit()
                                  : setState(() => _editing = true),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.capsule,
                                ),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                status.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
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
                      openingClient: _openingClient,
                      onOpenClient: _openLinkedClient,
                      clients: clients.whenData(
                        (data) => data.map((client) => client.toMap()).toList(),
                      ),
                      services: _services,
                      selectedClientId: _selectedClientId,
                      selectedServiceId: _selectedServiceId,
                      priceController: _priceController,
                      serviceTitleController: _serviceTitleController,
                      onClientChanged: (v) => _selectEditClient(
                        v,
                        clients.value ?? const <Client>[],
                      ),
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
                            _priceController.text = currencyInputValue(price);
                          }
                          final duration = service['duration_mins'] as int?;
                          if (duration != null) {
                            _durationController.text = '$duration';
                          }
                        });
                      },
                      onRetryClients: () => ref.invalidate(clientsProvider),
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
                      durationController: _durationController,
                      onPickDate: _pickDate,
                      onPickTime: _pickTime,
                      onDurationSelected: (minutes) {
                        setState(() => _durationController.text = '$minutes');
                      },
                      onDurationChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // The next operational decision stays close to the booking
                    // context instead of being hidden below notes and history.
                    AppointmentActionSection(
                      status: status,
                      notes: notes,
                      loading: _loading,
                      onComplete: () {
                        final payments = linkedPayments.value;
                        if (payments == null) {
                          _snack('Payment status is still loading');
                          return;
                        }
                        _showCompletionSheet(payments);
                      },
                      onCancel: _showCancelSheet,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _editing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      const [
                                        _BookingLocationOption(
                                          value: 'business',
                                          label: 'Business',
                                        ),
                                        _BookingLocationOption(
                                          value: 'client',
                                          label: 'Client',
                                        ),
                                        _BookingLocationOption(
                                          value: 'online',
                                          label: 'Online',
                                        ),
                                      ].map((option) {
                                        final selected =
                                            _locationMode == option.value;
                                        return WorkloopFilterChip(
                                          label: option.label,
                                          selected: selected,
                                          onTap: () => _setEditLocationMode(
                                            option.value,
                                            clients.value ?? const <Client>[],
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 10),
                                if (_locationMode == 'online')
                                  TextField(
                                    controller: _locationController,
                                    style: const TextStyle(color: AppColors.t1),
                                    decoration: InputDecoration(
                                      hintText: 'Call link or phone note',
                                      hintStyle: const TextStyle(
                                        color: AppColors.t3,
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
                                else
                                  BookingAddressField(
                                    controller: _locationController,
                                    onChanged: () => setState(() {}),
                                  ),
                              ],
                            )
                          : InkWell(
                              onTap: _openDirections,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final stacked =
                                      constraints.maxWidth < 280 ||
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(13) >
                                          18;
                                  const label = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.mapPin,
                                        color: AppColors.t3,
                                        size: 16,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Location',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.t3,
                                        ),
                                      ),
                                    ],
                                  );
                                  final value = Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _locationDisplayValue,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: stacked
                                              ? TextAlign.start
                                              : TextAlign.end,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.t1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      const Icon(
                                        LucideIcons.navigation,
                                        color: AppColors.modCalendar,
                                        size: 16,
                                      ),
                                    ],
                                  );
                                  if (stacked) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        label,
                                        const SizedBox(height: AppSpacing.xs),
                                        value,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      label,
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(child: value),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    if (recurrenceRule != null &&
                        recurrenceRule.isNotEmpty) ...[
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SlateDisclosure(
                      title: 'Notes',
                      subtitle: notes.isEmpty
                          ? 'No notes added'
                          : 'Booking context',
                      icon: LucideIcons.fileText,
                      expanded: _editing || _notesExpanded,
                      onToggle: () => setState(() {
                        if (!_editing) _notesExpanded = !_notesExpanded;
                      }),
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
                          : Text(
                              notes.isEmpty ? 'No notes' : notes,
                              style: TextStyle(
                                fontSize: 13,
                                color: notes.isEmpty
                                    ? AppColors.t3
                                    : AppColors.t2,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    SlateDisclosure(
                      title: 'Money',
                      subtitle: linkedPayments.when(
                        loading: () => 'Loading payment state',
                        error: (_, _) => 'Payment state unavailable',
                        data: (rows) => rows.isEmpty
                            ? bookingPrice > 0
                                  ? 'No payment linked · ${formatPounds(bookingPrice)}'
                                  : 'No payment linked'
                            : '${rows.length} linked payment${rows.length == 1 ? '' : 's'}',
                      ),
                      icon: LucideIcons.banknote,
                      expanded: _paymentExpanded,
                      onToggle: () =>
                          setState(() => _paymentExpanded = !_paymentExpanded),
                      child: _BookingPaymentCard(
                        payments: linkedPayments,
                        price: bookingPrice,
                        onRecordPayment: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPaymentScreen(
                                initialClientId: _appt['contact_id'] as String?,
                                appointmentId: _appt['id'] as String,
                              ),
                            ),
                          );
                          _refreshPaymentState();
                        },
                        onMarkPaid: _markLinkedPaymentPaid,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SlateDisclosure(
                      title: 'Booking tasks',
                      subtitle: linkedTasks.when(
                        loading: () => 'Loading tasks',
                        error: (_, _) => 'Tasks unavailable',
                        data: (items) => items.isEmpty
                            ? 'Prep and follow-up tasks'
                            : '${items.length} linked task${items.length == 1 ? '' : 's'}',
                      ),
                      icon: LucideIcons.listChecks,
                      expanded: _tasksExpanded,
                      onToggle: () =>
                          setState(() => _tasksExpanded = !_tasksExpanded),
                      child: _BookingTasksCard(
                        tasks: linkedTasks,
                        onAddTask: _showAddTaskSheet,
                        onRetry: () => ref.invalidate(
                          appointmentTasksProvider(_appt['id'] as String),
                        ),
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
}
