import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/payments/tap_to_pay_service.dart';
import '../../shared/repositories/stripe_payments_repository.dart';
import '../../shared/utils/currency_format.dart';
import '../../shared/widgets/slate_ui.dart';

String friendlyPaymentError(Object error) {
  final text = error.toString().replaceFirst(
    RegExp(r'^(?:Bad state|\w+(?:Exception)?):\s*'),
    '',
  );
  return text.isEmpty
      ? 'Payments are temporarily unavailable. Please try again.'
      : text;
}

enum PaymentSetupAction { viewOwed }

String contactlessUnavailableMessage(TargetPlatform platform) {
  if (platform == TargetPlatform.iOS) {
    return 'Available after Apple approves Workloop for Tap to Pay.';
  }
  return 'Contactless payments are not available on this phone yet.';
}

Future<bool> showPaymentCollectionSheet({
  required BuildContext context,
  required Payment payment,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: SlateTheme.of(context).scrim,
        builder: (_) => _PaymentCollectionSheet(payment: payment),
      ) ??
      false;
}

Future<PaymentSetupAction?> showPaymentSetupSheet({
  required BuildContext context,
  required String workspaceId,
}) {
  return showModalBottomSheet<PaymentSetupAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (_) => _PaymentCollectionSheet(workspaceId: workspaceId),
  );
}

class PaymentSetupCard extends StatelessWidget {
  final VoidCallback onTap;

  const PaymentSetupCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const Row(
        children: [
          Icon(
            LucideIcons.smartphoneNfc,
            color: AppColors.modFinance,
            size: 22,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get paid with Workloop',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Set up Stripe, send payment links, and manage payouts.',
                  style: TextStyle(
                    color: AppColors.t3,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 18),
        ],
      ),
    );
  }
}

class _PaymentCollectionSheet extends ConsumerStatefulWidget {
  final Payment? payment;
  final String? workspaceId;

  const _PaymentCollectionSheet({this.payment, this.workspaceId});

  @override
  ConsumerState<_PaymentCollectionSheet> createState() =>
      _PaymentCollectionSheetState();
}

