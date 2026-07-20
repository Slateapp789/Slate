import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/imports/import_models.dart';

void main() {
  group('parseCsv', () {
    test('parses quoted commas and escaped quotes', () {
      final table = parseCsv(
        'Name,Notes,Email\n"Ava Mitchell","Said ""hello"", then left",ava@example.com',
      );

      expect(table.headers, ['Name', 'Notes', 'Email']);
      expect(table.rows, hasLength(1));
      expect(table.rows.single[0], 'Ava Mitchell');
      expect(table.rows.single[1], 'Said "hello", then left');
      expect(table.rows.single[2], 'ava@example.com');
    });

    test('detects semicolon-delimited files and ignores empty rows', () {
      final table = parseCsv('Name;Phone\r\nAva;07123\r\n\r\n');

      expect(table.delimiter, ';');
      expect(table.rows, [
        ['Ava', '07123'],
      ]);
    });
  });

  group('duplicate detection', () {
    final existing = [
      (name: 'Ava Mitchell', phone: '07123 456 789', email: 'ava@example.com'),
    ];

    test('matches normalised email', () {
      const candidate = ImportCandidate(
        sourceId: '1',
        name: 'Different name',
        email: ' AVA@example.com ',
      );

      expect(
        isLikelyDuplicate(candidate: candidate, existing: existing),
        isTrue,
      );
    });

    test('matches formatted phone numbers', () {
      const candidate = ImportCandidate(
        sourceId: '2',
        name: 'Different name',
        phone: '07123-456-789',
      );

      expect(
        isLikelyDuplicate(candidate: candidate, existing: existing),
        isTrue,
      );
    });

    test('does not match unrelated records', () {
      const candidate = ImportCandidate(
        sourceId: '3',
        name: 'Maya Lewis',
        phone: '07999 111 222',
      );

      expect(
        isLikelyDuplicate(candidate: candidate, existing: existing),
        isFalse,
      );
    });
  });
}
