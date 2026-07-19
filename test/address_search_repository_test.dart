import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/repositories/address_search_repository.dart';

void main() {
  test('address prediction parses the safe Edge Function projection', () {
    final prediction = AddressPrediction.fromMap({
      'placeId': 'place-123',
      'primaryText': '12 High Street',
      'secondaryText': 'Putney, London SW15, UK',
      'fullText': '12 High Street, Putney, London SW15, UK',
      'unitLabel': 'Flat 28',
      'isPostcode': true,
    });

    expect(prediction.placeId, 'place-123');
    expect(prediction.primaryText, '12 High Street');
    expect(prediction.secondaryText, 'Putney, London SW15, UK');
    expect(prediction.fullText, contains('London'));
    expect(prediction.unitLabel, 'Flat 28');
    expect(prediction.isPostcode, isTrue);
  });

  test('resolved address safely parses optional coordinates', () {
    final address = ResolvedAddress.fromMap({
      'formattedAddress': '12 High Street, Putney, London SW15, UK',
      'latitude': 51.46,
      'longitude': -0.21,
    });

    expect(address.formattedAddress, startsWith('12 High Street'));
    expect(address.latitude, 51.46);
    expect(address.longitude, -0.21);
  });

  test('building-level results retain a typed flat number', () {
    expect(
      preserveAddressUnit(
        formattedAddress: 'Wedgewood Court, London, SW1A 1AA, UK',
        unitLabel: 'Flat 28',
      ),
      'Flat 28, Wedgewood Court, London, SW1A 1AA, UK',
    );
  });

  test('an existing flat label is not duplicated', () {
    expect(
      preserveAddressUnit(
        formattedAddress: 'Flat 28, Wedgewood Court, London, UK',
        unitLabel: 'Flat 28',
      ),
      'Flat 28, Wedgewood Court, London, UK',
    );
  });
}
