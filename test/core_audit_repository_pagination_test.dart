import 'package:flutter_test/flutter_test.dart';
import 'package:workloop/shared/repositories/repository_pagination.dart';

void main() {
  group('repository page-through retrieval', () {
    test('stops immediately on an empty first page', () async {
      final ranges = <(int, int)>[];

      final result = await fetchAllRepositoryPages<int>(
        loadPage: (from, to) async {
          ranges.add((from, to));
          return const [];
        },
      );

      expect(result, isEmpty);
      expect(ranges, [(0, 499)]);
    });

    test('preserves row order across multiple pages', () async {
      final source = List.generate(1201, (index) => index);
      final ranges = <(int, int)>[];

      final result = await fetchAllRepositoryPages<int>(
        loadPage: (from, to) async {
          ranges.add((from, to));
          if (from >= source.length) return const [];
          final endExclusive = (to + 1).clamp(0, source.length);
          return source.sublist(from, endExclusive);
        },
      );

      expect(result, source);
      expect(ranges, [(0, 499), (500, 999), (1000, 1499)]);
    });

    test('checks one empty page after an exact page boundary', () async {
      final source = List.generate(1000, (index) => 'row-$index');
      final ranges = <(int, int)>[];

      final result = await fetchAllRepositoryPages<String>(
        loadPage: (from, to) async {
          ranges.add((from, to));
          if (from >= source.length) return const [];
          return source.sublist(from, (to + 1).clamp(0, source.length));
        },
      );

      expect(result, source);
      expect(ranges, [(0, 499), (500, 999), (1000, 1499)]);
    });

    test('allows bounded page sizes and rejects unsafe values', () async {
      expect(
        await fetchAllRepositoryPages<int>(
          pageSize: 1000,
          loadPage: (_, _) async => const [],
        ),
        isEmpty,
      );
      expect(
        () => fetchAllRepositoryPages<int>(
          pageSize: 0,
          loadPage: (_, _) async => const [],
        ),
        throwsRangeError,
      );
      expect(
        () => fetchAllRepositoryPages<int>(
          pageSize: 1001,
          loadPage: (_, _) async => const [],
        ),
        throwsRangeError,
      );
    });

    test('rejects a loader that violates the requested range size', () {
      expect(
        () => fetchAllRepositoryPages<int>(
          pageSize: 2,
          loadPage: (_, _) async => [1, 2, 3],
        ),
        throwsStateError,
      );
    });
  });
}
