import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'supabase_client_provider.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(supabaseClientProvider));
});

class ExpensesRepository {
  final SupabaseClient _client;
  const ExpensesRepository(this._client);

  Future<List<Expense>> list(String workspaceId) async {
    try {
      final rows = await _client
          .from('expenses')
          .select()
          .eq('workspace_id', workspaceId)
          .order('expense_date', ascending: false)
          .order('created_at', ascending: false);
      return rows
          .map<Expense>(
            (row) => Expense.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    } on PostgrestException catch (error) {
      if (_tableMissing(error)) return [];
      rethrow;
    }
  }

  Future<void> create({
    required String workspaceId,
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    await _client.from('expenses').insert({
      'workspace_id': workspaceId,
      'amount': amount,
      'category': category,
      'expense_date': date.toIso8601String().split('T').first,
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    });
  }

  Future<void> delete(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  bool _tableMissing(PostgrestException error) {
    return error.code == '42P01' || error.message.contains('expenses');
  }
}
