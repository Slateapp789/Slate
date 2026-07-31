import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/workloop_app_info.dart';
import 'package:workloop/features/auth/password_recovery_screen.dart';
import 'package:workloop/shared/providers/onboarding_provider.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';
import 'package:workloop/shared/repositories/onboarding_repository.dart';
import 'package:workloop/shared/repositories/privacy_repository.dart';
import 'package:workloop/shared/utils/public_profile_routes.dart';

void main() {
  test('support version label follows installed artifact metadata', () {
    final originalVersion = WorkloopAppInfo.version;
    final originalBuild = WorkloopAppInfo.buildNumber;
    addTearDown(() {
      WorkloopAppInfo.version = originalVersion;
      WorkloopAppInfo.buildNumber = originalBuild;
    });

    WorkloopAppInfo.version = '2.4.0';
    WorkloopAppInfo.buildNumber = '314';

    expect(WorkloopAppInfo.versionLabel, '2.4.0 (314)');
  });

  test('password recovery uses the registered application scheme', () {
    expect(workloopPasswordRecoveryRedirect, 'workloop://reset-password');
    expect(validateRecoveryPassword('short', 'short'), isNotNull);
    expect(
      validateRecoveryPassword('safe-password', 'different-password'),
      isNotNull,
    );
    expect(validateRecoveryPassword('safe-password', 'safe-password'), isNull);
    expect(
      validateRecoveryPassword(' password ', ' password '),
      isNull,
      reason: 'Leading and trailing password characters are significant.',
    );
  });

  test('onboarding draft keys are isolated by auth user', () {
    expect(
      onboardingDraftKeyForUser('user-one'),
      isNot(onboardingDraftKeyForUser('user-two')),
    );
    expect(
      onboardingDraftKeyForUser('user-one'),
      startsWith('$legacyOnboardingDraftKey.user.'),
    );
  });

  test('onboarding RPC payload uses server contract field names', () {
    final params = buildOnboardingRpcParams(
      businessName: ' Workloop Studio ',
      industry: 'Wellness',
      handle: 'Workloop-Studio',
      services: const [
        {'name': 'Session', 'duration': 45, 'price': 65},
      ],
      workingHours: const {'monday': []},
      revenueTarget: 5000,
      firstBooking: const {
        'clientName': 'Alex',
        'serviceName': 'Session',
        'date': '2026-07-25',
        'hour': 10,
        'minute': 30,
      },
    );

    expect(params['business_name'], 'Workloop Studio');
    expect(params['profile_handle'], 'workloop-studio');
    expect(
      (params['service_rows'] as List).single,
      containsPair('duration_mins', 45),
    );
    expect(
      params['first_booking_value'],
      allOf(
        containsPair('client_name', 'Alex'),
        containsPair('service_name', 'Session'),
      ),
    );
  });

  test('reserved application routes cannot become public handles', () {
    expect(isReservedPublicHandle('clients'), isTrue);
    expect(isReservedPublicHandle('Privacy'), isTrue);
    expect(isReservedPublicHandle('settings'), isTrue);
    expect(isReservedPublicHandle('api'), isTrue);
    expect(isReservedPublicHandle('alex-studio'), isFalse);
  });

  test('privacy export manifest contains every workspace data table', () {
    expect(privacyExportPageSize, 1000);
    expect(
      workspacePrivacyExportTables,
      containsAll(const {
        'workspaces',
        'workspace_members',
        'workspace_settings',
        'business_profiles',
        'expenses',
        'notes',
        'task_checklist_items',
        'invoice_line_items',
        'notification_preferences',
        'account_deletion_requests',
      }),
    );
  });
}
