import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/reverb_client.dart';
import '../../core/storage/session_storage.dart';
import 'kitchen_service.dart';

sealed class KitchenState {
  const KitchenState();
}

class KitchenLoading extends KitchenState {
  const KitchenLoading();
}

class KitchenLoaded extends KitchenState {
  const KitchenLoaded(this.orders, {this.station, this.actionError});
  final List<KitchenOrder> orders;

  /// Filter station (nama kategori). `null` = semua.
  final String? station;

  /// Pesan galat dari aksi terakhir (mis. gagal menandai siap). Ditampilkan sekali.
  final String? actionError;

  List<String> get stations =>
      orders.expand((o) => o.items).map((i) => i.station).where((s) => s.isNotEmpty).toSet().toList()..sort();

  List<KitchenOrder> byStage(KitchenStage stage) {
    final list = orders.where((o) => o.stage == stage).toList();
    final filtered = station == null
        ? list
        : list.where((o) => o.items.any((i) => i.station == station)).toList();
    filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  KitchenLoaded copyWith({List<KitchenOrder>? orders, Object? station = _keep, String? actionError}) =>
      KitchenLoaded(
        orders ?? this.orders,
        station: identical(station, _keep) ? this.station : station as String?,
        actionError: actionError,
      );
}

const Object _keep = Object();

class KitchenFailed extends KitchenState {
  const KitchenFailed(this.message);
  final String message;
}

class KitchenCubit extends Cubit<KitchenState> {
  KitchenCubit({KitchenService? service})
      : _service = service ?? KitchenService.instance,
        super(const KitchenLoading());

  /// Interval penyegaran otomatis layar dapur.
  static const pollInterval = Duration(seconds: 6);

  final KitchenService _service;
  Timer? _timer;
  String? _subscribedChannel;

  void start() {
    refresh(silent: false);
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => refresh());

    // Berlangganan event websocket jika Reverb terkonfigurasi
    final locationId = SessionStorage.instance.getLocationId();
    if (locationId != null && locationId.isNotEmpty) {
      _subscribedChannel = 'kitchen.$locationId';
      ReverbClient.instance.connect().then((_) {
        ReverbClient.instance.subscribe(_subscribedChannel!);
        ReverbClient.instance.on('order.created', _onRealtimeOrderEvent);
        ReverbClient.instance.on('order.updated', _onRealtimeOrderEvent);
      }).catchError((_) {});
    }
  }

  void _onRealtimeOrderEvent(Map<String, dynamic> data) {
    refresh();
  }

  Future<void> refresh({bool silent = true}) async {
    if (!silent) emit(const KitchenLoading());
    try {
      final orders = await _service.load();
      final current = state;
      emit(KitchenLoaded(orders, station: current is KitchenLoaded ? current.station : null));
    } catch (e) {
      // Polling yang gagal tidak boleh menimpa data yang sudah tampil.
      if (state is! KitchenLoaded) emit(KitchenFailed(ApiException.from(e).message));
    }
  }

  void filterStation(String? station) {
    final current = state;
    if (current is KitchenLoaded) emit(current.copyWith(station: station));
  }

  Future<void> advance(KitchenOrder order) async {
    await _run(() => switch (order.stage) {
          KitchenStage.fresh => _service.start(order.id),
          KitchenStage.preparing => _service.markReady(order.id),
          KitchenStage.ready => _service.markServed(order.id),
        });
  }

  Future<void> toggleItem(KitchenOrder order, KitchenItem item) async {
    final current = state;
    if (current is! KitchenLoaded) return;
    // Optimistic update, dikembalikan bila server menolak.
    final optimistic = current.orders
        .map((o) => o.id != order.id
            ? o
            : o.copyWith(items: o.items.map((i) => i.id == item.id ? i.copyWith(done: !i.done) : i).toList()))
        .toList();
    emit(current.copyWith(orders: optimistic));
    try {
      await _service.toggleItemDone(order.id, item.id);
    } catch (e) {
      emit(current.copyWith(actionError: ApiException.from(e).message));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await refresh();
    } catch (e) {
      final current = state;
      if (current is KitchenLoaded) emit(current.copyWith(actionError: ApiException.from(e).message));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    if (_subscribedChannel != null) {
      ReverbClient.instance.off('order.created', _onRealtimeOrderEvent);
      ReverbClient.instance.off('order.updated', _onRealtimeOrderEvent);
      ReverbClient.instance.unsubscribe(_subscribedChannel!);
    }
    return super.close();
  }
}
