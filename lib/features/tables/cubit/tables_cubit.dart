// features/tables/cubit/tables_cubit.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/reverb_client.dart';
import '../../../core/storage/session_storage.dart';
import '../table_service.dart';
import 'tables_state.dart';

class TablesCubit extends Cubit<TablesState> {
  TablesCubit({TableService? service})
      : _service = service ?? TableService.instance,
        super(const TablesState(isLoading: true));

  final TableService _service;
  Timer? _pollTimer;
  String? _subscribedChannel;
  static const _pollInterval = Duration(seconds: 30);

  void startPolling() {
    _pollTimer?.cancel();
    loadTables();
    _pollTimer = Timer.periodic(_pollInterval, (_) => loadTables(silent: true));

    // Sambungkan ke WebSocket Reverb untuk update denah meja realtime (<100ms)
    final tenantId = SessionStorage.instance.getTenantId();
    final locationId = SessionStorage.instance.getLocationId();

    if (tenantId != null && tenantId.isNotEmpty) {
      final locChannel = locationId != null && locationId.isNotEmpty
          ? 'private-tenant.$tenantId.location.$locationId'
          : 'private-tenant.$tenantId';
      _subscribedChannel = locChannel;

      ReverbClient.instance.connect().then((_) {
        ReverbClient.instance.subscribe(_subscribedChannel!);
        ReverbClient.instance.on('table.status_changed', _onRealtimeTableEvent);
        ReverbClient.instance.on('order.created', _onRealtimeTableEvent);
        ReverbClient.instance.on('order.updated', _onRealtimeTableEvent);
        ReverbClient.instance.on('PosOrderPaid', _onRealtimeTableEvent);
        ReverbClient.instance.on('CafeKitchenOrderCreated', _onRealtimeTableEvent);
        ReverbClient.instance.on('kitchen.order.status_updated', _onRealtimeTableEvent);
      }).catchError((_) {});
    }
  }

  void _onRealtimeTableEvent(Map<String, dynamic> data) {
    debugPrint('🍽️ [TABLES REALTIME] Menerima update status meja via Reverb: $data');
    loadTables(silent: true);
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_subscribedChannel != null) {
      ReverbClient.instance.off('table.status_changed', _onRealtimeTableEvent);
      ReverbClient.instance.off('order.created', _onRealtimeTableEvent);
      ReverbClient.instance.off('order.updated', _onRealtimeTableEvent);
      ReverbClient.instance.off('PosOrderPaid', _onRealtimeTableEvent);
      ReverbClient.instance.off('CafeKitchenOrderCreated', _onRealtimeTableEvent);
      ReverbClient.instance.off('kitchen.order.status_updated', _onRealtimeTableEvent);
      ReverbClient.instance.unsubscribe(_subscribedChannel!);
      _subscribedChannel = null;
    }
  }

  Future<void> loadTables({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoading: state.tables == null, clearError: true));
    }
    try {
      final list = await _service.tables();
      CafeTableInfo? updatedSelected = state.selectedTable;
      if (updatedSelected != null) {
        updatedSelected =
            list.where((t) => t.id == updatedSelected!.id).firstOrNull;
      }

      emit(state.copyWith(
        tables: list,
        selectedTable: updatedSelected,
        clearSelectedTable: updatedSelected == null,
        isLoading: false,
        clearError: true,
      ));

      if (updatedSelected != null) {
        fetchActiveOrderFor(updatedSelected);
      }
    } catch (e) {
      if (!silent) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Gagal memuat denah meja: $e',
        ));
      }
    }
  }

  void setFilter(String filter) {
    emit(state.copyWith(selectedFilter: filter));
  }

  void selectTable(CafeTableInfo? table) {
    if (table == null) {
      emit(state.copyWith(
        clearSelectedTable: true,
        clearActiveOrder: true,
        isLoadingActiveOrder: false,
      ));
      return;
    }
    emit(state.copyWith(selectedTable: table));
    fetchActiveOrderFor(table);
  }

  Future<void> fetchActiveOrderFor(CafeTableInfo table) async {
    if (table.status == TableStatus.available) {
      emit(state.copyWith(
        clearActiveOrder: true,
        isLoadingActiveOrder: false,
      ));
      return;
    }

    emit(state.copyWith(isLoadingActiveOrder: true));
    try {
      final order = await _service.getActiveOrder(table.id);
      if (state.selectedTable?.id == table.id) {
        emit(state.copyWith(
          selectedActiveOrder: order,
          clearActiveOrder: order == null,
          isLoadingActiveOrder: false,
        ));
      }
    } catch (_) {
      if (state.selectedTable?.id == table.id) {
        emit(state.copyWith(
          clearActiveOrder: true,
          isLoadingActiveOrder: false,
        ));
      }
    }
  }

  Future<void> releaseTable(String tableId) async {
    await _service.release(tableId);
    await loadTables();
    if (state.selectedTable?.id == tableId) {
      emit(state.copyWith(
        clearSelectedTable: true,
        clearActiveOrder: true,
      ));
    }
  }

  Future<void> seedDefaultTables() async {
    await _service.seedDefaultTables();
    await loadTables();
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
