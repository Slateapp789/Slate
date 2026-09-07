import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One clock for time-sensitive views. Ticks update derived values only;
/// repositories continue to use their existing cached workspace reads.
final businessClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

final businessNowProvider = Provider<DateTime>((ref) {
  return ref.watch(businessClockProvider).value ?? DateTime.now();
});

/// Date-based totals need recalculating at midnight, not on every clock tick.
final businessTodayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(businessNowProvider).toLocal();
  return DateTime(now.year, now.month, now.day);
});
