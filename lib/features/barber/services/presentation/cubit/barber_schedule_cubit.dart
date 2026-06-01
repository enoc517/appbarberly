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

  Set<int> get selectedDays =>
      state is BarberScheduleLoaded
          ? (state as BarberScheduleLoaded).selectedDays
          : <int>{};

  String? get pendingStartTime =>
      state is BarberScheduleLoaded
          ? (state as BarberScheduleLoaded).pendingStartTime
          : null;

  String? get pendingEndTime =>
      state is BarberScheduleLoaded
          ? (state as BarberScheduleLoaded).pendingEndTime
          : null;

  BarberScheduleLoaded? get _loadedOrNull =>
      state is BarberScheduleLoaded ? state as BarberScheduleLoaded : null;

  Future<void> load(String barbershopId, String barberId) async {
    if (barbershopId.isEmpty || barberId.isEmpty) return;

    _barbershopId = barbershopId;
    _barberId = barberId;
    emit(const BarberScheduleLoading());

    final result = await _getBarberSchedule(
      GetBarberScheduleParams(barbershopId: barbershopId, barberId: barberId),
    );

    emit(result.when(
      ok: (schedule) {
        final scheduleMap = <int, BarberSchedule>{};
        for (final s in schedule) {
          scheduleMap[s.dayOfWeek] = s;
        }
        return BarberScheduleLoaded(
          schedule: scheduleMap,
          selectedDays: const {},
          pendingStartTime: null,
          pendingEndTime: null,
        );
      },
      fail: (f) => BarberScheduleError(f.message),
    ));
  }

  void toggleDay(int dayOfWeek) {
    final current = _loadedOrNull;
    if (current == null) return;

    final updated = Set<int>.from(current.selectedDays);
    if (updated.contains(dayOfWeek)) {
      updated.remove(dayOfWeek);
    } else {
      updated.add(dayOfWeek);
    }
    emit(_buildLoaded(
      current,
      selectedDays: updated,
    ));
  }

  void selectPreset(List<int> days) {
    final current = _loadedOrNull;
    if (current == null) return;

    emit(_buildLoaded(
      current,
      selectedDays: days.toSet(),
    ));
  }

  void setPendingTimes(String? startTime, String? endTime) {
    final current = _loadedOrNull;
    if (current == null) return;

    emit(_buildLoaded(
      current,
      pendingStartTime: startTime,
      pendingEndTime: endTime,
    ));
  }

  Future<void> saveDays() async {
    final current = _loadedOrNull;
    if (current == null) return;
    if (_barbershopId == null || _barberId == null) return;
    if (current.selectedDays.isEmpty) return;
    if (current.pendingStartTime == null || current.pendingEndTime == null) return;

    final startTime24 = _to24h(current.pendingStartTime!);
    final endTime24 = _to24h(current.pendingEndTime!);

    final futures = <Future>[];
    for (final day in current.selectedDays) {
      futures.add(_setSchedule(SetScheduleParams(
        barbershopId: _barbershopId!,
        barberId: _barberId!,
        dayOfWeek: day,
        startTime: startTime24,
        endTime: endTime24,
        isActive: true,
      )));
    }

    await Future.wait(futures);

    final updatedSchedule = Map<int, BarberSchedule>.from(current.schedule);
    for (final day in current.selectedDays) {
      updatedSchedule[day] = BarberSchedule(
        id: 'day_$day',
        dayOfWeek: day,
        isActive: true,
        startTime: startTime24,
        endTime: endTime24,
      );
    }

    emit(BarberScheduleDaysSaved(current.selectedDays.toList()));

    await Future.delayed(const Duration(milliseconds: 100));
    emit(BarberScheduleLoaded(
      schedule: updatedSchedule,
      selectedDays: const {},
      pendingStartTime: null,
      pendingEndTime: null,
    ));
  }

  BarberScheduleLoaded _buildLoaded(
    BarberScheduleLoaded current, {
    Map<int, BarberSchedule>? schedule,
    Set<int>? selectedDays,
    String? pendingStartTime,
    String? pendingEndTime,
  }) {
    return BarberScheduleLoaded(
      schedule: schedule ?? current.schedule,
      selectedDays: selectedDays ?? current.selectedDays,
      pendingStartTime: pendingStartTime ?? current.pendingStartTime,
      pendingEndTime: pendingEndTime ?? current.pendingEndTime,
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
    final current = _loadedOrNull;
    if (current == null) return;
    if (_barbershopId == null || _barberId == null) return;

    for (final entry in current.schedule.entries) {
      await _setSchedule(SetScheduleParams(
        barbershopId: _barbershopId!,
        barberId: _barberId!,
        dayOfWeek: entry.key,
        startTime: entry.value.startTime,
        endTime: entry.value.endTime,
        isActive: entry.value.isActive,
      ));
    }

    emit(const BarberScheduleSaved());
    if (_barbershopId != null && _barberId != null) {
      load(_barbershopId!, _barberId!);
    }
  }
}
