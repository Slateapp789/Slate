import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:workloop/features/subscription/store_purchase_service.dart';
import 'package:workloop/features/subscription/subscription_access.dart';

import 'support/subscription_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SubscriptionBackend backend;
  late FakeSubscriptionStore store;
  late StorePurchaseService service;
  late int verified;
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    backend = SubscriptionBackend();
    await backend.account();
    store = FakeSubscriptionStore();
    verified = 0;
    service = StorePurchaseService(
      backend.client,
      subscriptionUser,
      onVerified: () => verified++,
      store: store,
    );
  });
  tearDown(() async {
    service.dispose();
    await store.events.close();
    await backend.client.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'store pricing and purchase bind to the signed-in Workloop account',
    () async {
      await service.load();
      expect(service.state.value.available, isTrue);
      expect(service.state.value.products.map((p) => p.price), [
        '£14.99',
        '£149.99',
      ]);
      await service.buy(service.state.value.products.first);
      expect(store.buys.single.applicationUserName, subscriptionUser);
      expect(verified, 0);
      expect(store.completions, isEmpty);
    },
  );

  test('late product loading cannot clear a newer pending approval', () async {
    store.queryPending = Completer<void>();
    final loading = service.load();
    await flushStoreEvents();
    store.events.add([subscriptionPurchase(status: PurchaseStatus.pending)]);
    await flushStoreEvents();
    expect(service.state.value.awaitingApproval, isTrue);
    store.queryPending!.complete();
    await loading;
    expect(service.state.value.awaitingApproval, isTrue);
    expect(
      service.state.value.message,
      contains('Waiting for payment approval'),
    );
    expect(verified, 0);
  });

  test(
    'a failed reload clears stale products and cannot start a cached purchase',
    () async {
      await service.load();
      final previousProduct = service.state.value.products.first;
      store.failsLoad = true;
      await service.load();
      expect(service.state.value.available, isFalse);
      expect(service.state.value.products, isEmpty);
      await service.buy(previousProduct);
      expect(store.buys, isEmpty);
    },
  );

  test(
    'unavailable stores and unrelated products never enable purchases',
    () async {
      store.available = false;
      await service.load();
      expect(store.queries, 0);
      expect(service.state.value.available, isFalse);
      store.available = true;
      store.products = [subscriptionProduct('unrelated')];
      await service.load();
      expect(service.state.value.available, isFalse);
      expect(service.state.value.products, isEmpty);
    },
  );

  test(
    'a purchase that does not start releases busy state without granting access',
    () async {
      await service.load();
      store.startsPurchase = false;
      await service.buy(service.state.value.products.first);
      expect(service.state.value.busy, isFalse);
      expect(service.state.value.message, contains('did not start'));
      expect(verified, 0);
    },
  );

  test(
    'pending approval blocks another purchase but leaves restore usable',
    () async {
      await service.load();
      store.events.add([subscriptionPurchase(status: PurchaseStatus.pending)]);
      await flushStoreEvents();
      expect(service.state.value.awaitingApproval, isTrue);
      expect(service.state.value.busy, isFalse);
      await service.buy(service.state.value.products.first);
      expect(store.buys, isEmpty);
      await service.restore();
      expect(store.restores, [subscriptionUser]);
      expect(service.state.value.awaitingApproval, isTrue);
      await service.buy(service.state.value.products.first);
      expect(store.buys, isEmpty);
      store.events.add([subscriptionPurchase(status: PurchaseStatus.canceled)]);
      await flushStoreEvents();
      expect(service.state.value.awaitingApproval, isFalse);
      expect(service.state.value.message, contains('cancelled'));
      expect(verified, 0);
    },
  );

  for (final restoreFails in [false, true]) {
    test(
      '${restoreFails ? 'failed' : 'empty'} restore preserves pending approval until a verified terminal event',
      () async {
        await service.load();
        final product = service.state.value.products.first;
        store.events.add([
          subscriptionPurchase(status: PurchaseStatus.pending),
        ]);
        await flushStoreEvents();
        store.restoreFailures = restoreFails ? 1 : 0;

        final restoring = service.restore();
        expect(service.state.value.busy, isTrue);
        expect(service.state.value.awaitingApproval, isTrue);
        await restoring;
        expect(service.state.value.busy, isFalse);
        expect(service.state.value.awaitingApproval, isTrue);
        expect(
          service.state.value.message,
          contains('still awaiting approval'),
        );
        await service.buy(product);
        expect(store.buys, isEmpty);
        expect(verified, 0);
        expect(store.completions, isEmpty);

        // Restore stays available; the store's eventual terminal event can
        // resolve the pending purchase after server verification.
        store.restored = [
          subscriptionPurchase(status: PurchaseStatus.restored),
        ];
        await service.restore();
        expect(store.restores, hasLength(2));
        expect(service.state.value.awaitingApproval, isFalse);
        expect(service.state.value.busy, isFalse);
        expect(verified, 1);
        expect(store.completions, hasLength(1));
      },
    );
  }

  test('a store connection error cannot cancel pending approval', () async {
    await service.load();
    store.events.add([subscriptionPurchase(status: PurchaseStatus.pending)]);
    await flushStoreEvents();
    store.events.addError(StateError('connection lost'));
    await flushStoreEvents();
    expect(service.state.value.awaitingApproval, isTrue);
    expect(service.state.value.busy, isFalse);
    await service.buy(service.state.value.products.first);
    expect(store.buys, isEmpty);
    await service.restore();
    expect(store.restores, [subscriptionUser]);
    expect(service.state.value.awaitingApproval, isTrue);
    store.events.add([subscriptionPurchase(status: PurchaseStatus.error)]);
    await flushStoreEvents();
    expect(service.state.value.awaitingApproval, isFalse);
    expect(verified, 0);
    expect(store.completions, isEmpty);
  });

  for (final status in [200, 503]) {
    test(
      'rejected verification HTTP$status never completes or grants access',
      () async {
        backend.respond = (_) => jsonResponse({'verified': false}, status);
        store.events.add([subscriptionPurchase()]);
        await flushStoreEvents();
        expect(
          backend.requests.single.url.path,
          '/functions/v1/workloop-subscription',
        );
        expect(
          backend.requests.single.headers['authorization'],
          contains('Bearer '),
        );
        expect(jsonDecode(backend.requests.single.body), {
          'platform': 'apple',
          'signedTransaction': 'signed-test-receipt',
        });
        expect(verified, 0);
        expect(store.completions, isEmpty);
        expect(service.state.value.message, contains('Do not buy again'));
        expect(service.state.value.busy, isFalse);
      },
    );
  }

  test(
    'empty receipt and unrelated product never reach verification',
    () async {
      store.events.add([
        subscriptionPurchase(receipt: ''),
        subscriptionPurchase(product: 'unrelated'),
      ]);
      await flushStoreEvents();
      expect(backend.requests, isEmpty);
      expect(store.completions, isEmpty);
      expect(verified, 0);
    },
  );

  test(
    'duplicate successful callbacks verify and finish exactly once',
    () async {
      store.events.add([
        subscriptionPurchase(),
        subscriptionPurchase(status: PurchaseStatus.restored),
      ]);
      await flushStoreEvents();
      expect(backend.requests, hasLength(1));
      expect(verified, 1);
      expect(store.completions, hasLength(1));
      expect(service.state.value.message, contains('No real payment'));
    },
  );

  test(
    'a different receipt cannot reuse a previously verified transaction ID',
    () async {
      store.events.add([subscriptionPurchase()]);
      await flushStoreEvents();
      backend.respond = (_) => jsonResponse({'verified': false});
      store.events.add([
        subscriptionPurchase(receipt: 'different-unverified-proof'),
      ]);
      await flushStoreEvents();
      expect(backend.requests, hasLength(2));
      expect(verified, 1);
      expect(store.completions, hasLength(1));
    },
  );

  test(
    'acknowledgement failure retries completion without regranting access',
    () async {
      store.completeFailures = 1;
      store.events.add([subscriptionPurchase()]);
      await flushStoreEvents();
      expect(verified, 1);
      expect(service.state.value.message, contains('purchase was verified'));
      store.events.add([subscriptionPurchase(status: PurchaseStatus.restored)]);
      await flushStoreEvents();
      expect(backend.requests, hasLength(1));
      expect(store.completions, hasLength(2));
      expect(verified, 1);
    },
  );

  test(
    'an owner switch during verification never finishes or updates the new account',
    () async {
      final response = Completer<http.Response>();
      backend.respond = (_) => response.future;
      store.events.add([subscriptionPurchase()]);
      await flushStoreEvents();
      expect(backend.requests, hasLength(1));
      final snapshot = service.state.value;
      await backend.account(otherSubscriptionUser);
      response.complete(jsonResponse({'verified': true}));
      await flushStoreEvents();
      expect(verified, 0);
      expect(store.completions, isEmpty);
      expect(identical(service.state.value, snapshot), isTrue);
      await service.restore();
      expect(store.restores, isEmpty);
    },
  );

  test(
    'disposing with an outstanding verification prevents callbacks and finishing',
    () async {
      final response = Completer<http.Response>();
      backend.respond = (_) => response.future;
      store.events.add([subscriptionPurchase()]);
      await flushStoreEvents();
      service.dispose();
      response.complete(jsonResponse({'verified': true}));
      await flushStoreEvents();
      expect(verified, 0);
      expect(store.completions, isEmpty);
    },
  );

  test(
    'restore with no purchases does not claim a verified purchase',
    () async {
      await service.restore();
      expect(verified, 0);
      expect(store.completions, isEmpty);
      expect(service.state.value.message, contains('No additional purchases'));
    },
  );

  test('restore verifies signed purchases before finishing them', () async {
    store.restored = [subscriptionPurchase(status: PurchaseStatus.restored)];
    await service.restore();
    expect(store.restores, [subscriptionUser]);
    expect(backend.requests, hasLength(1));
    expect(verified, 1);
    expect(store.completions, hasLength(1));
  });

  test(
    'explicit restore rechecks previously verified receipts without finishing twice',
    () async {
      store.events.add([subscriptionPurchase()]);
      await flushStoreEvents();
      expect(verified, 1);
      store.restored = [subscriptionPurchase(status: PurchaseStatus.restored)];
      await service.restore();
      expect(backend.requests, hasLength(2));
      expect(verified, 2);
      expect(store.completions, hasLength(1));
    },
  );

  test(
    'failed restore remains retryable and does not refresh verified access',
    () async {
      store.restoreFailures = 1;
      await service.restore();
      expect(service.state.value.busy, isFalse);
      expect(service.state.value.message, contains('Could not restore'));
      expect(verified, 0);
      await service.restore();
      expect(store.restores, hasLength(2));
    },
  );

  test(
    'a purchase error resets state without completing the transaction',
    () async {
      store.events.add([subscriptionPurchase(status: PurchaseStatus.error)]);
      await flushStoreEvents();
      expect(service.state.value.busy, isFalse);
      expect(service.state.value.message, contains('could not complete'));
      expect(verified, 0);
      expect(store.completions, isEmpty);
    },
  );

  test('unsupported platforms give a clear restore explanation', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await service.load();
    await service.restore();
    expect(service.state.value.message, contains('iPhone or Android'));
    expect(store.restores, isEmpty);
    expect(WorkloopPlans.trialDays, 30);
  });
}
