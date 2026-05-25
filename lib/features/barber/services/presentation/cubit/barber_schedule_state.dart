import '../../domain/entities/barber_schedule.dart';

sealed class BarberScheduleState {
  const BarberScheduleState();
}

class BarberScheduleInitial extends BarberScheduleState {
  const BarberScheduleInitial();
}

class BarberScheduleLoading extends BarberScheduleState {
  const BarberScheduleLoading();
}

class BarberScheduleLoaded extends BarberScheduleState {
  final Map<int, BarberSchedule> schedule;
  final Set<int> selectedDays;
  final String? pendingStartTime;
  final String? pendingEndTime;

  const BarberScheduleLoaded({
    required this.schedule,
    required this.selectedDays,
    required this.pendingStartTime,
    required this.pendingEndTime,
  });
}

class BarberScheduleSaved extends BarberScheduleState {
  const BarberScheduleSaved();
}

class BarberScheduleDaysSaved extends BarberScheduleState {
  final List<int> daysSaved;
  const BarberScheduleDaysSaved(this.daysSaved);
}

class BarberScheduleError extends BarberScheduleState {
  final String message;
  const BarberScheduleError(this.message);
}
