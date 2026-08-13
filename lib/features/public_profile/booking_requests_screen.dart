import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
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
  return ref.watch(profileRepositoryProvider).bookingRequests(workspaceId);
});

enum _RequestView { active, pending, closed }

String bookingRequestEditablePrice(num price) {
  if (!price.isFinite || price < 0) return '0';
  return price.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

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
                  child: WorkloopRouteHeader(
                    title: 'Booking requests',
                    backSemanticLabel: 'Back to bookings',
                  ),
                ),
                requests.maybeWhen(
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    final pending = items
                        .where((item) => item.status == 'pending')
                        .length;
                    final active = items
                        .where(
                          (item) =>
                              item.status == 'pending' ||
                              item.status == 'contacted',
                        )
                        .length;
                    final closed = items
                        .where(
                          (item) =>
                              item.status == 'confirmed' ||
                              item.status == 'declined',
                        )
                        .length;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageX,
                        0,
                        AppSpacing.pageX,
                        AppSpacing.md,
                      ),
                      child: WorkloopNavigationControl<_RequestView>(
                        selected: _view,
                        emphasized: false,
                        onChanged: (view) => setState(() => _view = view),
                        segments: [
                          WorkloopSegment(
                            value: _RequestView.active,
                            label: 'Active',
                            badge: active > 0 ? '$active' : null,
                          ),
                          WorkloopSegment(
                            value: _RequestView.pending,
                            label: 'New',
                            badge: pending > 0 ? '$pending' : null,
                          ),
                          WorkloopSegment(
                            value: _RequestView.closed,
                            label: 'Closed',
                            badge: closed > 0 ? '$closed' : null,
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
                    error: (_, _) => _EmptyRequests(
                      title: 'Could not load requests',
                      subtitle: 'Check your connection, then try again.',
                      onRetry: () => ref.invalidate(bookingRequestsProvider),
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
                            _RequestView.closed => 'No closed requests',
                            _RequestView.active => 'No active requests',
                          },
                          subtitle: 'Switch filters to review other requests.',
                        );
                      }
                      return RefreshIndicator(
                        color: AppColors.green,
                        onRefresh: () async =>
                            ref.invalidate(bookingRequestsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageX,
                            0,
                            AppSpacing.pageX,
                            40,
                          ),
                          itemBuilder: (context, index) => _RequestRow(
                            request: filtered[index],
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingRequestDetailScreen(
                                  request: filtered[index],
                                ),
                              ),
                            ),
                          ),
                          separatorBuilder: (_, _) =>
                              const WorkloopDivider(margin: EdgeInsets.zero),
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
        _RequestView.closed =>
          item.status == 'confirmed' || item.status == 'declined',
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

class _RequestRow extends StatelessWidget {
  final BookingRequest request;
  final VoidCallback onTap;

  const _RequestRow({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final contextLine = [
      if (request.serviceName?.trim().isNotEmpty == true)
        request.serviceName!.trim(),
      if (request.preferredTimeText?.trim().isNotEmpty == true)
        request.preferredTimeText!.trim(),
    ].join(' · ');
    final initial = request.name.trim().isEmpty
        ? '?'
        : request.name.trim()[0].toUpperCase();
    return WorkloopListRow(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      showDivider: false,
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.modBg,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.t1,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        request.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        contextLine.isEmpty ? request.phone : contextLine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusBadge(status: request.status),
          const SizedBox(width: AppSpacing.xs),
          const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
        ],
      ),
    );
  }
}

class BookingRequestDetailScreen extends StatelessWidget {
  final BookingRequest request;

