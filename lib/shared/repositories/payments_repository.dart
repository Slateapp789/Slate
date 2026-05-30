import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(supabaseClientProvider));
});

class PaymentsRepository {
  final SupabaseClient _client;
  const PaymentsRepository(this._client);

  Future<List<Payment>> list(String workspaceId) async {
    await refreshOverdue(workspaceId);
    final rows = await _client
        .from('invoices')
        .select('*, contacts(name)')
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);
    return rows
        .map<Payment>((row) => Payment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Payment>> outstanding(String workspaceId) async {
    final rows = await _client
        .from('invoices')
        .select('*, contacts(name)')
        .eq('workspace_id', workspaceId)
        .inFilter('status', ['sent', 'overdue', 'pending'])
        .order('due_date', ascending: true);
    return rows
        .map<Payment>((row) => Payment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> forClientRows(String clientId) async {
    final rows = await _client
        .from('invoices')
        .select('*, contacts(name)')
        .eq('contact_id', clientId)
        .order('issue_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Payment>> forClient(String clientId) async {
    final rows = await forClientRows(clientId);
    return rows.map<Payment>((row) => Payment.fromMap(row)).toList();
  }

  Future<void> create({
    required String workspaceId,
    required double amount,
    required String status,
    required DateTime date,
    DateTime? dueDate,
    String? contactId,
    String? notes,
  }) async {
    final existing = await _client
        .from('invoices')
        .select('id')
        .eq('workspace_id', workspaceId);
    final count = List<dynamic>.from(existing).length + 1;
    final paymentNumber = 'PAY-${count.toString().padLeft(3, '0')}';
    final dateString = date.toIso8601String().split('T').first;
    final dueDateString = (dueDate ?? date).toIso8601String().split('T').first;

    await _client.from('invoices').insert({
      'workspace_id': workspaceId,
      'contact_id': contactId,
      'invoice_number': paymentNumber,
      'type': 'invoice',
      'status': status,
      'issue_date': dateString,
      'due_date': dueDateString,
      'subtotal': amount,
      'tax_rate': 0,
      'tax_amount': 0,
      'discount_value': 0,
      'total': amount,
      'amount_paid': status == 'paid' ? amount : 0,
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    });
  }

  Future<void> markPaid(Payment payment) async {
    await _client
        .from('invoices')
        .update({'status': 'paid', 'amount_paid': payment.total})
        .eq('id', payment.id);
  }

  Future<void> delete(String paymentId) async {
    await _client.from('invoices').delete().eq('id', paymentId);
  }

  Future<void> refreshOverdue(String workspaceId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    await _client
        .from('invoices')
        .update({'status': 'overdue'})
        .eq('workspace_id', workspaceId)
        .inFilter('status', ['sent', 'pending'])
        .lt('due_date', today);
  }
}
