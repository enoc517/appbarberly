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
  final List<BarberSchedule> schedule;
  const BarberScheduleLoaded(this.schedule);
}

class BarberScheduleSaved extends BarberScheduleState {
  const BarberScheduleSaved();
}

class BarberScheduleError extends BarberScheduleState {
  final String message;
  const BarberScheduleError(this.message);
}
