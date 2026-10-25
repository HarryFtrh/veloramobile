// features/tables/cubit/tables_state.dart
import 'package:equatable/equatable.dart';

import '../table_service.dart';

class TablesState extends Equatable {
  const TablesState({
    this.tables,
    this.selectedFilter = 'all',
    this.selectedTable,
    this.selectedActiveOrder,
    this.isLoadingActiveOrder = false,
    this.isLoading = false,
    this.error,
  });

  final List<CafeTableInfo>? tables;
  final String selectedFilter;
  final CafeTableInfo? selectedTable;
  final ActiveTableOrder? selectedActiveOrder;
  final bool isLoadingActiveOrder;
  final bool isLoading;
  final String? error;

  List<CafeTableInfo> get tableList => tables ?? const [];

  List<CafeTableInfo> get filteredTables {
    final list = tableList;
    if (selectedFilter == 'all') return list;
    return list.where((t) {
      if (selectedFilter == 'available') return t.status == TableStatus.available;
      if (selectedFilter == 'occupied') {
        return t.status == TableStatus.occupied || t.status == TableStatus.ordered;
      }
      if (selectedFilter == 'reserved') return t.status == TableStatus.reserved;
      return true;
    }).toList();
  }

  int get countAll => tableList.length;
  int get countAvailable =>
      tableList.where((t) => t.status == TableStatus.available).length;
  int get countOccupied => tableList
      .where((t) => t.status == TableStatus.occupied || t.status == TableStatus.ordered)
      .length;
  int get countReserved =>
      tableList.where((t) => t.status == TableStatus.reserved).length;

  TablesState copyWith({
    List<CafeTableInfo>? tables,
    String? selectedFilter,
    CafeTableInfo? selectedTable,
    bool clearSelectedTable = false,
    ActiveTableOrder? selectedActiveOrder,
    bool clearActiveOrder = false,
    bool? isLoadingActiveOrder,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedTable: clearSelectedTable ? null : (selectedTable ?? this.selectedTable),
      selectedActiveOrder:
          clearActiveOrder ? null : (selectedActiveOrder ?? this.selectedActiveOrder),
      isLoadingActiveOrder: isLoadingActiveOrder ?? this.isLoadingActiveOrder,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        tables,
        selectedFilter,
        selectedTable,
        selectedActiveOrder,
        isLoadingActiveOrder,
        isLoading,
        error,
      ];
}
