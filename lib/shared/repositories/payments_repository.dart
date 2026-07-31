import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'repository_pagination.dart';
import 'supabase_client_provider.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(supabaseClientProvider));
});

class PaymentsRepository {
  final SupabaseClient _client;
  const PaymentsRepository(this._client);

  Future<List<Payment>> list(String workspaceId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('invoices')
            .select('*, contacts(name)')
            .eq('workspace_id', workspaceId)
            .order('created_at', ascending: false)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<Payment>(Payment.fromMap).toList();
  }

  Future<List<Payment>> outstanding(String workspaceId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('invoices')
            .select('*, contacts(name)')
            .eq('workspace_id', workspaceId)
            .inFilter('status', ['sent', 'overdue', 'pending'])
            .order('due_date', ascending: true)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<Payment>(Payment.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> forClientRows(String clientId) async {
    return fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('invoices')
            .select('*, contacts(name)')
            .eq('contact_id', clientId)
            .order('issue_date', ascending: false)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
  }

  Future<List<Payment>> forClient(String clientId) async {
    final rows = await forClientRows(clientId);
    return rows.map<Payment>((row) => Payment.fromMap(row)).toList();
  }

  Future<List<Payment>> forAppointment(String appointmentId) async {
    final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
      loadPage: (from, to) async {
        final page = await _client
            .from('invoices')
            .select('*, contacts(name)')
            .eq('appointment_id', appointmentId)
            .order('created_at', ascending: false)
            .order('id', ascending: true)
            .range(from, to);
        return List<Map<String, dynamic>>.from(page);
      },
    );
    return rows.map<Payment>(Payment.fromMap).toList();
  }

  Future<void> create({
    required String workspaceId,
    required double amount,
    required String status,
    required DateTime date,
    DateTime? dueDate,
    String? contactId,
    String? appointmentId,
    String? notes,
  }) async {
    final dateString = date.toIso8601String().split('T').first;
    final dueDateString = (dueDate ?? date).toIso8601String().split('T').first;
    final isPaid = status == 'paid';

    await _client.from('invoices').insert({
      'workspace_id': workspaceId,
      'contact_id': contactId,
      'appointment_id': appointmentId,
      'type': 'invoice',
      'status': status,
      'issue_date': dateString,
      'due_date': dueDateString,
      'subtotal': amount,
      'tax_rate': 0,
      'tax_amount': 0,
      'discount_value': 0,
      'total': amount,
      'amount_paid': isPaid ? amount : 0,
      'income_recorded_at': isPaid ? date.toUtc().toIso8601String() : null,
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    });
  }

  Future<void> markPaid(Payment payment) async {
    await _client
        .from('invoices')
        .update({
          'status': 'paid',
          'amount_paid': payment.total,
          'income_recorded_at':
              payment.incomeRecordedAt?.toUtc().toIso8601String() ??
              DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', payment.id)
        .select('id')
        .single();
  }

  Future<void> update({
    required Payment existingPayment,
    required double amount,
    required String status,
    required DateTime date,
    required bool paymentStateChanged,
    DateTime? dueDate,
    String? contactId,
    String? appointmentId,
    String? notes,
  }) async {
    final dateString = date.toIso8601String().split('T').first;
    final updateState = resolvePaymentUpdateState(
      existingPayment: existingPayment,
      amount: amount,
      selectedStatus: status,
      selectedDate: date,
      paymentStateChanged: paymentStateChanged,
    );
    final dueDateString =
        (updateState.status == 'paid' ? date : dueDate ?? date)
            .toIso8601String()
            .split('T')
            .first;
    await _client
        .from('invoices')
        .update({
          'contact_id': contactId,
          'appointment_id': appointmentId,
          'status': updateState.status,
          'issue_date': dateString,
          'due_date': dueDateString,
          'subtotal': amount,
          'tax_amount': 0,
          'total': amount,
          'amount_paid': updateState.amountPaid,
          'income_recorded_at': updateState.incomeRecordedAt,
          'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        })
        .eq('id', existingPayment.id)
        .select('id')
        .single();
  }

  Future<void> delete(String paymentId) async {
    await _client
        .from('invoices')
        .delete()
        .eq('id', paymentId)
        .select('id')
        .single();
  }
}

typedef PaymentUpdateState = ({
  String status,
  double amountPaid,
  String? incomeRecordedAt,
});

PaymentUpdateState resolvePaymentUpdateState({
  required Payment existingPayment,
  required double amount,
  required String selectedStatus,
  required DateTime selectedDate,
  required bool paymentStateChanged,
}) {
  if (paymentStateChanged) {
    final isPaid = selectedStatus == 'paid';
    return (
      status: isPaid ? 'paid' : 'sent',
      amountPaid: isPaid ? amount : 0,
      incomeRecordedAt: isPaid ? selectedDate.toUtc().toIso8601String() : null,
    );
  }

  if (existingPayment.status == 'paid') {
    return (
      status: 'paid',
      amountPaid: amount,
      incomeRecordedAt: selectedDate.toUtc().toIso8601String(),
    );
  }

  final amountPaid = existingPayment.amountPaid.clamp(0, amount).toDouble();
  final becomesFullyPaid = amount > 0 && amountPaid >= amount;
  return (
    status: becomesFullyPaid ? 'paid' : existingPayment.status,
    amountPaid: amountPaid,
    incomeRecordedAt: existingPayment.incomeRecordedAt
        ?.toUtc()
        .toIso8601String(),
  );
}
