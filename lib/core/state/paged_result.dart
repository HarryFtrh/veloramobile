/// Halaman hasil dari endpoint yang memakai paginasi Laravel.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.lastPage,
    this.extra,
  });

  final List<T> items;
  final int page;
  final int lastPage;

  /// Data pendamping dari halaman pertama (mis. statistik anggota).
  final Object? extra;

  bool get hasMore => page < lastPage;
}