  const BookingRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    AppSpacing.lg,
                    AppSpacing.pageX,
                    AppSpacing.xl,
                  ),
                  child: const WorkloopRouteHeader(
                    title: 'Booking request',
                    backSemanticLabel: 'Back to booking requests',
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageX,
                      0,
                      AppSpacing.pageX,
                      AppSpacing.xxl,
                    ),
                    child: _RequestCard(
                      request: request,
                      detailMode: true,
                      closeAfterAction: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final BookingRequest request;
  final bool detailMode;
  final bool closeAfterAction;

  const _RequestCard({
    required this.request,
    this.detailMode = false,
    this.closeAfterAction = false,
  });

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
          .updateBookingRequestStatus(
            requestId: widget.request.id,
            workspaceId: widget.request.workspaceId,
            status: status,
          );
      ref.invalidate(bookingRequestsProvider);
      if (widget.closeAfterAction && mounted) Navigator.pop(context);
    } on BookingRequestStateException catch (error) {
      ref.invalidate(bookingRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The request could not be updated. Check your connection and try again.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                fontWeight: FontWeight.w600,
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
    final emailController = TextEditingController(text: widget.request.email);
    final serviceController = TextEditingController(
      text: widget.request.serviceName?.trim().isNotEmpty == true
          ? widget.request.serviceName!.trim()
          : 'Booking request',
    );
    final durationController = TextEditingController(
      text: (widget.request.serviceDurationMins ?? 60).toString(),
    );
    final priceController = TextEditingController(
      text: bookingRequestEditablePrice(widget.request.servicePrice ?? 0),
    );
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    var createPaymentDue = (widget.request.servicePrice ?? 0) > 0;
    var submitting = false;
    String? submissionError;
    final sheetCloseDuration = AppMotion.responsive(
      context,
      AppMotion.deliberate,
    );

    final confirmation = await showModalBottomSheet<BookingRequestConfirmationOutcome>(
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
              final picked = await showWorkloopDatePicker(
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
              final picked = await showWorkloopTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) {
                setSheetState(() => selectedTime = picked);
              }
            }

            Future<void> submit() async {
              if (submitting || !canSubmit()) return;
              setSheetState(() {
                submitting = true;
                submissionError = null;
              });
              final duration =
                  int.tryParse(durationController.text.trim()) ?? 60;
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final startTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              Future<BookingRequestConfirmationOutcome> confirm({
                bool enforceWorkingHours = true,
              }) {
                return ref
                    .read(profileRepositoryProvider)
                    .confirmBookingRequest(
                      request: widget.request,
                      startTime: startTime,
                      durationMins: duration.clamp(15, 720),
                      price: price,
                      clientName: clientNameController.text.trim(),
                      clientPhone: phoneController.text.trim(),
                      clientEmail:
                          isValidBookingRequestEmail(widget.request.email)
                          ? widget.request.email.trim()
                          : null,
                      serviceTitle: serviceController.text.trim(),
                      location: locationController.text.trim(),
                      extraNotes: notesController.text.trim(),
                      createPaymentDue: createPaymentDue,
                      enforceWorkingHours: enforceWorkingHours,
                    );
              }

              try {
                try {
                  final outcome = await confirm();
                  if (context.mounted) Navigator.pop(context, outcome);
                } on AppointmentScheduleException catch (error) {
                  if (error.issue != AppointmentScheduleIssue.workingHours) {
                    rethrow;
                  }
                  if (!context.mounted) return;
                  final proceed = await showWorkloopOutsideHoursConfirmation(
                    context,
                    detail: error.message,
                  );
                  if (!proceed) {
                    if (context.mounted) {
                      setSheetState(() => submitting = false);
                    }
                    return;
                  }
                  final outcome = await confirm(enforceWorkingHours: false);
                  if (context.mounted) Navigator.pop(context, outcome);
                }
              } on AppointmentScheduleException catch (error) {
                if (context.mounted) {
                  setSheetState(() {
                    submitting = false;
                    submissionError = error.message;
                  });
                }
              } on BookingRequestStateException catch (error) {
                ref.invalidate(bookingRequestsProvider);
                if (context.mounted) {
                  setSheetState(() {
                    submitting = false;
                    submissionError = error.message;
                  });
                }
              } catch (_) {
                if (context.mounted) {
                  setSheetState(() {
                    submitting = false;
                    submissionError =
                        'The booking was not created. Check your connection and try again.';
                  });
                }
              }
            }

            final price = double.tryParse(priceController.text.trim()) ?? 0;
            final valid = canSubmit();
            final formNote = !valid
                ? 'Add a client, phone, service, valid duration, and non-negative price.'
                : createPaymentDue && price > 0
                ? 'This will create the booking and an unpaid Money item.'
                : 'This will create the booking and close the request.';

            return PopScope(
              canPop: !submitting,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SlateSheetFrame(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          (MediaQuery.sizeOf(context).height -
                              MediaQuery.viewInsetsOf(context).bottom) *
                          0.68,
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
                              fontWeight: FontWeight.w600,
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
                            controller: emailController,
                            label: 'Customer email',
                            icon: LucideIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: true,
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
                          _ResponsiveSheetPair(
                            first: _SheetPickerButton(
                              icon: LucideIcons.calendar,
                              label: _formatSheetDate(selectedDate),
                              onTap: pickDate,
                            ),
                            second: _SheetPickerButton(
                              icon: LucideIcons.clock3,
                              label: selectedTime.format(context),
                              onTap: pickTime,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ResponsiveSheetPair(
                            first: _SheetField(
                              controller: durationController,
                              label: 'Duration mins',
                              icon: LucideIcons.timer,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => refreshForm(),
                            ),
                            second: _SheetField(
                              controller: priceController,
                              label: 'Price',
                              icon: LucideIcons.banknote,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => refreshForm(),
                            ),
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
                          if (submissionError != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Semantics(
                              liveRegion: true,
                              container: true,
                              label: submissionError,
                              child: _SheetSubmissionError(
                                message: submissionError!,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SlateButton(
                            label: submitting
                                ? 'Creating booking…'
                                : 'Create booking',
                            icon: submitting ? null : LucideIcons.calendarCheck,
                            onPressed: valid && !submitting ? submit : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // The modal future completes when pop begins; keep controllers alive for
    // the closing transition so its text fields cannot rebuild after disposal.
    Future<void>.delayed(sheetCloseDuration, () {
      clientNameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      serviceController.dispose();
      durationController.dispose();
      priceController.dispose();
      locationController.dispose();
      notesController.dispose();
    });
    if (confirmation == null) return;

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
      final successMessage = bookingRequestConfirmationMessage(
        confirmation.confirmationEmailStatus,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor:
              confirmation.confirmationEmailStatus ==
                  BookingRequestConfirmationEmailStatus.failed
              ? AppColors.warning
              : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.closeAfterAction) Navigator.pop(context);
    }
  }

  Future<void> _call() async {
    final phone = widget.request.phone.replaceAll(' ', '');
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _email() async {
    await launchUrl(Uri(scheme: 'mailto', path: widget.request.email));
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pending = request.status == 'pending';
    final contacted = request.status == 'contacted';
    return Container(
      padding: widget.detailMode
          ? EdgeInsets.zero
          : const EdgeInsets.all(AppSpacing.md),
      decoration: widget.detailMode
          ? null
          : BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          if (isValidBookingRequestEmail(request.email)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.t2),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Email ${request.name}',
                  onTap: _email,
                  child: ExcludeSemantics(
                    child: OutlinedButton.icon(
                      onPressed: _email,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.t2,
                        minimumSize: const Size(0, AppSpacing.minTouch),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      icon: const Icon(LucideIcons.mail, size: 14),
                      label: const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  request.phone,
                  style: const TextStyle(color: AppColors.t2),
                ),
              ),
              Semantics(
                button: true,
                label: 'Call ${request.name}',
                onTap: _call,
                child: ExcludeSemantics(
                  child: OutlinedButton.icon(
                    onPressed: _call,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.t2,
                      minimumSize: const Size(0, AppSpacing.minTouch),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(LucideIcons.phone, size: 14),
                    label: const Text(
                      'Call',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

String bookingRequestConfirmationMessage(
  BookingRequestConfirmationEmailStatus status,
) => switch (status) {
  BookingRequestConfirmationEmailStatus.sent =>
    'Booking confirmed and confirmation email sent.',
  BookingRequestConfirmationEmailStatus.pending =>
    'Booking confirmed. The confirmation email is queued.',
  BookingRequestConfirmationEmailStatus.failed =>
    'Booking confirmed, but the email could not be sent. Contact the customer directly.',
  BookingRequestConfirmationEmailStatus.notApplicable =>
    'Booking confirmed. No email was available for confirmation.',
};

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
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveSheetPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsiveSheetPair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(14);
        final stacked = constraints.maxWidth < 360 || scaledBody > 18;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 10), second],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.t1, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.t3),
        prefixIcon: Icon(icon, color: AppColors.t3, size: 17),
      ),
    );
  }
}

class _SheetSubmissionError extends StatelessWidget {
  final String message;

  const _SheetSubmissionError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.error, size: 17),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
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
              fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w600,
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
          Switch.adaptive(value: value, onChanged: onChanged),
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
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - (AppSpacing.pageX * 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgInteract,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.t3),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.t2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
    final tokens = SlateTheme.of(context);
    final isPrimary = variant == _RequestActionVariant.primary;
    final isDestructive = variant == _RequestActionVariant.destructiveQuiet;
    final color = isPrimary
        ? tokens.primaryAction
        : isDestructive
        ? AppColors.error
        : AppColors.t2;
    final background = isPrimary
        ? tokens.primaryAction
        : isDestructive
        ? Colors.transparent
        : AppColors.t1.withValues(alpha: 0.06);
    final foreground = isPrimary ? tokens.onPrimaryAction : color;
    final border = isPrimary
        ? Colors.transparent
        : isDestructive
        ? Colors.transparent
        : AppColors.border;
    return Semantics(
      button: true,
      enabled: !loading,
      label: label,
      onTap: loading ? null : onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: loading ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
        borderRadius: BorderRadius.circular(AppRadius.capsule),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _EmptyRequests({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.inbox, color: AppColors.t3, size: 38),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.t3),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    WorkloopTextButton(label: 'Try again', onPressed: onRetry),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
