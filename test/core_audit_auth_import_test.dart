import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/features/auth/auth_validation.dart';
import 'package:workloop/features/imports/import_models.dart';

void main() {
  group('core audit auth validation', () {
    test('accepts real email shapes and rejects malformed lookalikes', () {
      expect(isValidAuthEmail('owner+bookings@example.co.uk'), isTrue);
      expect(isValidAuthEmail(' owner@example.com '), isTrue);

      for (final value in [
        'owner',
        'owner@example',
        'owner@.com',
        '@example.com',
        'owner @example.com',
        'owner@example .com',
      ]) {
        expect(isValidAuthEmail(value), isFalse, reason: value);
      }
    });

    test('applies password rules only to the relevant auth intent', () {
      expect(
        validateAuthForm(
          email: 'owner@example.com',
          password: 'short',
          intent: AuthFormIntent.signIn,
        ),
        isNull,
        reason: 'Existing accounts may predate the current signup minimum.',
      );
      expect(
        validateAuthForm(
          email: 'owner@example.com',
          password: 'short',
          intent: AuthFormIntent.signUp,
        ),
        workloopPasswordLengthMessage,
      );
      expect(
        validateAuthForm(
          email: 'owner@example.com',
          password: 'long password only',
          intent: AuthFormIntent.signUp,
        ),
        workloopPasswordStrengthMessage,
      );
      expect(
        validateAuthForm(
          email: 'owner@example.com',
          password: '',
          intent: AuthFormIntent.resetPassword,
        ),
        isNull,
      );
    });

    test('new password comparison preserves significant whitespace', () {
      expect(
        validateNewPasswordPair(' Long password 2! ', ' Long password 2! '),
        isNull,
      );
      expect(
        validateNewPasswordPair(' Long password 2! ', 'Long password 2!'),
        'The passwords do not match.',
      );
    });

    test('maps known auth failures without leaking backend copy', () {
      expect(
        friendlyAuthErrorMessage('Invalid login credentials'),
        'Wrong email or password.',
      );
      expect(
        friendlyAuthErrorMessage('Email rate limit exceeded'),
        'Too many attempts. Please wait a moment and try again.',
      );
      expect(
        friendlyAuthErrorMessage('internal provider detail'),
        isNot(contains('internal provider detail')),
      );
    });
  });

  group('core audit CSV boundaries', () {
    test('legacy carriage-return task lists remain line separated', () {
      expect(
        taskTitlesFromImportText('First task\rSecond task\r\nThird task'),
        ['First task', 'Second task', 'Third task'],
      );
    });

    test('detects delimiters outside quoted header text', () {
      final table = parseCsv('"Name, preferred";Phone\n"Ada, A.";07123 456789');

      expect(table.delimiter, ';');
      expect(table.headers, ['Name, preferred', 'Phone']);
      expect(table.rows.single, ['Ada, A.', '07123 456789']);
    });

    test('rejects an unclosed quote instead of importing corrupted rows', () {
      expect(
        () => parseCsv('Name,Notes\nAda,"unfinished'),
        throwsFormatException,
      );
    });

    test('rejects extra unlabelled columns instead of truncating data', () {
      expect(
        () => parseCsv('Name,Phone\nAda,07123,unexpected'),
        throwsFormatException,
      );
    });
  });
}
