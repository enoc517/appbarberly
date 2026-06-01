import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/penalty.dart';
import '../../domain/repositories/penalties_repository.dart';

sealed class PenaltiesState {
  const PenaltiesState();
}

class PenaltiesLoading extends PenaltiesState {
  const PenaltiesLoading();
}

class PenaltiesLoaded extends PenaltiesState {
  const PenaltiesLoaded(this.penalties);

  final List<Penalty> penalties;
}

class PenaltiesEmpty extends PenaltiesState {
  const PenaltiesEmpty();
}

class PenaltiesError extends PenaltiesState {
  const PenaltiesError(this.message);

  final String message;
}

class PenaltiesCubit extends Cubit<PenaltiesState> {
  PenaltiesCubit({
    required PenaltiesRepository repository,
    required String barbershopId,
  }) : _repository = repository,
       _barbershopId = barbershopId,
       super(const PenaltiesLoading());

  final PenaltiesRepository _repository;
  final String _barbershopId;
  StreamSubscription<List<Penalty>>? _subscription;

  void watch() {
    if (_barbershopId.isEmpty) {
      emit(const PenaltiesEmpty());
      return;
    }

    _subscription?.cancel();
    _subscription = _repository
        .watchPendingPenalties(_barbershopId)
        .listen(
          (penalties) => emit(
            penalties.isEmpty
                ? const PenaltiesEmpty()
                : PenaltiesLoaded(penalties),
          ),
          onError: (_) => emit(
            const PenaltiesError('No se pudieron cargar las penalizaciones'),
          ),
        );
  }

  Future<void> markAsPaid(Penalty penalty) async {
    try {
      await _repository.markAsPaid(penalty.id);
    } catch (_) {
      emit(const PenaltiesError('No se pudo marcar como pagada'));
    }
  }

  Future<void> waive(Penalty penalty) async {
    try {
      await _repository.waive(penalty.id);
    } catch (_) {
      emit(const PenaltiesError('No se pudo perdonar la penalización'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
