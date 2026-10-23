import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/paged_cubit.dart';
import 'components.dart';
import 'tokens.dart';

/// Daftar berhalaman dengan seluruh state umum sudah ditangani:
/// skeleton saat muat awal, tampilan kosong, error + coba lagi,
/// muat otomatis di akhir daftar, dan tarik-untuk-refresh.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.itemBuilder,
    required this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.header,
  });

  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  /// Ditampilkan di atas daftar dan ikut ter-scroll (mis. kartu statistik).
  final Widget Function(BuildContext context, PagedState<T> state)? header;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  static const double _loadMoreThreshold = 240;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < _loadMoreThreshold) {
      context.read<PagedCubit<T>>().loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PagedCubit<T>>();
    return BlocBuilder<PagedCubit<T>, PagedState<T>>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return const SkeletonList();
        }
        if (state.error != null && state.items.isEmpty) {
          return ErrorState(message: state.error!, onRetry: cubit.reload);
        }

        final header = widget.header?.call(context, state);
        final empty = state.items.isEmpty;

        return RefreshIndicator(
          onRefresh: cubit.reload,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Gap.lg),
              itemCount: (header != null ? 1 : 0) + (empty ? 1 : state.items.length) + 1,
              separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
              itemBuilder: (context, index) {
                if (header != null) {
                  if (index == 0) return header;
                  index -= 1;
                }
                if (empty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: Gap.xxl),
                    child: EmptyState(
                      icon: widget.emptyIcon,
                      title: widget.emptyTitle,
                      message: widget.emptyMessage,
                    ),
                  );
                }
                if (index < state.items.length) {
                  return widget.itemBuilder(context, state.items[index]);
                }
                return _Footer(state: state, onRetry: cubit.loadMore);
              },
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final PagedState<dynamic> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Gap.lg),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.error != null && state.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.sm),
        child: Column(
          children: [
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.danger),
            ),
            TextButton(onPressed: onRetry, child: const Text('Muat lagi')),
          ],
        ),
      );
    }
    return const SizedBox(height: Gap.sm);
  }
}
