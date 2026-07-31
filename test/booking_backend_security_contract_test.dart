import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync().toLowerCase();

void _expectBefore(String source, String first, String second) {
  final firstIndex = source.indexOf(first);
  final secondIndex = source.indexOf(second);
  expect(firstIndex, greaterThanOrEqualTo(0), reason: 'Missing "$first"');
  expect(secondIndex, greaterThanOrEqualTo(0), reason: 'Missing "$second"');
  expect(
    firstIndex,
    lessThan(secondIndex),
    reason: 'Expected "$first" before "$second"',
  );
}

String _phoneDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

void main() {
  group('public booking request database boundary', () {
    late String rateLimitMigration;

    setUpAll(() {
      rateLimitMigration = _source(
        'supabase/migrations/20260726000057_edge_rate_limits.sql',
      );
    });

    test('duplicate tokens are unique and short-circuit side effects', () {
      expect(
        rateLimitMigration,
        contains('booking_requests_workspace_request_token_idx'),
      );
      expect(
        rateLimitMigration,
        contains('on public.booking_requests(workspace_id, request_token)'),
      );
      _expectBefore(
        rateLimitMigration,
        'select request.id',
        'delete from app_private.edge_rate_limit_events',
      );
      _expectBefore(
        rateLimitMigration,
        "return query select v_existing_id, 'duplicate'::text",
        'insert into public.notifications',
      );
    });

    test('service ownership, visibility, and booking mode are enforced', () {
      expect(rateLimitMigration, contains("profile.booking_mode = 'manual'"));
      expect(
        rateLimitMigration,
        contains('service.workspace_id = p_workspace_id'),
      );
      expect(rateLimitMigration, contains('service.show_on_profile = true'));
      expect(rateLimitMigration, contains('service.active = true'));
      _expectBefore(
        rateLimitMigration,
        "return query select null::uuid, 'invalid_service'::text",
        'insert into public.booking_requests',
      );
    });

    test('rate limits serialize and normalize both abuse dimensions', () {
      expect(rateLimitMigration, contains('pg_advisory_xact_lock'));
      expect(rateLimitMigration, contains("scope = 'booking_source'"));
      expect(rateLimitMigration, contains('if v_source_count >= 5'));
      expect(rateLimitMigration, contains("scope = 'booking_phone'"));
      expect(rateLimitMigration, contains('if v_phone_count >= 3'));
      expect(rateLimitMigration, contains("interval '15 minutes'"));
      expect(
        rateLimitMigration,
        contains("regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')"),
      );
    });

    test('ledger and intake RPC are closed to mobile roles', () {
      final denyMigration = _source(
        'supabase/migrations/'
        '20260726000520_deny_client_edge_rate_limit_access.sql',
      );
      expect(rateLimitMigration, contains('enable row level security'));
      expect(
        rateLimitMigration,
        contains(
          'revoke all on table app_private.edge_rate_limit_events from anon',
        ),
      );
      expect(
        rateLimitMigration,
        contains(
          'revoke all on table app_private.edge_rate_limit_events from authenticated',
        ),
      );
      expect(rateLimitMigration, contains(') to service_role'));
      expect(denyMigration, contains('to anon, authenticated'));
      expect(denyMigration, contains('using (false)'));
      expect(denyMigration, contains('with check (false)'));
    });
  });

  group('member booking conversion boundary', () {
    late String workflowMigration;

    setUpAll(() {
      workflowMigration = _source(
        'supabase/migrations/'
        '20260726000118_transactional_booking_workflows.sql',
      );
    });

    test('auth, workspace ownership, and linked records are validated', () {
      expect(workflowMigration, contains('v_caller_id uuid := auth.uid()'));
      expect(workflowMigration, contains('workspace access denied'));
      expect(
        workflowMigration,
        contains('member.workspace_id = v_workspace_id'),
      );
      expect(workflowMigration, contains('member.user_id = v_caller_id'));
      expect(
        workflowMigration,
        contains('service.workspace_id = v_workspace_id'),
      );
      expect(
        workflowMigration,
        contains('contact.workspace_id = v_workspace_id'),
      );
    });

    test('request conversion is locked, active-only, and atomic', () {
      expect(workflowMigration, contains('pg_advisory_xact_lock'));
      expect(
        workflowMigration,
        contains('request.workspace_id = v_workspace_id'),
      );
      expect(workflowMigration, contains('for update;'));
      expect(
        workflowMigration,
        contains("v_request_status not in ('pending', 'contacted')"),
      );
      _expectBefore(
        workflowMigration,
        'appointment overlaps an existing booking',
        'insert into public.appointments',
      );
      _expectBefore(
        workflowMigration,
        "set status = 'confirmed'",
        'insert into public.notifications',
      );
      _expectBefore(
        workflowMigration,
        'insert into public.notifications',
        'set result = v_existing_result',
      );
    });

    test('idempotency and callable privileges are explicit', () {
      expect(
        workflowMigration,
        contains(
          'primary key (workspace_id, user_id, operation, idempotency_key)',
        ),
      );
      expect(workflowMigration, contains('security definer'));
      expect(workflowMigration, contains("set search_path = ''"));
      expect(workflowMigration, contains('security invoker'));
      expect(
        workflowMigration,
        contains(
          'revoke execute on function public.create_booking_workflow(jsonb)',
        ),
      );
      expect(workflowMigration, contains('from public, anon'));
      expect(
        workflowMigration,
        contains(
          'grant execute on function public.create_booking_workflow(jsonb)',
        ),
      );
      expect(workflowMigration, contains('to authenticated'));
    });
  });

  group('launch booking hardening migration', () {
    late String hardeningMigration;

    setUpAll(() {
      hardeningMigration = _source(
        'supabase/migrations/'
        '20260726005736_harden_booking_notification_and_contact_reuse.sql',
      );
    });

    test('public request notifications respect both preference switches', () {
      final triggerFunction = hardeningMigration.substring(
        0,
        hardeningMigration.indexOf(
          'create or replace function app_private.create_booking_workflow',
        ),
      );

      expect(hardeningMigration, contains('new.type = \'booking_request\''));
      expect(
        hardeningMigration,
        contains('preference.workspace_id = new.workspace_id'),
      );
      expect(hardeningMigration, contains('not preference.all_notifications'));
      expect(hardeningMigration, contains('not preference.booking_request'));
      expect(hardeningMigration, contains('return null'));
      expect(
        hardeningMigration,
        contains('before insert on public.notifications'),
      );
      expect(hardeningMigration, contains("set search_path = ''"));
      expect(hardeningMigration, contains('from public, anon, authenticated'));
      expect(triggerFunction, contains('security invoker'));
      expect(triggerFunction, isNot(contains('security definer')));
    });

    test('contact reuse compares workspace-scoped canonical digits', () {
      expect(
        hardeningMigration,
        contains(
          'create or replace function '
          'app_private.create_booking_workflow',
        ),
      );
      expect(hardeningMigration, contains('member.user_id = v_caller_id'));
      expect(
        hardeningMigration,
        contains('contact.workspace_id = v_workspace_id'),
      );
      expect(
        hardeningMigration,
        contains("contact.phone = btrim(v_new_contact ->> 'phone')"),
      );
      expect(hardeningMigration, contains("coalesce(contact.phone, '')"));
      expect(
        hardeningMigration,
        contains("coalesce(v_new_contact ->> 'phone', '')"),
      );
      expect(hardeningMigration, contains("'[^0-9]'"));
      expect(hardeningMigration, contains(')) >= 7'));
      expect(hardeningMigration, contains('for update;'));
      expect(hardeningMigration, contains('pg_advisory_xact_lock'));
      _expectBefore(
        hardeningMigration,
        'insert into app_private.workflow_idempotency',
        'perform pg_advisory_xact_lock',
      );
      _expectBefore(
        hardeningMigration,
        'perform pg_advisory_xact_lock',
        'select contact.id',
      );
      expect(
        hardeningMigration,
        contains('select app_private.create_booking_workflow(p_payload)'),
      );
      expect(hardeningMigration, isNot(contains("'+44'")));
      expect(hardeningMigration, isNot(contains('united kingdom')));
    });

    test(
      'digit matching removes formatting but invents no country mapping',
      () {
        expect(
          _phoneDigits('+44 (0) 7123-456-789'),
          _phoneDigits('44 0 7123 456 789'),
        );
        expect(
          _phoneDigits('07123 456789'),
          isNot(_phoneDigits('+44 7123 456789')),
        );
      },
    );
  });

  test('schema contract records current booking backend shape', () {
    final schemaContract = _source('supabase/schema_contract.sql');

    expect(schemaContract, contains('phone_normalized text'));
    expect(
      schemaContract,
      contains(
        "generated always as (regexp_replace(phone, '[^0-9]', '', 'g')) stored",
      ),
    );
    expect(schemaContract, contains('request_token uuid'));
    expect(
      schemaContract,
      contains('booking_requests_workspace_request_token_idx'),
    );
    expect(
      schemaContract,
      contains('create table if not exists app_private.edge_rate_limit_events'),
    );
    expect(schemaContract, contains('enable row level security'));
    expect(schemaContract, contains('edge_rate_limit_events_deny_clients'));
    expect(schemaContract, contains('using (false)'));
    expect(schemaContract, contains('with check (false)'));
    expect(schemaContract, contains('from public, anon, authenticated'));
    expect(schemaContract, contains('to service_role'));
    expect(schemaContract, contains('dedupe_key text'));
    expect(schemaContract, contains('notifications_workspace_dedupe_uidx'));
    expect(schemaContract, contains('public.create_public_booking_request('));
    expect(
      schemaContract,
      contains('public.create_booking_workflow(jsonb) returns jsonb'),
    );
    expect(
      schemaContract,
      contains('public.complete_booking_workflow(jsonb) returns jsonb'),
    );
    expect(schemaContract, contains('no country-code'));
    expect(schemaContract, contains('inference is performed'));
  });

  test('booking request rows retain member-only RLS and explicit grants', () {
    final policies = _source('supabase/rls_policies.sql');
    final grants = _source(
      'supabase/migrations/'
      '20260725212223_harden_data_api_table_grants.sql',
    );

    expect(
      policies,
      contains(
        'alter table if exists booking_requests enable row level security',
      ),
    );
    expect(policies, contains('on booking_requests for all'));
    expect(policies, contains('to authenticated'));
    expect(
      policies,
      contains('using (app_private.is_workspace_member(workspace_id))'),
    );
    expect(
      policies,
      contains(
        'drop policy if exists "public can create booking requests" '
        'on booking_requests',
      ),
    );
    expect(
      grants,
      contains(
        'revoke all privileges on all tables in schema public from anon',
      ),
    );
    expect(grants, contains('public.booking_requests'));
    expect(grants, contains('to authenticated'));
  });

  test('Edge handler delegates atomic writes and never inserts directly', () {
    final edgeHandler = File(
      'supabase/functions/create-booking-request/index.ts',
    ).readAsStringSync();

    expect(edgeHandler, contains('"create_public_booking_request"'));
    expect(edgeHandler, contains('p_request_token: requestToken'));
    expect(edgeHandler, contains('bookingRequestOutcomeResponse(outcome)'));
    expect(edgeHandler, isNot(contains('.from("booking_requests").insert')));
    expect(edgeHandler, isNot(contains('.from("notifications").insert')));
  });

  test('Flutter retry and triage paths preserve lifecycle guards', () {
    final publicForm = File(
      'lib/features/public_profile/public_profile_screen.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/shared/repositories/profile_repository.dart',
    ).readAsStringSync();

    expect(
      publicForm,
      contains('final String _requestToken = createPublicRequestToken();'),
    );
    expect(publicForm, contains('requestToken: _requestToken'));
    expect(repository, contains(".eq('workspace_id', workspaceId)"));
    expect(repository, contains(".inFilter('status', sourceStatuses)"));
    expect(repository, contains(".select('id')"));
    expect(repository, contains('.maybeSingle()'));
    expect(repository, contains('if (updated == null)'));
  });

  test('booking repository reads page full datasets deterministically', () {
    final appointments = File(
      'lib/shared/repositories/appointments_repository.dart',
    ).readAsStringSync();
    final profiles = File(
      'lib/shared/repositories/profile_repository.dart',
    ).readAsStringSync();

    expect(
      RegExp(
        'fetchAllRepositoryPages<Map<String, dynamic>>',
      ).allMatches(appointments),
      hasLength(4),
    );
    expect(appointments, contains(".order('start_time', ascending: true)"));
    expect(appointments, contains(".order('id', ascending: true)"));
    expect(appointments, contains('.range(from, to)'));
    expect(appointments, contains('.limit(limit)'));
    expect(profiles, contains('fetchAllRepositoryPages<Map<String, dynamic>>'));
    expect(profiles, contains(".order('created_at', ascending: false)"));
    expect(profiles, contains(".order('id', ascending: true)"));
    expect(profiles, contains('.range(from, to)'));
  });
}
