import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/workloop_app_info.dart';
import '../../shared/repositories/supabase_client_provider.dart';
import '../../shared/widgets/slate_ui.dart';
import '../settings/support_screen.dart';
import '../settings/widgets/settings_account_tab.dart';
import 'store_purchase_service.dart';
import 'subscription_access.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key, this.canClose = true});
  final bool canClose;
  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _loadedForUserId;
  Future<void> _openUrl(String url) async {
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      /* Keep the user on the current page with a useful retry. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open that page. Please try again.'),
        ),
      );
    }
  }

  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return const SizedBox.shrink();
    final access = ref.watch(subscriptionAccessProvider(userId));
    final service = ref.watch(storePurchaseServiceProvider(userId));
    final value = access.value;
    final apple = defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb;
    final salesEnabled =
        value != null &&
        !access.hasError &&
        !access.isLoading &&
        !value.isLifetime &&
        (apple ? value.appleSalesEnabled : value.googleSalesEnabled);
    if (salesEnabled && _loadedForUserId != userId) {
      _loadedForUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) service.load();
      });
    }
    final tokens = SlateTheme.of(context);
    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            AppSpacing.screenTop,
            AppSpacing.pageX,
            AppSpacing.xxl,
          ),
          children: [
            if (widget.canClose)
              const WorkloopRouteHeader(title: 'Your Workloop plan')
            else
              Text(
                'Your Workloop plan',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            const SizedBox(height: AppSpacing.lg),
            if (access.isLoading && value == null)
              const Center(child: CircularProgressIndicator())
            else if (access.hasError) ...[
              const Text(
                'We could not check your plan. Please check your connection.',
              ),
              WorkloopTextButton(
                label: 'Try again',
                onPressed: () =>
                    ref.invalidate(subscriptionAccessProvider(userId)),
              ),
            ] else if (value != null) ...[
              Text(value.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value.isLifetime
                    ? 'Thank you for helping shape Workloop. Your beta account has free lifetime access. There is nothing to pay and no subscription to cancel.'
                    : value.state == 'beta'
                    ? 'You can keep using Workloop during the beta. No payment is needed.'
                    : value.state == 'trial'
                    ? 'Enjoy all of Workloop for 30 days. No payment details are needed for the trial. When it ends, choose a plan to continue. You will not be charged automatically for the trial.'
                    : value.state == 'subscribed'
                    ? 'Your plan keeps your business connected. Manage renewal, cancellation and billing through the store where you subscribed.'
                    : 'Your trial has ended. Choose a plan to keep working. Your records are safe, and export and account controls remain available.',
                style: const TextStyle(height: 1.5),
              ),
            ],
            if (value != null &&
                !value.isLifetime &&
                value.state != 'subscribed' &&
                value.state != 'beta') ...[
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'One plan. Everything included.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Clients, bookings, tasks, notes, money and your business booking page. Pick the billing period that suits you.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<StorePurchaseState>(
                valueListenable: service.state,
                builder: (context, purchase, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (salesEnabled && purchase.available)
                      ...purchase.products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: WorkloopPrimaryButton(
                            label: product.id == WorkloopPlans.yearlyId
                                ? '${product.price} / year'
                                : '${product.price} / month',
                            onPressed:
                                purchase.busy || purchase.awaitingApproval
                                ? null
                                : () => service.buy(product),
                            secondary: product.id == WorkloopPlans.yearlyId,
                          ),
                        ),
                      )
                    else if (!salesEnabled)
                      const Text(
                        'Plans are being prepared for launch: £14.99 a month or £149.99 a year. Purchasing is not available yet.',
                      ),
                    if (salesEnabled && !purchase.available && !purchase.busy)
                      WorkloopTextButton(
                        label: 'Load plans',
                        onPressed: service.load,
                      ),
                    if (salesEnabled)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          'Your store confirms the price before payment. A subscription starts when you purchase and renews automatically until cancelled. Cancel in your store subscription settings. The yearly plan is billed in full once a year.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            ValueListenableBuilder<StorePurchaseState>(
              valueListenable: service.state,
              builder: (context, purchase, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (purchase.busy)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (purchase.message != null)
                    Text(
                      purchase.message!,
                      style: const TextStyle(height: 1.5),
                    ),
                  WorkloopTextButton(
                    label: 'Restore purchases',
                    onPressed: purchase.busy ? null : service.restore,
                  ),
                ],
              ),
            ),
            WorkloopTextButton(
              label: 'Manage store subscription',
              onPressed: () => _openUrl(
                (value?.platform == 'apple' ||
                        (value?.platform == null && apple))
                    ? 'https://apps.apple.com/account/subscriptions'
                    : 'https://play.google.com/store/account/subscriptions',
              ),
            ),
            WorkloopTextButton(
              label: 'Terms of use',
              onPressed: () => _openUrl(WorkloopAppInfo.termsUrl),
            ),
            WorkloopTextButton(
              label: 'Privacy policy',
              onPressed: () => _openUrl(WorkloopAppInfo.privacyUrl),
            ),
            if (!widget.canClose) ...[
              WorkloopTextButton(
                label: 'Export data or delete account',
                onPressed: () => _open(
                  Scaffold(
                    appBar: AppBar(title: const Text('Privacy & data')),
                    body: const SettingsAccountTab(showDataOnly: true),
                  ),
                ),
              ),
              WorkloopTextButton(
                label: 'Manage account or sign out',
                onPressed: () => _open(
                  Scaffold(
                    appBar: AppBar(title: const Text('Your account')),
                    body: const SettingsAccountTab(),
                  ),
                ),
              ),
              WorkloopTextButton(
                label: 'Help & support',
                onPressed: () => _open(const SupportScreen()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
