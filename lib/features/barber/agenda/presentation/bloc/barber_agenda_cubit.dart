import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bookings/domain/entities/booking.dart';
import '../../../../bookings/domain/repositories/bookings_repository.dart';
import '../../../../barber/services/domain/usecases/get_barber_schedule.dart';

sealed class BarberAgendaState {
  const BarberAgendaState();
}

class BarberAgendaLoading extends BarberAgendaState {
  const BarberAgendaLoading();
}

class BarberAgendaLoaded extends BarberAgendaState {
  const BarberAgendaLoaded({
    required this.bookings,
    required this.selectedDay,
    required this.visibleDays,
    this.isLoadingBookings = false,
  });

  final List<Booking> bookings;
  final DateTime selectedDay;
  final List<DateTime> visibleDays;
  final bool isLoadingBookings;

  BarberAgendaLoaded copyWith({
    List<Booking>? bookings,
    DateTime? selectedDay,
    List<DateTime>? visibleDays,
    bool? isLoadingBookings,
  }) {
    return BarberAgendaLoaded(
      bookings: bookings ?? this.bookings,
      selectedDay: selectedDay ?? this.selectedDay,
      visibleDays: visibleDays ?? this.visibleDays,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
    );
  }
}

class BarberAgendaEmpty extends BarberAgendaState {
  const BarberAgendaEmpty(this.message);

  final String message;
}

class BarberAgendaError extends BarberAgendaState {
  const BarberAgendaError(this.message);

  final String message;
}

class BarberAgendaCubit extends Cubit<BarberAgendaState> {
  BarberAgendaCubit({
    required BookingsRepository bookingsRepository,
    required FirebaseFirestore firestore,
    required GetBarberSchedule getBarberSchedule,
    required String userId,
  }) : _bookingsRepository = bookingsRepository,
       _firestore = firestore,
       _getBarberSchedule = getBarberSchedule,
       _userId = userId,
       super(const BarberAgendaLoading());

  final BookingsRepository _bookingsRepository;
  final FirebaseFirestore _firestore;
  final GetBarberSchedule _getBarberSchedule;
  final String _userId;
  String? _barbershopId;
  StreamSubscription<List<Booking>>? _subscription;
  DateTime _selectedDay = DateTime.now();
  Set<int> _activeWeekdays = <int>{};

  Future<void> load({DateTime? day}) async {
    _selectedDay = _dateOnly(day ?? _selectedDay);
    if (_userId.isEmpty) {
      emit(const BarberAgendaEmpty('No hay usuario autenticado.'));
      return;
    }

    emit(const BarberAgendaLoading());
    final userDoc = await _firestore.collection('users').doc(_userId).get();
    final data = userDoc.data() ?? <String, dynamic>{};
    final barbershopId = data['barbershopId'] as String?;

    if (barbershopId == null || barbershopId.isEmpty) {
      emit(
        const BarberAgendaEmpty(
          'Tu cuenta profesional aún no tiene barbería asignada.',
        ),
      );
      return;
    }

    final scheduleResult = await _getBarberSchedule(
      GetBarberScheduleParams(barbershopId: barbershopId, barberId: _userId),
    );

    final activeDays = scheduleResult.when(
      ok: (schedule) => schedule
          .where((day) => day.isActive)
          .map((day) => day.dayOfWeek)
          .toSet(),
      fail: (failure) {
        emit(BarberAgendaError(failure.message));
        return <int>{};
      },
    );

    if (state is BarberAgendaError) return;

    _barbershopId = barbershopId;
    _activeWeekdays = activeDays;
    if (_activeWeekdays.isEmpty) {
      emit(
        const BarberAgendaEmpty(
          'No tienes días activos configurados en tu horario.',
        ),
      );
      return;
    }

    _selectedDay = _resolveSelectedDay(day ?? _selectedDay);

    await _watchBookingsForSelectedDay();
  }

  Future<void> selectDay(DateTime day) async {
    _selectedDay = _resolveSelectedDay(day);
    await _watchBookingsForSelectedDay();
  }

  Future<bool> completeBooking(Booking booking) async {
    if (!canCompleteBooking(booking)) return false;

    try {
      await _bookingsRepository.completeBooking(
        bookingId: booking.id,
        clientId: booking.clientId,
      );
      return true;
    } catch (_) {
      emit(const BarberAgendaError('No se pudo completar la cita'));
      return false;
    }
  }

  bool canCompleteBooking(Booking booking, {DateTime? now}) {
    if (!booking.isActive) return false;
    final currentTime = now ?? DateTime.now();
    return !currentTime.isBefore(booking.slotEnd);
  }

  Future<bool> cancelBooking(Booking booking) async {
    if (!booking.isActive) return false;

    try {
      await _bookingsRepository.cancelBooking(
        bookingId: booking.id,
        clientId: booking.clientId,
        cancelledBy: BookingCancellationActor.barber,
      );
      return true;
    } catch (_) {
      emit(const BarberAgendaError('No se pudo cancelar la cita'));
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _resolveSelectedDay(DateTime requestedDay) {
    var candidate = _dateOnly(requestedDay);
    for (var i = 0; i < 7; i++) {
      if (_activeWeekdays.contains(candidate.weekday)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return _dateOnly(requestedDay);
  }

  List<DateTime> _visibleDaysFor(DateTime selectedDay) {
    final monday = selectedDay.subtract(
      Duration(days: selectedDay.weekday - 1),
    );
    return List.generate(7, (index) => monday.add(Duration(days: index)))
        .where((day) => _activeWeekdays.contains(day.weekday))
        .toList(growable: false);
  }

  Future<void> _watchBookingsForSelectedDay() async {
    final barbershopId = _barbershopId;
    if (barbershopId == null || barbershopId.isEmpty) return;

    final current = state;
    if (current is BarberAgendaLoaded) {
      emit(
        current.copyWith(
          selectedDay: _selectedDay,
          visibleDays: _visibleDaysFor(_selectedDay),
          bookings: const [],
          isLoadingBookings: true,
        ),
      );
    }

    await _subscription?.cancel();
    _subscription = _bookingsRepository
        .watchBarberAgenda(
          barbershopId: barbershopId,
          barberId: _userId,
          dateKey: _dateKey(_selectedDay),
        )
        .listen(
          (bookings) => emit(
            BarberAgendaLoaded(
              bookings: bookings,
              selectedDay: _selectedDay,
              visibleDays: _visibleDaysFor(_selectedDay),
            ),
          ),
          onError: (_) =>
              emit(const BarberAgendaError('No se pudo cargar la agenda')),
        );
  }
}
