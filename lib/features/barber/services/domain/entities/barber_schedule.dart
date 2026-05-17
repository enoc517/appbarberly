class BarberSchedule {
  final String id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  const BarberSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  String get dayName => switch (dayOfWeek) {
    1 => 'Lunes',
    2 => 'Martes',
    3 => 'Miércoles',
    4 => 'Jueves',
    5 => 'Viernes',
    6 => 'Sábado',
    7 => 'Domingo',
    _ => '',
  };
}
