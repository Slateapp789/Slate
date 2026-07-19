import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/main.dart';

void main() {
  test('launch timing fills only the remaining minimum duration', () {
    expect(
      remainingLaunchDuration(const Duration(milliseconds: 400)),
      const Duration(milliseconds: 1000),
    );
    expect(
      remainingLaunchDuration(const Duration(milliseconds: 1400)),
      Duration.zero,
    );
    expect(
      remainingLaunchDuration(const Duration(milliseconds: 2000)),
      Duration.zero,
    );
  });
}
