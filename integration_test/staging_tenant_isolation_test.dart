import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'staging_test_config.dart';

const _userAEmail = String.fromEnvironment('E2E_USER_A_EMAIL');
const _userAPassword = String.fromEnvironment('E2E_USER_A_PASSWORD');
const _userBEmail = String.fromEnvironment('E2E_USER_B_EMAIL');
const _userBPassword = String.fromEnvironment('E2E_USER_B_PASSWORD');

final _configured =
    stagingWritesAllowed &&
    stagingUrl.isNotEmpty &&
    stagingAnonKey.isNotEmpty &&
    _userAEmail.isNotEmpty &&
    _userAPassword.isNotEmpty &&
    _userBEmail.isNotEmpty &&
    _userBPassword.isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  requireSafeStagingWriteTarget();

  testWidgets(
    'staging clients cannot mutate another workspace through the SDK',
    (tester) async {
      final userA = _client();
      final userB = _client();
      final runId = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
      final cleanupRows = <_CleanupRow>[];

      try {
        final authA = await userA.auth.signInWithPassword(
          email: _userAEmail,
          password: _userAPassword,
        );
        final authB = await userB.auth.signInWithPassword(
          email: _userBEmail,
          password: _userBPassword,
        );
        expect(authA.user, isNotNull);
        expect(authB.user, isNotNull);

        final workspaceA = await _workspaceId(userA, authA.user!.id);
        final workspaceB = await _workspaceId(userB, authB.user!.id);
        expect(
          workspaceA,
          isNot(workspaceB),
          reason: 'The E2E accounts must own separate workspaces.',
        );

        final start = DateTime.now().toUtc().add(const Duration(days: 75));
        final date = start.toIso8601String().split('T').first;
        final contact = await _insertSentinel(
          userB,
          table: 'contacts',
          payload: {
            'workspace_id': workspaceB,
            'name': 'E2E Tenant B contact $runId',
            'phone': '+44 7700 900999',
            'source': 'E2E isolation',
            'tags': ['E2E'],
          },
          markerColumn: 'name',
          cleanupRows: cleanupRows,
        );
        final service = await _insertSentinel(
          userB,
          table: 'services',
          payload: {
            'workspace_id': workspaceB,
            'name': 'E2E Tenant B service $runId',
            'duration_mins': 60,
            'price': 85,
            'description': 'Disposable isolation evidence.',
            'show_on_profile': false,
          },
          markerColumn: 'name',
          cleanupRows: cleanupRows,
        );
        final appointment = await _insertSentinel(
          userB,
          table: 'appointments',
          payload: {
            'workspace_id': workspaceB,
            'contact_id': contact.id,
            'service_id': service.id,
            'title': 'E2E Tenant B booking $runId',
            'start_time': start.toIso8601String(),
            'end_time': start.add(const Duration(hours: 1)).toIso8601String(),
            'status': 'scheduled',
            'price': 85,
          },
          markerColumn: 'title',
          cleanupRows: cleanupRows,
        );
        final invoice = await _insertSentinel(
          userB,
          table: 'invoices',
          payload: {
            'workspace_id': workspaceB,
            'contact_id': contact.id,
            'appointment_id': appointment.id,
            'type': 'invoice',
            'status': 'draft',
            'issue_date': date,
            'due_date': date,
            'subtotal': 85,
            'tax_rate': 0,
            'tax_amount': 0,
            'discount_value': 0,
            'total': 85,
            'amount_paid': 0,
            'notes': 'E2E Tenant B invoice $runId',
          },
          markerColumn: 'notes',
          cleanupRows: cleanupRows,
        );
        final task = await _insertSentinel(
          userB,
          table: 'tasks',
          payload: {
            'workspace_id': workspaceB,
            'contact_id': contact.id,
            'appointment_id': appointment.id,
            'title': 'E2E Tenant B task $runId',
            'priority': 'medium',
            'status': 'open',
            'due_date': date,
          },
          markerColumn: 'title',
          cleanupRows: cleanupRows,
        );
        final sentinels = <_TenantSentinel>[
          contact,
          service,
          appointment,
          invoice,
          await _insertSentinel(
            userB,
            table: 'invoice_line_items',
            payload: {
              'workspace_id': workspaceB,
              'invoice_id': invoice.id,
              'description': 'E2E Tenant B line item $runId',
              'quantity': 1,
              'unit_price': 85,
              'line_total': 85,
              'position': 0,
            },
            markerColumn: 'description',
            cleanupRows: cleanupRows,
          ),
          await _insertSentinel(
            userB,
            table: 'expenses',
            payload: {
              'workspace_id': workspaceB,
              'amount': 12.50,
              'category': 'Other',
              'expense_date': date,
              'notes': 'E2E Tenant B expense $runId',
            },
            markerColumn: 'notes',
            cleanupRows: cleanupRows,
          ),
          task,
          await _insertSentinel(
            userB,
            table: 'task_checklist_items',
            payload: {
              'workspace_id': workspaceB,
              'task_id': task.id,
              'title': 'E2E Tenant B checklist item $runId',
              'completed': false,
              'position': 0,
            },
            markerColumn: 'title',
            cleanupRows: cleanupRows,
          ),
          await _insertSentinel(
            userB,
            table: 'notes',
            payload: {
              'workspace_id': workspaceB,
              'contact_id': contact.id,
              'appointment_id': appointment.id,
              'title': 'E2E Tenant B note $runId',
              'body': 'Disposable isolation evidence.',
            },
            markerColumn: 'title',
            cleanupRows: cleanupRows,
          ),
          await _insertSentinel(
            userB,
            table: 'notifications',
            payload: {
              'workspace_id': workspaceB,
              'type': 'booking',
              'title': 'E2E Tenant B notification $runId',
              'body': 'Disposable isolation evidence.',
              'read': false,
            },
            markerColumn: 'title',
            cleanupRows: cleanupRows,
          ),
          await _insertSentinel(
            userB,
            table: 'booking_requests',
            payload: {
              'workspace_id': workspaceB,
              'name': 'E2E Tenant B request $runId',
              'phone': '+44 7700 901234',
              'preferred_time_text': 'A weekday morning',
              'message': 'Disposable isolation evidence.',
              'status': 'pending',
              'request_token': _uuidFor(runId),
            },
            markerColumn: 'name',
            cleanupRows: cleanupRows,
          ),
          await _insertSentinel(
            userB,
            table: 'push_tokens',
            payload: {
              'workspace_id': workspaceB,
              'user_id': authB.user!.id,
              'token': 'e2e-tenant-b-$runId',
              'platform': 'ios',
            },
            markerColumn: 'token',
            cleanupRows: cleanupRows,
          ),
          await _insertSentinel(
            userB,
            table: 'calendar_sync_accounts',
            payload: {
              'workspace_id': workspaceB,
              'provider': 'e2e',
              'provider_account_id': 'e2e-tenant-b-$runId',
              'sync_enabled': false,
            },
            markerColumn: 'provider_account_id',
            cleanupRows: cleanupRows,
          ),
        ];

        for (final sentinel in sentinels) {
          await _expectTenantIsolation(
            attacker: userA,
            owner: userB,
            sentinel: sentinel,
            cleanupRows: cleanupRows,
          );
        }
      } finally {
        for (final row in cleanupRows.reversed) {
          await _ignoreCleanup(
            () => userB.from(row.table).delete().eq('id', row.id),
          );
        }
        await _ignoreCleanup(userA.auth.signOut);
        await _ignoreCleanup(userB.auth.signOut);
        userA.dispose();
        userB.dispose();
      }
    },
    skip: !_configured,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

class _TenantSentinel {
  const _TenantSentinel({
    required this.table,
    required this.id,
    required this.markerColumn,
    required this.markerValue,
    required this.insertPayload,
  });

  final String table;
  final String id;
  final String markerColumn;
  final String markerValue;
  final Map<String, dynamic> insertPayload;
}

class _CleanupRow {
  const _CleanupRow(this.table, this.id);

  final String table;
  final String id;
}

Future<_TenantSentinel> _insertSentinel(
  SupabaseClient owner, {
  required String table,
  required Map<String, dynamic> payload,
  required String markerColumn,
  required List<_CleanupRow> cleanupRows,
}) async {
  final row = await owner.from(table).insert(payload).select('id').single();
  final id = row['id'] as String;
  cleanupRows.add(_CleanupRow(table, id));
  return _TenantSentinel(
    table: table,
    id: id,
    markerColumn: markerColumn,
    markerValue: payload[markerColumn] as String,
    insertPayload: Map<String, dynamic>.from(payload),
  );
}

Future<void> _expectTenantIsolation({
  required SupabaseClient attacker,
  required SupabaseClient owner,
  required _TenantSentinel sentinel,
  required List<_CleanupRow> cleanupRows,
}) async {
  final reads = await attacker
      .from(sentinel.table)
      .select('id')
      .eq('id', sentinel.id);
  expect(
    reads,
    isEmpty,
    reason: 'User A unexpectedly read User B data from ${sentinel.table}.',
  );

  final updates = await attacker
      .from(sentinel.table)
      .update({sentinel.markerColumn: 'Cross-tenant overwrite'})
      .eq('id', sentinel.id)
      .select('id');
  expect(
    updates,
    isEmpty,
    reason: 'User A unexpectedly updated User B data in ${sentinel.table}.',
  );

  final deletes = await attacker
      .from(sentinel.table)
      .delete()
      .eq('id', sentinel.id)
      .select('id');
  expect(
    deletes,
    isEmpty,
    reason: 'User A unexpectedly deleted User B data from ${sentinel.table}.',
  );

  final ownerRow = await owner
      .from(sentinel.table)
      .select('id, ${sentinel.markerColumn}')
      .eq('id', sentinel.id)
      .single();
  expect(ownerRow[sentinel.markerColumn], sentinel.markerValue);

  final attackPayload = Map<String, dynamic>.from(sentinel.insertPayload);
  attackPayload[sentinel.markerColumn] =
      'Cross-tenant insert ${sentinel.table}';
  if (sentinel.table == 'booking_requests') {
    attackPayload['request_token'] = _uuidFor('${sentinel.id}-attack');
  }
  try {
    final inserted = await attacker
        .from(sentinel.table)
        .insert(attackPayload)
        .select('id')
        .single();
    final insertedId = inserted['id'] as String;
    cleanupRows.add(_CleanupRow(sentinel.table, insertedId));
    fail('User A unexpectedly inserted into ${sentinel.table}.');
  } on PostgrestException {
    // Expected: the supplied workspace belongs to User B, so RLS rejects it.
  }
}

String _uuidFor(String seed) {
  final hex = seed.codeUnits
      .fold<BigInt>(
        BigInt.zero,
        (value, unit) => (value << 5) ^ BigInt.from(unit),
      )
      .toRadixString(16)
      .padLeft(32, '0');
  return '00000000-0000-4000-8000-${hex.substring(hex.length - 12)}';
}

SupabaseClient _client() => SupabaseClient(
  stagingUrl,
  stagingAnonKey,
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

Future<String> _workspaceId(SupabaseClient client, String userId) async {
  final membership = await client
      .from('workspace_members')
      .select('workspace_id')
      .eq('user_id', userId)
      .limit(1)
      .maybeSingle();
  expect(membership, isNotNull, reason: 'The E2E user needs a workspace.');
  return membership!['workspace_id'] as String;
}

Future<void> _ignoreCleanup(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    // Cleanup is best effort so the original isolation failure stays visible.
  }
}
