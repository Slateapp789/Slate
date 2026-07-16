import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/repositories/auth_repository.dart';

void main() {
  group('firstNameFromUserMetadata', () {
    test('prefers the explicit first name', () {
      expect(
        firstNameFromUserMetadata({
          'first_name': 'Ash',
          'full_name': 'Different Name',
        }),
        'Ash',
      );
    });

    test('extracts the first word from legacy name fields', () {
      expect(firstNameFromUserMetadata({'full_name': 'Ash Morgan'}), 'Ash');
    });

    test('returns null when no usable name exists', () {
      expect(firstNameFromUserMetadata({'first_name': '  '}), isNull);
      expect(firstNameFromUserMetadata(null), isNull);
    });
  });
}
