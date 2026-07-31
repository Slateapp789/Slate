const repositoryFetchPageSize = 500;

typedef RepositoryPageLoader<T> =
    Future<List<T>> Function(int fromInclusive, int toInclusive);

/// Retrieves every row from a deterministically ordered Supabase query.
///
/// Supabase/PostgREST applies a server-side maximum row count to an individual
/// response. Callers must apply a stable order before `range` so page
/// boundaries cannot move while the result is assembled.
Future<List<T>> fetchAllRepositoryPages<T>({
  required RepositoryPageLoader<T> loadPage,
  int pageSize = repositoryFetchPageSize,
}) async {
  if (pageSize < 1 || pageSize > 1000) {
    throw RangeError.range(pageSize, 1, 1000, 'pageSize');
  }

  final results = <T>[];
  var from = 0;
  while (true) {
    final page = await loadPage(from, from + pageSize - 1);
    if (page.length > pageSize) {
      throw StateError(
        'Repository page loader returned ${page.length} rows for a '
        '$pageSize-row range.',
      );
    }
    results.addAll(page);
    if (page.length < pageSize) return results;
    from += pageSize;
  }
}
