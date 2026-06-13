import 'package:barberly/core/events/barbershop_event_bus.dart';
import 'package:barberly/core/usecases/usecase.dart';
import 'package:barberly/features/barber/dashboard/domain/entities/appointment.dart';
import 'package:barberly/features/barber/dashboard/domain/entities/daily_summary.dart';
import 'package:barberly/features/barber/dashboard/domain/entities/dashboard_overview.dart';
import 'package:barberly/features/barber/dashboard/domain/entities/weekly_performance.dart';
import 'package:barberly/features/barber/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:barberly/features/barber/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:barberly/features/barber/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardCubit', () {
    late _FakeDashboardRepository repository;
    late DashboardCubit cubit;

    setUp(() {
      repository = _FakeDashboardRepository();
      cubit = DashboardCubit(
        getData: GetDashboardData(repository),
        eventBus: BarbershopEventBus.instance,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('refreshes when bookingUpdated is emitted', () async {
      await cubit.load('barber-1');
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 1);

      BarbershopEventBus.instance.emit(BarbershopEvent.bookingUpdated);
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 2);
    });
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  var calls = 0;

  @override
  Future<Result<DashboardData>> getDashboardData(String barberId) async {
    calls += 1;
    return Ok(
      DashboardData(
        summary: const DailySummary(
          incomeToday: 1000,
          estimatedIncomeToday: 1200,
          incomePreviousDay: 500,
          completedAppointments: 1,
          totalAppointments: 2,
        ),
        weekly: WeeklyPerformance(
          dailyValues: [0, 0, 0, 0, 0, 0, 0],
          todayIndex: 0,
        ),
        todayAppointments: [
          Appointment(
            id: 'booking-1',
            clientName: 'Cliente Uno',
            serviceName: 'Corte',
            startTime: DateTime(2026, 6, 12, 9),
            status: AppointmentStatus.upcoming,
          ),
        ],
        nextAppointment: null,
        weekOverview: const BarberWeeklyOverview(
          totalAppointments: 2,
          completedAppointments: 1,
          cancelledAppointments: 0,
          upcomingAppointments: 1,
          estimatedIncome: 1200,
        ),
        topServices: const [],
        upcomingBlockedHours: const [],
      ),
    );
  }
}
