import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_barber_schedule.dart';
import '../../domain/usecases/set_schedule.dart';
import '../../domain/entities/barber_schedule.dart';
import 'barber_schedule_state.dart';

class BarberScheduleCubit extends Cubit<BarberScheduleState> {
  final GetBarberSchedule _getBarberSchedule;
  final SetSchedule _setSchedule;

  BarberScheduleCubit({
    required GetBarberSchedule getBarberSchedule,
    required SetSchedule setSchedule,
  }) : _getBarberSchedule = getBarberSchedule,
       _setSchedule = setSchedule,
       super(const BarberScheduleInitial());

  String? _barbershopId;
  String? _barberId;
  final Map<int, _DaySchedule> _localSchedule = {};

  Future<void> load(String barbershopId, String barberId) async {
    _barbershopId = barbershopId;
    _barberId = barberId;
    emit(const BarberScheduleLoading());
    final result = await _getBarberSchedule(
      GetBarberScheduleParams(barbershopId: barbershopId, barberId: barberId),
    );
    emit(result.when(
      ok: (schedule) {
        _localSchedule.clear();
        for (final s in schedule) {
          _localSchedule[s.dayOfWeek] = _DaySchedule(
            isActive: s.isActive,
            startTime: s.startTime,
            endTime: s.endTime,
          );
        }
        return BarberScheduleLoaded(schedule);
      },
      fail: (f) => BarberScheduleError(f.message),
    ));
  }

  void updateDay(int dayOfWeek, {bool? isActive, String? startTime, String? endTime}) {
    final existing = _localSchedule[dayOfWeek];
    _localSchedule[dayOfWeek] = _DaySchedule(
      isActive: isActive ?? existing?.isActive ?? false,
      startTime: startTime ?? existing?.startTime ?? '',
      endTime: endTime ?? existing?.endTime ?? '',
    );
  }

  Future<void> saveAll() async {
    if (_barbershopId == null || _barberId == null) return;

    for (var i = 1; i <= 7; i++) {
      final day = _localSchedule[i];
      if (day == null) continue;

      final params = SetScheduleParams(
        barbershopId: _barbershopId!,
        barberId: _barberId!,
        dayOfWeek: i,
        startTime: day.startTime,
        endTime: day.endTime,
        isActive: day.isActive,
      );
      await _setSchedule(params);
    }

    emit(const BarberScheduleSaved());
    if (_barbershopId != null && _barberId != null) {
      load(_barbershopId!, _barberId!);
    }
  }

  BarberSchedule? getDaySchedule(int dayOfWeek) {
    final day = _localSchedule[dayOfWeek];
    if (day == null) return null;
    return BarberSchedule(
      id: '',
      dayOfWeek: dayOfWeek,
      isActive: day.isActive,
      startTime: day.startTime,
      endTime: day.endTime,
    );
  }
}

class _DaySchedule {
  final bool isActive;
  final String startTime;
  final String endTime;

  const _DaySchedule({
    required this.isActive,
    required this.startTime,
    required this.endTime,
  });
}
