class WeeklyPerformance {
  /// Valores normalizados 0-1 para L, M, M, J, V, S, D.
  final List<double> dailyValues;

  /// Índice del día "hoy" (0 = Lunes).
  final int todayIndex;

  const WeeklyPerformance({
    required this.dailyValues,
    required this.todayIndex,
  }) : assert(dailyValues.length == 7);
}