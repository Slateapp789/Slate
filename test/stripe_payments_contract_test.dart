import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/finance/payment_collection_sheet.dart';
import 'package:workloop/shared/models/slate_models.dart';
import 'package:workloop/shared/repositories/payments_repository.dart';

void main() {
  group('Stripe payment security contract', () {
    final migration = File(
      'supabase/migrations/20260804090000_stripe_connect_payments.sql',
    ).readAsStringSync().toLowerCase();

    test('provider tables are RLS protected and client read-only', () {
      for (final table in const [
        'workspace_payment_accounts',
        'payment_transactions',
        'payment_refunds',
      ]) {
        expect(
          migration,
          contains('alter table public.$table enable row level security'),
        );
      }
      expect(
        migration,
        contains('revoke all on table public.workspace_payment_accounts'),
      );
      expect(migration, contains('to authenticated;'));
      expect(migration, contains('to service_role;'));
    });

    test(
      'webhooks are idempotent and provider income is trigger reconciled',
      () {
        expect(migration, contains('app_private.stripe_webhook_events'));
        expect(migration, contains('stripe_event_id text primary key'));
        expect(migration, contains('sync_invoice_stripe_amount'));
        expect(migration, contains('amount_paid - invoice.stripe_amount_paid'));
        expect(migration, contains('on delete restrict'));
      },
    );

    test('platform fee and live mode remain disabled by default', () {
      final environment = File(
        'supabase/functions/.env.example',
      ).readAsStringSync();
      expect(environment, contains('WORKLOOP_PLATFORM_FEE_BPS=0'));
      expect(environment, contains('WORKLOOP_PLATFORM_FEE_ENABLED=false'));
      expect(environment, contains('STRIPE_LIVE_MODE_ALLOWED=false'));
    });
  });

  test('provider-collected income survives a manual unpaid edit', () {
    final payment = Payment.fromMap({
      'id': 'payment-1',
      'workspace_id': 'workspace-1',
      'status': 'paid',
      'issue_date': '2026-08-04',
      'total': 100,
      'amount_paid': 40,
      'stripe_amount_paid': 40,
    });

    final update = resolvePaymentUpdateState(
      existingPayment: payment,
      amount: 100,
      selectedStatus: 'sent',
      selectedDate: DateTime(2026, 8, 4),
      paymentStateChanged: true,
    );

    expect(payment.stripeAmountPaid, 40);
    expect(update.status, 'sent');
    expect(update.amountPaid, 40);
    expect(update.incomeRecordedAt, isNotNull);
  });

  test('payment total cannot be edited below provider-collected amount', () {
    final payment = Payment(
      id: 'payment-1',
      workspaceId: 'workspace-1',
      number: 'PAY-001',
      status: 'paid',
      issueDate: DateTime(2026, 8, 4),
      total: 100,
      amountPaid: 75,
      stripeAmountPaid: 75,
    );

    expect(
      () => resolvePaymentUpdateState(
        existingPayment: payment,
        amount: 50,
        selectedStatus: 'paid',
        selectedDate: DateTime(2026, 8, 4),
        paymentStateChanged: false,
      ),
      throwsArgumentError,
    );
  });

  test('payment errors never expose Dart StateError prefixes', () {
    expect(
      friendlyPaymentError(
        StateError(
          'Tap to Pay is not enabled for this Workloop build yet. '
          'You can still copy a secure payment link.',
        ),
      ),
      'Tap to Pay is not enabled for this Workloop build yet. '
      'You can still copy a secure payment link.',
    );
  });

  test('contactless availability explains the real platform gate', () {
    expect(
      contactlessUnavailableMessage(TargetPlatform.iOS),
      'Available after Apple approves Workloop for Tap to Pay.',
    );
    expect(
      contactlessUnavailableMessage(TargetPlatform.android),
      'Contactless payments are not available on this phone yet.',
    );
  });

  testWidgets('payment setup entry sets honest expectations', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PaymentSetupCard(onTap: () {})),
      ),
    );

    expect(find.text('Get paid with Workloop'), findsOneWidget);
    expect(
      find.text('Set up Stripe, send payment links, and manage payouts.'),
      findsOneWidget,
    );
    expect(find.textContaining('Tap to Pay'), findsNothing);
  });

  test('ready flow leads users to money they can collect', () {
    final source = File(
      'lib/features/finance/payment_collection_sheet.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'View payments to collect'"));
    expect(source, contains('Copy secure payment link'));
    expect(source, contains("status: 'Pending'"));
    expect(source, contains('Test mode — no real money will move.'));
  });
}
