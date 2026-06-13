import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/events/barbershop_event_bus.dart';
import '../../domain/usecases/get_dashboard_data.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required GetDashboardData getData,
    required BarbershopEventBus eventBus,
  }) : _getData = getData,
       _eventBus = eventBus,
       super(const DashboardLoading()) {
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event == BarbershopEvent.bookingUpdated) {
        final barberId = _barberId;
        if (barberId != null && barberId.isNotEmpty) {
          refresh(barberId);
        }
      }
    });
  }

  final GetDashboardData _getData;
  final BarbershopEventBus _eventBus;
  late final StreamSubscription<BarbershopEvent> _eventSubscription;
  String? _barberId;

  Future<void> load(String barberId) async {
    _barberId = barberId;
    emit(const DashboardLoading());
    final result = await _getData(barberId);
    emit(result.when(
      ok: (d) => DashboardLoaded(d),
      fail: (f) => DashboardError(f.message),
    ));
  }

  Future<void> refresh(String barberId) async {
    _barberId = barberId;
    final result = await _getData(barberId);
    emit(result.when(
      ok: (d) => DashboardLoaded(d),
      fail: (f) => DashboardError(f.message),
    ));
  }

  @override
  Future<void> close() async {
    await _eventSubscription.cancel();
    return super.close();
  }
}
