import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/core/theme/app_theme.dart';
import 'package:workloop/features/appointments/appointments_screen.dart';
import 'package:workloop/features/clients/clients_screen.dart';
import 'package:workloop/features/finance/finance_screen.dart';
import 'package:workloop/features/more/more_screen.dart';
import 'package:workloop/features/public_profile/booking_requests_screen.dart';
import 'package:workloop/shared/providers/appointments_provider.dart';
import 'package:workloop/shared/providers/clients_provider.dart';
import 'package:workloop/shared/providers/finance_provider.dart';
import 'package:workloop/shared/providers/workspace_settings_provider.dart';
import 'package:workloop/shared/widgets/slate_ui.dart';

void main() {
  testWidgets('shell page headers share one safe-area top position', (
    tester,
  ) async {
    final finance = FinanceSummary.from(
      payments: const [],
      expenses: const [],
      monthlyTarget: 5000,
      now: DateTime(2026, 7, 26),
    );
    final overrides = <Override>[
      clientCrmRecordsProvider.overrideWith((ref) async => const []),
      appointmentsProvider.overrideWith((ref) async => const []),
      bookingRequestsProvider.overrideWith((ref) async => const []),
      invoicesProvider.overrideWith((ref) async => const []),
      expensesProvider.overrideWith((ref) async => const []),
      financeSummaryProvider.overrideWith((ref) async => finance),
      workspaceSettingsProvider.overrideWith(
        (ref) async => const {'revenue_target': 5000},
      ),
    ];
    final screens = <String, Widget>{
      'Clients': const ClientsScreen(),
      'Bookings': const AppointmentsScreen(),
      'Money': const FinanceScreen(),
      'Tools': MoreScreen(
        onOpenMoney: () {},
        onOpenTasks: () {},
        onOpenNotes: () {},
      ),
    };
    final topPositions = <String, double>{};

    for (final screen in screens.entries) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                devicePixelRatio: 1,
                padding: EdgeInsets.only(top: 47, bottom: 34),
                disableAnimations: true,
              ),
              child: screen.value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(WorkloopPageHeader),
        findsOneWidget,
        reason: '${screen.key} must use the canonical shell header',
      );
      topPositions[screen.key] = tester
          .getTopLeft(find.byType(WorkloopPageHeader))
          .dy;
      expect(tester.takeException(), isNull);
    }

    final expectedTop = 47 + AppSpacing.screenTop;
    for (final position in topPositions.entries) {
      expect(
        position.value,
        moreOrLessEquals(expectedTop, epsilon: 0.01),
        reason: '${position.key} header drifted from the shell grid',
      );
    }
  });
}
