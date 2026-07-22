import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/features/clients/widgets/client_form.dart';
import 'package:workloop/shared/repositories/address_search_repository.dart';

class _FakeAddressSearchRepository extends AddressSearchRepository {
  _FakeAddressSearchRepository()
    : super(SupabaseClient('https://example.supabase.co', 'test-anon-key'));

  String lastInput = '';

  @override
  Future<List<AddressPrediction>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    lastInput = input;
    if (input.toUpperCase() == 'HD1 5HD') {
      return const [
        AddressPrediction(
          placeId: 'postcode',
          primaryText: 'HD1 5HD',
          secondaryText: 'Tanfield Road, Birkby, Huddersfield',
          fullText: 'HD1 5HD, UK',
          isPostcode: true,
        ),
      ];
    }
    return List.generate(
      5,
      (index) => AddressPrediction(
        placeId: 'place-$index',
        primaryText: index == 0
            ? '57 Tanfield Road'
            : '${index + 1} Tanfield Avenue',
        secondaryText: 'Huddersfield',
        fullText: index == 0
            ? '57 Tanfield Road, Huddersfield, HD1 5HD, UK'
            : '${index + 1} Tanfield Avenue, Huddersfield, UK',
      ),
    );
  }

  @override
  Future<ResolvedAddress> resolve({
    required String placeId,
    required String sessionToken,
  }) async {
    if (placeId == 'postcode') {
      return const ResolvedAddress(formattedAddress: 'HD1 5HD, UK');
    }
    return const ResolvedAddress(
      formattedAddress: '57 Tanfield Road, Huddersfield, HD1 5HD, UK',
    );
  }
}

void main() {
  late TextEditingController controller;
  late _FakeAddressSearchRepository repository;

  setUp(() {
    controller = TextEditingController();
    repository = _FakeAddressSearchRepository();
  });

  tearDown(() => controller.dispose());

  Future<void> pumpField(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addressSearchRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  BookingAddressField(controller: controller, onChanged: () {}),
                  const SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('suggestions survive dragging and selection fills the field', (
    tester,
  ) async {
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), '57 Tanfield');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(find.text('57 Tanfield Road'), findsOneWidget);
    await tester.dragFrom(const Offset(350, 500), const Offset(0, -45));
    await tester.pump();
    expect(find.text('Google Maps'), findsOneWidget);
    await tester.dragFrom(const Offset(350, 500), const Offset(0, 45));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -45));
    await tester.pump();
    expect(find.text('Google Maps'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 45));
    await tester.pump();

    await tester.tap(find.text('57 Tanfield Road'));
    await tester.pumpAndSettle();

    expect(controller.text, '57 Tanfield Road, Huddersfield, HD1 5HD, UK');
    expect(find.text('Google Maps'), findsNothing);
  });

  testWidgets('postcode remains a normal single-field value', (tester) async {
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), 'HD1 5HD');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    await tester.tap(find.text('HD1 5HD').last);
    await tester.pumpAndSettle();

    expect(controller.text, 'HD1 5HD, UK');
    expect(find.text('House number or building'), findsNothing);
  });

  testWidgets('typed postcode can be kept manually without selecting it', (
    tester,
  ) async {
    await pumpField(tester);
    await tester.enterText(find.byType(TextField), 'HD1 5HD');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(controller.text, 'HD1 5HD');
    expect(find.text('House number or building'), findsNothing);
  });
}
