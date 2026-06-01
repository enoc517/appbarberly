import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/events/barbershop_event_bus.dart';
import '../../domain/repositories/barbershop_hub_repository.dart';
import 'barbershop_management_hub_state.dart';

class BarbershopManagementHubCubit extends Cubit<BarbershopManagementHubState> {
  BarbershopManagementHubCubit({
    required BarbershopEventBus eventBus,
    required BarbershopHubRepository repository,
    required String userId,
  }) : _eventBus = eventBus,
       _repository = repository,
       _userId = userId,
       super(const BarbershopManagementHubState()) {
    _subscribeToEvents();
    loadBarbershopInfo();
  }

  final BarbershopEventBus _eventBus;
  final BarbershopHubRepository _repository;
  final String _userId;
  late final StreamSubscription<BarbershopEvent> _eventSubscription;

  void _subscribeToEvents() {
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event == BarbershopEvent.barbershopCreated ||
          event == BarbershopEvent.barbershopUpdated) {
        loadBarbershopInfo();
      }
    });
  }

  Future<void> loadBarbershopInfo() async {
    if (_userId.isEmpty) {
      emit(const BarbershopManagementHubState(isLoading: false));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final info = await _repository.getHubInfo(_userId);

      emit(
        state.copyWith(
          isLoading: false,
          hasBarbershop: info.hasBarbershop,
          barbershopId: info.barbershopId,
          barbershopName: info.barbershopName,
          isOwner: info.isOwner,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _eventSubscription.cancel();
    return super.close();
  }
}
