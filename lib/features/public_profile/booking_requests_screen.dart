import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';

final bookingRequestsProvider = FutureProvider<List<BookingRequest>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  try {
    return ref.watch(profileRepositoryProvider).bookingRequests(workspaceId);
  } catch (_) {
    return [];
  }
});

enum _RequestView { active, pending, contacted, booked, declined }

class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  ConsumerState<BookingRequestsScreen> createState() =>
      _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen> {
  _RequestView _view = _RequestView.active;

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(bookingRequestsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    AppSpacing.lg,
                    AppSpacing.pageX,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      WorkloopIconButton(
                        icon: LucideIcons.chevronLeft,
                        semanticLabel: 'Back to bookings',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Booking requests',
                          style: TextStyle(
                            color: AppColors.t1,
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                requests.maybeWhen(
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    final pending = items
                        .where((item) => item.status == 'pending')
                        .length;
                    final contacted = items
                        .where((item) => item.status == 'contacted')
                        .length;
                    final booked = items
                        .where((item) => item.status == 'confirmed')
                        .length;
                    final declined = items
                        .where((item) => item.status == 'declined')
                        .length;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          _RequestFilterChip(
                            label: 'Active ${pending + contacted}',
                            active: _view == _RequestView.active,
                            onTap: () =>
                                setState(() => _view = _RequestView.active),
                          ),
                          const SizedBox(width: 8),
                          _RequestFilterChip(
                            label: 'New $pending',
                            active: _view == _RequestView.pending,
                            onTap: () =>
                                setState(() => _view = _RequestView.pending),
                          ),
                          const SizedBox(width: 8),
                          _RequestFilterChip(
                            label: 'Contacted $contacted',
                            active: _view == _RequestView.contacted,
                            onTap: () =>
                                setState(() => _view = _RequestView.contacted),
                          ),
                          const SizedBox(width: 8),
                          _RequestFilterChip(
                            label: 'Booked $booked',
                            active: _view == _RequestView.booked,
                            onTap: () =>
                                setState(() => _view = _RequestView.booked),
                          ),
                          const SizedBox(width: 8),
                          _RequestFilterChip(
                            label: 'Declined $declined',
                            active: _view == _RequestView.declined,
                            onTap: () =>
                                setState(() => _view = _RequestView.declined),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                Expanded(
                  child: requests.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                    error: (_, __) => const _EmptyRequests(
                      title: 'Could not load requests',
                      subtitle: 'Try again in a moment.',
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const _EmptyRequests(
                          title: 'No booking requests',
                          subtitle:
                              'Requests from your public profile will appear here.',
                        );
                      }
                      final filtered = _filterRequests(items);
                      if (filtered.isEmpty) {
                        return _EmptyRequests(
                          title: switch (_view) {
                            _RequestView.pending => 'No new requests',
                            _RequestView.contacted => 'No contacted requests',
                            _RequestView.booked => 'No booked requests',
                            _RequestView.declined => 'No declined requests',
                            _ => 'No active requests',
                          },
                          subtitle: 'Switch filters to review other requests.',
                        );
                      }
                      return RefreshIndicator(
                        color: AppColors.green,
                        onRefresh: () async =>
                            ref.invalidate(bookingRequestsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          itemBuilder: (context, index) =>
                              _RequestCard(request: filtered[index]),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemCount: filtered.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<BookingRequest> _filterRequests(List<BookingRequest> items) {
    final filtered = items.where((item) {
      return switch (_view) {
        _RequestView.active =>
          item.status == 'pending' || item.status == 'contacted',
        _RequestView.pending => item.status == 'pending',
        _RequestView.contacted => item.status == 'contacted',
        _RequestView.booked => item.status == 'confirmed',
        _RequestView.declined => item.status == 'declined',
      };
    }).toList();

    const statusOrder = {
      'pending': 0,
      'contacted': 1,
      'confirmed': 2,
      'declined': 3,
    };
    filtered.sort((a, b) {
      final statusCompare = (statusOrder[a.status] ?? 9).compareTo(
        statusOrder[b.status] ?? 9,
      );
      if (statusCompare != 0) return statusCompare;
      final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreated.compareTo(aCreated);
    });
    return filtered;
  }
}

class _RequestFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RequestFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.t1.withValues(alpha: 0.10)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active
                ? AppColors.t1.withValues(alpha: 0.15)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.t1 : AppColors.t3,
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final BookingRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _saving = false;

  Future<void> _setStatus(String status) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateBookingRequestStatus(widget.request.id, status);
      ref.invalidate(bookingRequestsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _declineRequest() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Decline request?',
              style: TextStyle(
                color: AppColors.t1,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.request.name} will move to closed requests. You can still find it later.',
              style: const TextStyle(color: AppColors.t3, height: 1.35),
            ),
            const SizedBox(height: 18),
            SlateButton(
              label: 'Decline Request',
              icon: LucideIcons.xCircle,
              destructive: true,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            SlateButton(
              label: 'Keep Request',
              secondary: true,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _setStatus('declined');
    }
  }

  Future<void> _confirmAsBooking() async {
    final now = DateTime.now();
    var selectedDate = DateTime(now.year, now.month, now.day + 1);
    var selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final clientNameController = TextEditingController(
      text: widget.request.name,
    );
    final phoneController = TextEditingController(text: widget.request.phone);
    final serviceController = TextEditingController(
      text: widget.request.serviceName?.trim().isNotEmpty == true
          ? widget.request.serviceName!.trim()
          : 'Booking request',
    );
    final durationController = TextEditingController(
      text: (widget.request.serviceDurationMins ?? 60).toString(),
    );
    final priceController = TextEditingController(
      text: (widget.request.servicePrice ?? 0).toStringAsFixed(0),
    );
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    var createPaymentDue = (widget.request.servicePrice ?? 0) > 0;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool canSubmit() {
              final duration =
                  int.tryParse(durationController.text.trim()) ?? 0;
              final price = double.tryParse(priceController.text.trim()) ?? -1;
              return clientNameController.text.trim().isNotEmpty &&
                  phoneController.text.trim().isNotEmpty &&
                  serviceController.text.trim().isNotEmpty &&
                  duration >= 15 &&
                  duration <= 720 &&
                  price >= 0;
            }

            void refreshForm() => setSheetState(() {});

            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 1),
              );
              if (picked != null) {
                setSheetState(() => selectedDate = picked);
              }
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) {
                setSheetState(() => selectedTime = picked);
              }
            }

            final price = double.tryParse(priceController.text.trim()) ?? 0;
            final valid = canSubmit();
            final formNote = !valid
                ? 'Add a client, phone, service, valid duration, and non-negative price.'
                : createPaymentDue && price > 0
                ? 'This will create the booking and an unpaid Money item.'
                : 'This will create the booking and close the request.';

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SlateSheetFrame(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirm booking',
                          style: TextStyle(
                            color: AppColors.t1,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Check the details, then add it to your calendar.',
                          style: TextStyle(color: AppColors.t3),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgInteract,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              if (widget
                                      .request
                                      .preferredTimeText
                                      ?.isNotEmpty ==
                                  true)
                                _SheetSummaryRow(
                                  icon: LucideIcons.messageSquare,
                                  label: 'Asked for',
                                  value: widget.request.preferredTimeText!,
                                ),
                              if (widget.request.message?.isNotEmpty ==
                                  true) ...[
                                if (widget
                                        .request
                                        .preferredTimeText
                                        ?.isNotEmpty ==
                                    true)
                                  const SizedBox(height: 10),
                                _SheetSummaryRow(
                                  icon: LucideIcons.messageCircle,
                                  label: 'Message',
                                  value: widget.request.message!,
                                ),
                              ],
                              if (widget.request.preferredTimeText?.isEmpty !=
                                      false &&
                                  widget.request.message?.isEmpty != false)
                                const _SheetEmptyHint(
                                  text:
                                      'No extra message was included with this request.',
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SheetField(
                          controller: clientNameController,
                          label: 'Client name',
                          icon: LucideIcons.user,
                          keyboardType: TextInputType.name,
                          onChanged: (_) => refreshForm(),
                        ),
                        const SizedBox(height: 10),
                        _SheetField(
                          controller: phoneController,
                          label: 'Phone',
                          icon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => refreshForm(),
                        ),
                        const SizedBox(height: 10),
                        _SheetField(
                          controller: serviceController,
                          label: 'Service',
                          icon: LucideIcons.scissors,
                          keyboardType: TextInputType.text,
                          onChanged: (_) => refreshForm(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _SheetPickerButton(
                                icon: LucideIcons.calendar,
                                label: _formatSheetDate(selectedDate),
                                onTap: pickDate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SheetPickerButton(
                                icon: LucideIcons.clock3,
                                label: selectedTime.format(context),
                                onTap: pickTime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SheetField(
                                controller: durationController,
                                label: 'Duration mins',
                                icon: LucideIcons.timer,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => refreshForm(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SheetField(
                                controller: priceController,
                                label: 'Price',
                                icon: LucideIcons.banknote,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => refreshForm(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SheetField(
                          controller: locationController,
                          label: 'Location',
                          icon: LucideIcons.mapPin,
                          keyboardType: TextInputType.text,
                          onChanged: (_) => refreshForm(),
                        ),
                        const SizedBox(height: 10),
                        _SheetField(
                          controller: notesController,
                          label: 'Private booking note',
                          icon: LucideIcons.fileText,
                          keyboardType: TextInputType.multiline,
                          maxLines: 2,
                          onChanged: (_) => refreshForm(),
                        ),
                        if (price > 0) ...[
                          const SizedBox(height: 12),
                          _SheetSwitchRow(
                            title: 'Add a payment to collect',
                            subtitle:
                                'Links an unpaid Money item to the booking.',
                            value: createPaymentDue,
                            onChanged: (value) =>
                                setSheetState(() => createPaymentDue = value),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _SheetEmptyHint(text: formNote),
                        const SizedBox(height: 18),
                        SlateButton(
                          label: 'Create booking',
                          icon: LucideIcons.calendarCheck,
                          onPressed: valid
                              ? () => Navigator.pop(context, true)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) {
      clientNameController.dispose();
      phoneController.dispose();
      serviceController.dispose();
      durationController.dispose();
      priceController.dispose();
      locationController.dispose();
      notesController.dispose();
      return;
    }

    final duration = int.tryParse(durationController.text.trim()) ?? 60;
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final clientName = clientNameController.text.trim();
    final clientPhone = phoneController.text.trim();
    final serviceTitle = serviceController.text.trim();
    final location = locationController.text.trim();
    final extraNotes = notesController.text.trim();
    clientNameController.dispose();
    phoneController.dispose();
    serviceController.dispose();
    durationController.dispose();
    priceController.dispose();
    locationController.dispose();
    notesController.dispose();

    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .confirmBookingRequest(
            request: widget.request,
            startTime: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            ),
            durationMins: duration.clamp(15, 720),
            price: price,
            clientName: clientName,
            clientPhone: clientPhone,
            serviceTitle: serviceTitle,
            location: location,
            extraNotes: extraNotes,
            createPaymentDue: createPaymentDue,
          );
      ref.invalidate(bookingRequestsProvider);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(invoicesProvider);
      ref.invalidate(financeSummaryProvider);
      ref.invalidate(dashboardRevenueProvider);
      ref.invalidate(dashboardFocusProvider);
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking added to your calendar'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create booking: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _call() async {
    final phone = widget.request.phone.replaceAll(' ', '');
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pending = request.status == 'pending';
    final contacted = request.status == 'contacted';
    return Container(
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
              Expanded(
                child: Text(
                  request.name,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  request.phone,
                  style: const TextStyle(color: AppColors.t2),
                ),
              ),
              GestureDetector(
                onTap: _call,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.phone, size: 13, color: AppColors.t2),
                      SizedBox(width: 5),
                      Text(
                        'Call',
                        style: TextStyle(
                          color: AppColors.t2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (request.serviceName?.isNotEmpty == true ||
              request.preferredTimeText?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (request.serviceName?.isNotEmpty == true)
                  _InfoChip(
                    icon: LucideIcons.scissors,
                    label: request.serviceName!,
                  ),
                if (request.preferredTimeText?.isNotEmpty == true)
                  _InfoChip(
                    icon: LucideIcons.clock3,
                    label: request.preferredTimeText!,
                  ),
              ],
            ),
          ],
          if (request.message?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              request.message!,
              style: const TextStyle(color: AppColors.t3, height: 1.35),
            ),
          ],
          if (pending || contacted) ...[
            const SizedBox(height: 14),
            Column(
              children: [
                if (pending) ...[
                  _ActionButton(
                    label: 'Mark contacted',
                    variant: _RequestActionVariant.secondary,
                    loading: _saving,
                    onTap: () => _setStatus('contacted'),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Decline',
                        variant: _RequestActionVariant.destructiveQuiet,
                        loading: _saving,
                        onTap: _declineRequest,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Book',
                        variant: _RequestActionVariant.primary,
                        loading: _saving,
                        onTap: _confirmAsBooking,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _formatSheetDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _SheetPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetPickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgInteract,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.t3, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.t1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.t1, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.t3),
        prefixIcon: Icon(icon, color: AppColors.t3, size: 17),
      ),
    );
  }
}

class _SheetEmptyHint extends StatelessWidget {
  final String text;

  const _SheetEmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.t3, fontSize: 12, height: 1.32),
      ),
    );
  }
}

class _SheetSummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 16),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SheetSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.t3,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.green,
            activeTrackColor: AppColors.green.withValues(alpha: 0.28),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.t3),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _RequestActionVariant { primary, secondary, destructiveQuiet }

class _ActionButton extends StatelessWidget {
  final String label;
  final _RequestActionVariant variant;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.variant,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == _RequestActionVariant.primary;
    final isDestructive = variant == _RequestActionVariant.destructiveQuiet;
    final color = isPrimary
        ? AppColors.accentPrimaryStrong
        : isDestructive
        ? AppColors.error
        : AppColors.t2;
    final background = isPrimary
        ? AppColors.accentPrimaryStrong
        : isDestructive
        ? Colors.transparent
        : AppColors.t1.withValues(alpha: 0.06);
    final foreground = isPrimary ? AppColors.bg : color;
    final border = isPrimary
        ? Colors.transparent
        : isDestructive
        ? Colors.transparent
        : AppColors.border;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' => AppColors.success,
      'declined' => AppColors.error,
      'contacted' => AppColors.t2,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'confirmed' => 'Booked',
      'declined' => 'Declined',
      'contacted' => 'Contacted',
      _ => 'New',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyRequests({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.inbox, color: AppColors.t3, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.t1,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.t3),
            ),
          ],
        ),
      ),
    );
  }
}
