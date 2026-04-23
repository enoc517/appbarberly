import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_data.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardData _getData;

  DashboardCubit(this._getData) : super(const DashboardLoading());

  Future<void> load(String barberId) async {
    emit(const DashboardLoading());
    final result = await _getData(barberId);
    emit(result.when(
      ok: (d) => DashboardLoaded(d),
      fail: (f) => DashboardError(f.message),
    ));
  }

  Future<void> refresh(String barberId) => load(barberId);
}