import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/main.dart';

void main() {
  test('launch timing fills only the remaining minimum duration', () {
    expect(
      remainingLaunchDuration(const Duration(milliseconds: 250)),
      const Duration(milliseconds: 450),
    );
    expect(
      remainingLaunchDuration(const Duration(milliseconds: 700)),
      Duration.zero,
    );
    expect(
      remainingLaunchDuration(const Duration(milliseconds: 2000)),
      Duration.zero,
    );
  });
}