class _PaymentCollectionSheetState
    extends ConsumerState<_PaymentCollectionSheet> {
  late Future<StripeAccountStatus> _status;
  late Future<TapToPayAvailability> _tapAvailability;
  Future<List<Map<String, dynamic>>>? _transactions;
  bool _working = false;
  bool _linkCopied = false;
  String? _error;

  String get _workspaceId =>
      widget.payment?.workspaceId ?? widget.workspaceId ?? '';

  @override
  void initState() {
    super.initState();
    _status = _repository.accountStatus(_workspaceId);
    _tapAvailability = tapToPayService.availability();
    if ((widget.payment?.stripeAmountPaid ?? 0) > 0) {
      _transactions = _repository.transactionsForInvoice(
        _workspaceId,
        widget.payment!.id,
      );
    }
  }

  StripePaymentsRepository get _repository =>
      ref.read(stripePaymentsRepositoryProvider);

  void _refreshStatus() {
    setState(() {
      _error = null;
      _status = _repository.accountStatus(_workspaceId);
    });
  }

  Future<void> _startOnboarding() async {
    await _run(() async {
      final link = await _repository.createOnboardingLink(_workspaceId);
      if (!await launchUrl(link, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open Stripe setup.');
      }
    });
  }

  Future<void> _openDashboard() async {
    await _run(() async {
      final link = await _repository.createDashboardLink(_workspaceId);
      if (!await launchUrl(link, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open Stripe.');
      }
    });
  }

  Future<void> _copyPaymentLink() async {
    final payment = widget.payment;
    if (payment == null) return;
    await _run(() async {
      final link = await _repository.createPaymentLink(
        workspaceId: payment.workspaceId,
        invoiceId: payment.id,
      );
      await Clipboard.setData(ClipboardData(text: link.url.toString()));
      if (!mounted) return;
      setState(() => _linkCopied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secure payment link copied')),
      );
    });
  }

  Future<void> _takeContactlessPayment() async {
    final payment = widget.payment;
    if (payment == null) return;
    await _run(() async {
      final availability = await tapToPayService.availability();
      if (!availability.supported) {
        throw StateError(
          'Tap to Pay is not enabled for this Workloop build yet. '
          'You can still copy a secure payment link.',
        );
      }
      final request = await _repository.createTerminalPayment(
        workspaceId: payment.workspaceId,
        invoiceId: payment.id,
      );
      final result = await tapToPayService.collect(
        clientSecret: request.clientSecret,
        locationId: request.locationId,
        connectionTokenLoader: () =>
            _repository.createConnectionToken(payment.workspaceId),
      );
      if (result.status != 'succeeded') {
        throw StateError('Stripe is still processing this payment.');
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    });
  }

  Future<void> _refundTransaction(Map<String, dynamic> transaction) async {
    final amount = (transaction['amount_minor'] as num?)?.toInt() ?? 0;
    final refunded =
        (transaction['amount_refunded_minor'] as num?)?.toInt() ?? 0;
    final refundable = amount - refunded;
    if (refundable <= 0) return;
    final controller = TextEditingController(
      text: (refundable / 100).toStringAsFixed(2),
    );
    final confirmed = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refund card payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Up to ${formatPounds(refundable / 100)} can be refunded.'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Refund amount (£)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              final minor = value == null ? 0 : (value * 100).round();
              if (minor <= 0 || minor > refundable) return;
              Navigator.pop(dialogContext, minor);
            },
            child: const Text('Refund'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed == null || !mounted) return;
    await _run(() async {
      await _repository.refund(
        workspaceId: _workspaceId,
        transactionId: transaction['id'] as String,
        amountMinor: confirmed,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyPaymentError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    return SlateSheetFrame(
      child: SafeArea(
        top: false,
        child: FutureBuilder<StripeAccountStatus>(
          future: _status,
          builder: (context, snapshot) {
            final status = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Get paid',
                        style: TextStyle(
                          color: AppColors.t1,
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (status != null) _ModeLabel(mode: status.mode),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (payment == null)
                  const Text(
                    'Set up once, then collect from each unpaid Money item.',
                    style: TextStyle(
                      color: AppColors.t3,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  )
                else
                  _PaymentSummary(payment: payment),
                const SizedBox(height: AppSpacing.lg),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SlateLoadingBlock(height: 150, radius: AppRadius.md)
                else if (snapshot.hasError)
                  SlateErrorState(
                    message: 'Could not check payment setup',
                    onRetry: _refreshStatus,
                  )
                else if (status == null || !status.ready)
                  _buildSetup(status)
                else
                  _buildReady(status),
                if (status?.mode == 'test') ...[
                  const SizedBox(height: AppSpacing.md),
                  const _TestModeNote(),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Stripe processing fees apply. Workloop adds no platform fee. Card details never pass through Workloop.',
                  style: TextStyle(
                    color: AppColors.t3,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SlateButton(
                  label: 'Close',
                  secondary: true,
                  onPressed: _working ? null : () => Navigator.pop(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetup(StripeAccountStatus? status) {
    final started = status?.connected == true;
    return Column(
      children: [
        SlateButton(
          label: _working
              ? 'Opening Stripe...'
              : started
              ? 'Continue Stripe setup'
              : 'Set up secure payments',
          icon: LucideIcons.shieldCheck,
          onPressed: _working ? null : _startOnboarding,
        ),
        if (started) ...[
          const SizedBox(height: AppSpacing.sm),
          SlateButton(
            label: 'I’ve finished setup',
            secondary: true,
            onPressed: _working ? null : _refreshStatus,
          ),
        ],
      ],
    );
  }

  Widget _buildReady(StripeAccountStatus status) {
    final payment = widget.payment;
    if (payment == null) {
      return Column(
        children: [
          const _PaymentStatusRow(
            icon: LucideIcons.circleCheck,
            iconColor: AppColors.success,
            title: 'Stripe is connected',
            detail: 'Secure payment links and payouts are ready.',
          ),
          const SizedBox(height: AppSpacing.lg),
          SlateButton(
            label: 'View payments to collect',
            icon: LucideIcons.arrowRight,
            onPressed: _working
                ? null
                : () => Navigator.pop(context, PaymentSetupAction.viewOwed),
          ),
          const SizedBox(height: AppSpacing.sm),
          SlateButton(
            label: 'Open Stripe payouts',
            secondary: true,
            onPressed: _working ? null : _openDashboard,
          ),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<TapToPayAvailability>(
            future: _tapAvailability,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SlateLoadingBlock(
                  height: 64,
                  radius: AppRadius.md,
                );
              }
              final available = snapshot.data?.supported == true;
              return _PaymentStatusRow(
                icon: LucideIcons.smartphoneNfc,
                iconColor: available ? AppColors.success : AppColors.t3,
                title: 'Contactless payments',
                detail: available
                    ? 'Ready on this phone.'
                    : contactlessUnavailableMessage(Theme.of(context).platform),
                status: available ? 'Ready' : 'Pending',
              );
            },
          ),
        ],
      );
    }
    if (payment.stripeAmountPaid > 0 && payment.outstandingAmount <= 0) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SlateLoadingBlock(height: 112, radius: AppRadius.md);
          }
          final transactions = snapshot.data ?? const [];
          final refundable = transactions.where((transaction) {
            final amount = (transaction['amount_minor'] as num?)?.toInt() ?? 0;
            final refunded =
                (transaction['amount_refunded_minor'] as num?)?.toInt() ?? 0;
            return amount > refunded &&
                const [
                  'succeeded',
                  'partially_refunded',
                ].contains(transaction['status']);
          }).toList();
          if (refundable.isEmpty) {
            return const SlateSurface(
              child: Text(
                'This card payment has been fully refunded.',
                style: TextStyle(color: AppColors.t2, fontSize: 13),
              ),
            );
          }
          return SlateButton(
            label: _working ? 'Refunding...' : 'Refund card payment',
            icon: LucideIcons.undo2,
            secondary: true,
            onPressed: _working
                ? null
                : () => _refundTransaction(refundable.first),
          );
        },
      );
    }
    return FutureBuilder<TapToPayAvailability>(
      future: _tapAvailability,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SlateLoadingBlock(height: 132, radius: AppRadius.md);
        }
        return _buildCollectionMethods(
          contactlessAvailable: snapshot.data?.supported == true,
        );
      },
    );
  }

  Widget _buildCollectionMethods({required bool contactlessAvailable}) {
    final linkButton = SlateButton(
      label: _linkCopied ? 'Payment link copied' : 'Copy secure payment link',
      icon: _linkCopied ? LucideIcons.circleCheck : LucideIcons.link,
      secondary: contactlessAvailable,
      onPressed: _working ? null : _copyPaymentLink,
    );
    return Column(
      children: [
        if (contactlessAvailable) ...[
          SlateButton(
            label: _working
                ? 'Preparing reader...'
                : 'Take contactless payment',
            icon: LucideIcons.smartphoneNfc,
            onPressed: _working ? null : _takeContactlessPayment,
          ),
          const SizedBox(height: AppSpacing.sm),
          linkButton,
        ] else ...[
          linkButton,
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Send the link by message or email. Stripe handles the card securely.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.t3, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PaymentStatusRow(
            icon: LucideIcons.smartphoneNfc,
            iconColor: AppColors.t3,
            title: 'Contactless payments',
            detail: contactlessUnavailableMessage(Theme.of(context).platform),
            status: 'Pending',
          ),
        ],
      ],
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final Payment payment;

  const _PaymentSummary({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatPounds(payment.outstandingAmount),
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Due from ${payment.clientName ?? 'your client'}',
            style: const TextStyle(color: AppColors.t3, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String detail;
  final String? status;

  const _PaymentStatusRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.detail,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens.divider),
          bottom: BorderSide(color: tokens.divider),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.t3,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              status!,
              style: TextStyle(
                color: status == 'Ready' ? AppColors.success : AppColors.t3,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TestModeNote extends StatelessWidget {
  const _TestModeNote();

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Text(
        'Test mode — no real money will move.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.t2,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  final String mode;

  const _ModeLabel({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        mode == 'live' ? 'Live' : 'Test mode',
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
