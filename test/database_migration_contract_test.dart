import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clean database replay contract', () {
    final migrationFiles =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('core baseline runs before every extension migration', () {
      expect(migrationFiles, isNotEmpty);
      expect(
        migrationFiles.first.path,
        endsWith('20260530000000_core_schema_baseline.sql'),
      );
    });

    test('baseline defines every table required by the first extension', () {
      final baseline = migrationFiles.first.readAsStringSync().toLowerCase();
      for (final table in const [
        'workspaces',
        'workspace_members',
        'workspace_settings',
        'contacts',
        'services',
        'appointments',
        'invoices',
        'invoice_line_items',
        'tasks',
        'business_profiles',
      ]) {
        expect(
          baseline,
          contains('create table if not exists public.$table'),
          reason: '$table must exist before extension migrations run',
        );
      }
    });

    test('task completion column exists before its trigger migration', () {
      final baseline = migrationFiles.first.readAsStringSync().toLowerCase();
      final completionMigration = File(
        'supabase/migrations/'
        '20260715103602_track_task_completion_timestamp.sql',
      ).readAsStringSync().toLowerCase();

      expect(baseline, contains('completed_at timestamptz'));
      expect(completionMigration, contains('new.completed_at'));
      expect(completionMigration, contains('set completed_at'));
    });
  });

  test('database security harness checks inherited and direct grants', () {
    final schemaSecurity = File(
      'supabase/tests/database/001_schema_security.test.sql',
    ).readAsStringSync().toLowerCase();
    final isolation = File(
      'supabase/tests/database/002_rls_isolation.test.sql',
    ).readAsStringSync().toLowerCase();

    expect(schemaSecurity, contains('information_schema.table_privileges'));
    expect(schemaSecurity, contains("lower(grantee) in ('anon', 'public')"));
    expect(
      schemaSecurity,
      contains("lower(grantee) in ('anon', 'authenticated', 'public')"),
    );
    expect(isolation, contains("'42501'"));
    expect(
      isolation,
      contains('anonymous callers have no private-table read privilege'),
    );
  });
}
