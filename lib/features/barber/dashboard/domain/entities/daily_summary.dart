class DailySummary {
  final double incomeToday;
  final double estimatedIncomeToday;
  final double incomePreviousDay;
  final int completedAppointments;
  final int totalAppointments;

  const DailySummary({
    required this.incomeToday,
    required this.estimatedIncomeToday,
    required this.incomePreviousDay,
    required this.completedAppointments,
    required this.totalAppointments,
  });

  /// Variación porcentual vs ayer. Positivo = mejoró.
  double get incomeDeltaPercent {
    if (incomePreviousDay == 0) return 0;
    return ((incomeToday - incomePreviousDay) / incomePreviousDay) * 100;
  }

  int get pendingAppointments => totalAppointments - completedAppointments;
}
