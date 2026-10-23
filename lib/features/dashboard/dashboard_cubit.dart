import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import 'dashboard_service.dart';

enum DashboardRange {
  today('Hari ini', 0),
  week('7 hari', 6),
  month('30 hari', 29);

  const DashboardRange(this.label, this.daysBack);

  final String label;
  final int daysBack;
}

sealed class DashboardState {
  const DashboardState(this.range);
  final DashboardRange range;
}

class DashboardLoading extends DashboardState {
  const DashboardLoading(super.range);
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(super.range, this.summary);
  final DashboardSummary summary;
}

class DashboardFailed extends DashboardState {
  const DashboardFailed(super.range, this.message);
  final String message;
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({DashboardService? service})
      : _service = service ?? DashboardService.instance,
        super(const DashboardLoading(DashboardRange.week));

  final DashboardService _service;

  Future<void> load([DashboardRange? range]) async {
    final selected = range ?? state.range;
    emit(DashboardLoading(selected));

    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(Duration(days: selected.daysBack));

    try {
      final summary = await _service.load(start: start, end: end);
      emit(DashboardLoaded(selected, summary));
    } catch (e) {
      emit(DashboardFailed(selected, ApiException.from(e).message));
    }
  }
}
