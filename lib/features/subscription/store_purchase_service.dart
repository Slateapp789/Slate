import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/repositories/supabase_client_provider.dart';
import 'subscription_access.dart';

class StorePurchaseState {
  const StorePurchaseState({
    this.busy = false,
    this.products = const [],
    this.message,
    this.available = false,
    this.awaitingApproval = false,
  });
  final bool busy, available;
  final bool awaitingApproval;
  final List<ProductDetails> products;
  final String? message;
}

final storePurchaseServiceProvider = Provider.autoDispose
    .family<StorePurchaseService, String>((ref, userId) {
      final service = StorePurchaseService(
        ref.watch(supabaseClientProvider),
        userId,
        onVerified: () => ref.invalidate(subscriptionAccessProvider(userId)),
      );
      ref.onDispose(service.dispose);
      return service;
    });

/// The store owns charges. Supabase verifies the signed transaction and owns
/// access. A local purchase callback alone never unlocks a subscription.
class StorePurchaseService {
  StorePurchaseService(
    this.client,
    this.userId, {
    required this.onVerified,
    InAppPurchase? store,
  }) : store = store ?? InAppPurchase.instance {
    if (_supported) {
      _subscription = this.store.purchaseStream.listen(
        (purchases) {
          _pending = _pending
              .then((_) async {
                for (final purchase in purchases) {
                  await _handle(purchase);
                }
              })
              .catchError((Object _) {
                _show(
                  'Could not confirm the purchase. Please restore purchases.',
                  awaitingApproval: state.value.awaitingApproval,
                );
              });
        },
        onError: (Object _) {
          _show(
            'The store could not connect. Please try again.',
            awaitingApproval: state.value.awaitingApproval,
          );
        },
      );
    }
  }
  final SupabaseClient client;
  final String userId;
  final VoidCallback onVerified;
  final InAppPurchase store;
  final state = ValueNotifier(const StorePurchaseState());
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> _pending = Future.value();
  final _verifiedTransactions = <String, bool>{};
  final _completedTransactions = <String>{};
  bool _disposed = false;
  int _activity = 0;
  bool get _supported =>
      !kIsWeb &&
      {
        TargetPlatform.iOS,
        TargetPlatform.android,
      }.contains(defaultTargetPlatform);
  bool get _current => !_disposed && client.auth.currentUser?.id == userId;

  void _show(
    String? message, {
    bool busy = false,
    bool awaitingApproval = false,
    bool? available,
    List<ProductDetails>? products,
  }) {
    if (!_current) return;
    state.value = StorePurchaseState(
      message: message,
      busy: busy,
      awaitingApproval: awaitingApproval,
      available: available ?? state.value.available,
      products: products ?? state.value.products,
    );
  }

  Future<void> load() async {
    if (!_current || state.value.busy || state.value.awaitingApproval) return;
    final activity = _activity;
    _show(null, busy: true);
    try {
      if (!_supported ||
          !await store.isAvailable().timeout(const Duration(seconds: 12))) {
        if (!_current || activity != _activity) return;
        _show(
          'The app store is unavailable. Please try again later.',
          available: false,
          products: const [],
        );
        return;
      }
      final response = await store
          .queryProductDetails(WorkloopPlans.productIds)
          .timeout(const Duration(seconds: 20));
      if (!_current || activity != _activity) return;
      if (response.error != null || response.productDetails.isEmpty) {
        _show(
          'Plans are not available in the store yet. Your existing access is unchanged.',
          available: false,
          products: const [],
        );
        return;
      }
      final products =
          response.productDetails
              .where((p) => WorkloopPlans.productIds.contains(p.id))
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      _show(
        products.isEmpty
            ? 'No Workloop plans were returned by the store.'
            : null,
        available: products.isNotEmpty,
        products: products,
      );
    } catch (_) {
      if (!_current || activity != _activity) return;
      _show(
        'Could not load plans. Check your connection and try again.',
        available: false,
        products: const [],
      );
    }
  }

  Future<void> buy(ProductDetails product) async {
    if (!_current ||
        state.value.busy ||
        state.value.awaitingApproval ||
        !state.value.available ||
        !state.value.products.any((p) => p.id == product.id)) {
      return;
    }
    final activity = ++_activity;
    _show('Waiting for the app store…', busy: true);
    try {
      // UUID associates Apple's signed transaction with this Workloop account.
      final started = await store
          .buyNonConsumable(
            purchaseParam: PurchaseParam(
              productDetails: product,
              applicationUserName: userId,
            ),
          )
          .timeout(const Duration(seconds: 30));
      if (!started && activity == _activity) {
        _show('The purchase did not start. Please try again.');
      }
    } catch (_) {
      if (activity != _activity) return;
      _show('No purchase was confirmed. Please try again.');
    }
  }

