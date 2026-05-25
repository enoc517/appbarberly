import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/barber_schedule.dart';
import '../../domain/usecases/get_barber_schedule.dart';
import '../../domain/usecases/set_schedule.dart';
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
  final Set<int> _selectedDays = {};

  String? _pendingStartTime;
  String? _pendingEndTime;

  Set<int> get selectedDays => Set.unmodifiable(_selectedDays);
  String? get pendingStartTime => _pendingStartTime;
  String? get pendingEndTime => _pendingEndTime;

  Future<void> load(String barbershopId, String barberId) async {
    if (barbershopId.isEmpty || barberId.isEmpty) return;

    _barbershopId = barbershopId;
    _barberId = barberId;
    _selectedDays.clear();
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
        return _loadedState();
      },
      fail: (f) => BarberScheduleError(f.message),
    ));
  }

  void toggleDay(int dayOfWeek) {
    if (_selectedDays.contains(dayOfWeek)) {
      _selectedDays.remove(dayOfWeek);
    } else {
      _selectedDays.add(dayOfWeek);
    }
    _emitSelectionChanged();
  }

  void selectPreset(List<int> days) {
    _selectedDays.clear();
    _selectedDays.addAll(days);
    _emitSelectionChanged();
  }

  void _emitSelectionChanged() {
    emit(_loadedState());
  }

  void setPendingTimes(String? startTime, String? endTime) {
    _pendingStartTime = startTime;
    _pendingEndTime = endTime;
    emit(_loadedState());
  }

  Future<void> saveDays() async {
    if (_barbershopId == null || _barberId == null) return;
    if (_selectedDays.isEmpty) return;
    if (_pendingStartTime == null || _pendingEndTime == null) return;

    final startTime24 = _to24h(_pendingStartTime!);
    final endTime24 = _to24h(_pendingEndTime!);

    final futures = <Future>[];
    for (final day in _selectedDays) {
      final params = SetScheduleParams(
        barbershopId: _barbershopId!,
        barberId: _barberId!,
        dayOfWeek: day,
        startTime: startTime24,
        endTime: endTime24,
        isActive: true,
      );
      futures.add(_setSchedule(params));
    }

    await Future.wait(futures);

    for (final day in _selectedDays) {
      _localSchedule[day] = _DaySchedule(
        isActive: true,
        startTime: startTime24,
        endTime: endTime24,
      );
    }

    emit(BarberScheduleDaysSaved(_selectedDays.toList()));

    await Future.delayed(const Duration(milliseconds: 100));
    emit(_loadedState());
  }

  BarberScheduleLoaded _loadedState() {
    return BarberScheduleLoaded(
      schedule: Map.fromEntries(
        _localSchedule.entries.map((e) => MapEntry(
              e.key,
              BarberSchedule(
                id: 'day_${e.key}',
                dayOfWeek: e.key,
                isActive: e.value.isActive,
                startTime: e.value.startTime,
                endTime: e.value.endTime,
              ),
            )),
      ),
      selectedDays: Set.from(_selectedDays),
      pendingStartTime: _pendingStartTime,
      pendingEndTime: _pendingEndTime,
    );
  }

  String _to24h(String time12h) {
    final clean = time12h.trim().toUpperCase();
    final isPM = clean.contains('PM');
    final parts = clean.replaceAll(RegExp(r'[APM\s]'), '').split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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
