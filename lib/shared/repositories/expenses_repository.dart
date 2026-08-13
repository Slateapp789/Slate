import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import 'repository_pagination.dart';
import 'supabase_client_provider.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(supabaseClientProvider));
});

class ExpensesRepository {
  final SupabaseClient _client;
  const ExpensesRepository(this._client);

  Future<List<Expense>> list(String workspaceId) async {
    try {
      final rows = await fetchAllRepositoryPages<Map<String, dynamic>>(
        loadPage: (from, to) async {
          final page = await _client
              .from('expenses')
              .select()
              .eq('workspace_id', workspaceId)
              .order('expense_date', ascending: false)
              .order('created_at', ascending: false)
              .order('id', ascending: true)
              .range(from, to);
          return List<Map<String, dynamic>>.from(page);
        },
      );
      return rows.map<Expense>(Expense.fromMap).toList();
    } on PostgrestException catch (error) {
      if (_tableMissing(error)) return [];
      rethrow;
    }
  }

  Future<List<Expense>> listForBusinessFeed(
    String workspaceId, {
    required DateTime from,
    int limit = 12,
  }) async {
    try {
      final rows = await _client
          .from('expenses')
          .select()
          .eq('workspace_id', workspaceId)
          .gte('expense_date', from.toIso8601String().split('T').first)
          .order('expense_date', ascending: false)
          .order('created_at', ascending: false)
          .order('id', ascending: true)
          .limit(limit);
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

  Future<void> update({
    required String expenseId,
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    await _client
        .from('expenses')
        .update({
          'amount': amount,
          'category': category,
          'expense_date': date.toIso8601String().split('T').first,
          'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', expenseId)
        .select('id')
        .single();
  }

  Future<void> delete(String expenseId) async {
    await _client
        .from('expenses')
        .delete()
        .eq('id', expenseId)
        .select('id')
        .single();
  }

  bool _tableMissing(PostgrestException error) {
    return error.code == '42P01' || error.message.contains('expenses');
  }
}