  Future<void> restore() async {
    if (!_current || state.value.busy) return;
    if (!_supported) {
      _show('Restore purchases in Workloop on your iPhone or Android device.');
      return;
    }
    final activity = ++_activity;
    // An explicit restore asks the server again: a previously seen receipt can
    // now be expired or revoked. Ordinary duplicate stream events stay deduped.
    _verifiedTransactions.clear();
    // Restoring is safe while approval is pending, but an empty result or a
    // connection failure cannot cancel that purchase. Only a terminal store
    // event clears the approval state.
    _show(
      'Checking your purchases…',
      busy: true,
      awaitingApproval: state.value.awaitingApproval,
    );
    try {
      await store
          .restorePurchases(applicationUserName: userId)
          .timeout(const Duration(seconds: 25));
      await _pending;
      if (_current) {
        if (state.value.busy) {
          _show(
            state.value.awaitingApproval
                ? 'No additional purchases were found. Your payment is still awaiting approval.'
                : 'No additional purchases were found. Your access is unchanged.',
            awaitingApproval: state.value.awaitingApproval,
          );
        }
      }
    } catch (_) {
      if (activity != _activity) return;
      _show(
        state.value.awaitingApproval
            ? 'Could not restore purchases. Your payment is still awaiting approval; try restoring again later.'
            : 'Could not restore purchases. Please try again.',
        awaitingApproval: state.value.awaitingApproval,
      );
    }
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    if (!_current || !WorkloopPlans.productIds.contains(purchase.productID)) {
      return;
    }
    _activity++;
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _show(
          'Waiting for payment approval. Your access is unchanged.',
          awaitingApproval: true,
        );
        return;
      case PurchaseStatus.canceled:
        _show('Purchase cancelled. Your access is unchanged.');
        return;
      case PurchaseStatus.error:
        _show('The store could not complete the purchase. Please try again.');
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final signedTransaction =
            purchase.verificationData.serverVerificationData;
        // A store callback is not evidence of entitlement. Empty verification
        // data must remain unfinished so the store can redeliver it later.
        if (signedTransaction.trim().isEmpty) {
          _show(
            'The store did not return a receipt. Use Restore purchases to retry.',
          );
          return;
        }
        final key =
            '${purchase.productID}:${purchase.purchaseID ?? ''}:$signedTransaction';
        _show('Confirming your purchase…', busy: true);
        try {
          if (!_verifiedTransactions.containsKey(key)) {
            final accessToken = client.auth.currentSession?.accessToken;
            if (accessToken == null) throw StateError('Signed out');
            final response = await client.functions
                .invoke(
                  'workloop-subscription',
                  headers: {'Authorization': 'Bearer $accessToken'},
                  body: {
                    'platform': defaultTargetPlatform == TargetPlatform.iOS
                        ? 'apple'
                        : 'google',
                    'signedTransaction': signedTransaction,
                  },
                )
                .timeout(const Duration(seconds: 25));
            if (!_current) return;
            if (response.status != 200 ||
                response.data is! Map ||
                response.data['verified'] != true) {
              throw StateError('Not verified');
            }
            _verifiedTransactions[key] =
                response.data['environment'] == 'Sandbox';
            onVerified();
          }
          if (!_current) return;
          if (purchase.pendingCompletePurchase &&
              !_completedTransactions.contains(key)) {
            try {
              await store
                  .completePurchase(purchase)
                  .timeout(const Duration(seconds: 12));
              if (!_current) return;
              _completedTransactions.add(key);
            } catch (_) {
              _show(
                'Your purchase was verified, but the store could not finish confirming it. Do not buy again; use Restore purchases to retry.',
              );
              return;
            }
          }
          if (!_current) return;
          _show(
            _verifiedTransactions[key] == true
                ? 'Test purchase verified. No real payment was taken.'
                : 'Purchase verified. Your current plan details are shown here.',
          );
        } catch (_) {
          _show(
            'Your purchase is awaiting verification. Do not buy again; use Restore purchases to retry.',
          );
        }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription?.cancel());
    state.dispose();
  }
}
