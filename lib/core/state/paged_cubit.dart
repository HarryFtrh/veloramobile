import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/api_exception.dart';
import 'paged_result.dart';

/// State daftar berhalaman: muat awal, muat lanjutan, dan gagal.
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.extra,
  });

  final List<T> items;
  final int page;
  final bool hasMore;

  /// Memuat halaman pertama (layar penuh).
  final bool loading;

  /// Memuat halaman berikutnya (indikator di bawah daftar).
  final bool loadingMore;
  final String? error;
  final Object? extra;

  PagedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    Object? extra,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      extra: extra ?? this.extra,
    );
  }
}

typedef PageFetcher<T> = Future<PagedResult<T>> Function(int page);

/// Cubit generik untuk daftar berhalaman. Fetcher diberikan pemanggil,
/// jadi filter dan pencarian cukup ditutup di dalam closure.
class PagedCubit<T> extends Cubit<PagedState<T>> {
  PagedCubit(this._fetch) : super(const PagedState());

  PageFetcher<T> _fetch;

  /// Ganti fetcher (mis. saat filter berubah) lalu muat ulang dari awal.
  Future<void> reload([PageFetcher<T>? fetcher]) async {
    if (fetcher != null) _fetch = fetcher;
    emit(PagedState<T>(loading: true, extra: state.extra));
    try {
      final result = await _fetch(1);
      emit(PagedState<T>(
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
        extra: result.extra,
      ));
    } catch (e) {
      emit(PagedState<T>(
        hasMore: false,
        error: ApiException.from(e).message,
        extra: state.extra,
      ));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore || state.error != null) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _fetch(state.page + 1);
      emit(state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        hasMore: result.hasMore,
        loadingMore: false,
      ));
    } catch (e) {
      // Daftar yang sudah tampil dipertahankan; hanya hentikan paginasi
      // dan simpan pesan agar UI bisa menawarkan coba lagi.
      emit(state.copyWith(
        loadingMore: false,
        hasMore: false,
        error: ApiException.from(e).message,
      ));
    }
  }
}
