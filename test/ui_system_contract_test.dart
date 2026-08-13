import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final visualFiles = <File>[
    ...Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
    File('lib/shared/widgets/slate_ui.dart'),
  ];

  test('user-facing UI does not introduce a second raw colour system', () {
    final violations = <String>[];
    final rawColour = RegExp(r'Color\(0x(?:FF|ff)');

    for (final file in visualFiles) {
      if (rawColour.hasMatch(file.readAsStringSync())) {
        violations.add(file.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature UI must use WorkloopThemeTokens or the canonical AppColors aliases.',
    );
  });

  test(
    'interface typography does not introduce ultra-heavy display weights',
    () {
      final violations = <String>[];
      final heavyWeight = RegExp(r'FontWeight\.(?:w800|w900)');

      for (final file in visualFiles) {
        if (heavyWeight.hasMatch(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Studio uses 700 only for intentional display and metric hierarchy.',
      );
    },
  );

  test('controls use named Studio geometry instead of magic pill values', () {
    final violations = <String>[];
    final retiredGeometry = RegExp(
      r'AppRadius\.pill|BorderRadius\.circular\(999\)',
    );

    for (final file in visualFiles) {
      if (retiredGeometry.hasMatch(file.readAsStringSync())) {
        violations.add(file.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use AppRadius.capsule for compact statuses and filters, and the Studio radius scale elsewhere.',
    );
  });

  test(
    'feature motion either responds to reduced motion or handles it explicitly',
    () {
      final violations = <String>[];
      final directMotion = RegExp(
        r'duration:\s*AppMotion\.(?:fast|standard|deliberate)\b',
      );
      final explicitReducedMotion = RegExp(
        r'MediaQuery\.(?:disableAnimationsOf|maybeOf\(context\)\?\.disableAnimations)',
      );

      for (final file in visualFiles) {
        final source = file.readAsStringSync();
        if (directMotion.hasMatch(source) &&
            !explicitReducedMotion.hasMatch(source)) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Use AppMotion.responsive for presentation motion, or explicitly jump to the stable state.',
      );
    },
  );
}
