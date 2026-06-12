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
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.blockedSlots,
    required this.dayIncome,
    required this.totalBookings,
    required this.completedCount,
    required this.cancelledCount,
    this.isLoadingBookings = false,
  });

  final List<Booking> bookings;
  final DateTime selectedDay;
  final List<DateTime> visibleDays;
  final List<Booking> activeBookings;
  final List<Booking> completedBookings;
  final List<Booking> cancelledBookings;
  final List<AgendaBlockedSlot> blockedSlots;
  final double dayIncome;
  final int totalBookings;
  final int completedCount;
  final int cancelledCount;
  final bool isLoadingBookings;

  BarberAgendaLoaded copyWith({
    List<Booking>? bookings,
    DateTime? selectedDay,
    List<DateTime>? visibleDays,
    List<Booking>? activeBookings,
    List<Booking>? completedBookings,
    List<Booking>? cancelledBookings,
    List<AgendaBlockedSlot>? blockedSlots,
    double? dayIncome,
    int? totalBookings,
    int? completedCount,
    int? cancelledCount,
    bool? isLoadingBookings,
  }) {
    return BarberAgendaLoaded(
      bookings: bookings ?? this.bookings,
      selectedDay: selectedDay ?? this.selectedDay,
      visibleDays: visibleDays ?? this.visibleDays,
      activeBookings: activeBookings ?? this.activeBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      blockedSlots: blockedSlots ?? this.blockedSlots,
      dayIncome: dayIncome ?? this.dayIncome,
      totalBookings: totalBookings ?? this.totalBookings,
      completedCount: completedCount ?? this.completedCount,
      cancelledCount: cancelledCount ?? this.cancelledCount,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
    );
  }
}

class AgendaBlockedSlot {
  const AgendaBlockedSlot({
    required this.id,
    required this.start,
    required this.end,
    required this.reason,
    required this.isActive,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final String reason;
  final bool isActive;
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
    try {
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

      _selectedDay = _resolveSelectedDay(_selectedDay);

      await _watchBookingsForSelectedDay();
    } catch (_) {
      emit(const BarberAgendaError('No se pudo cargar la agenda'));
    }
  }

  Future<void> selectDay(DateTime day) async {
    _selectedDay = _resolveSelectedDay(day);
    await _watchBookingsForSelectedDay();
  }

  Future<void> previousWeek() async {
    _selectedDay = _resolveSelectedDay(
      _selectedDay.subtract(const Duration(days: 7)),
    );
    await _watchBookingsForSelectedDay();
  }

  Future<void> nextWeek() async {
    _selectedDay = _resolveSelectedDay(
      _selectedDay.add(const Duration(days: 7)),
    );
    await _watchBookingsForSelectedDay();
  }

  Future<void> goToCurrentWeek() async {
    _selectedDay = _resolveSelectedDay(DateTime.now());
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

  Future<bool> cancelBooking(
    Booking booking, {
    String? cancellationReason,
  }) async {
    if (!booking.isActive) return false;

    try {
      await _bookingsRepository.cancelBooking(
        bookingId: booking.id,
        clientId: booking.clientId,
        cancelledBy: BookingCancellationActor.barber,
        cancellationReason: cancellationReason,
      );
      return true;
    } catch (_) {
      emit(const BarberAgendaError('No se pudo cancelar la cita'));
      return false;
    }
  }

  Future<bool> blockSlot({
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    final barbershopId = _barbershopId;
    if (barbershopId == null || barbershopId.isEmpty) return false;
    if (reason.trim().isEmpty) return false;
    if (!end.isAfter(start)) return false;
    if (_activeBookingsForSelectedDay().any(
      (booking) => _overlaps(start, end, booking.slotStart, booking.slotEnd),
    )) {
      return false;
    }

    if (_activeBlockedSlotsForSelectedDay().any(
      (slot) => _overlaps(start, end, slot.start, slot.end),
    )) {
      return false;
    }

    final doc = _firestore
        .collection('barbershops')
        .doc(barbershopId)
        .collection('barbers')
        .doc(_userId)
        .collection('blocked_slots')
        .doc();

    await doc.set({
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'dateKey': _dateKey(start),
      'reason': reason.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': _userId,
    });
    await _watchBookingsForSelectedDay();
    return true;
  }

  Future<bool> cancelBlockedSlot(String blockId) async {
    final barbershopId = _barbershopId;
    if (barbershopId == null || barbershopId.isEmpty) return false;
    if (blockId.trim().isEmpty) return false;

    try {
      await _firestore
          .collection('barbershops')
          .doc(barbershopId)
          .collection('barbers')
          .doc(_userId)
          .collection('blocked_slots')
          .doc(blockId)
          .update({
            'isActive': false,
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await _watchBookingsForSelectedDay();
      return true;
    } catch (_) {
      emit(const BarberAgendaError('No se pudo cancelar el bloqueo'));
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
    List<AgendaBlockedSlot> blockedSlots = const [];
    try {
      blockedSlots = await _loadBlockedSlotsForSelectedDay();
    } catch (_) {
      blockedSlots = const [];
    }
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
              activeBookings: bookings
                  .where((b) => b.isActive)
                  .toList(growable: false),
              completedBookings: bookings
                  .where((b) => b.status == AppointmentBookingStatus.completed)
                  .toList(growable: false),
              cancelledBookings: bookings
                  .where((b) => b.status == AppointmentBookingStatus.cancelled)
                  .toList(growable: false),
              blockedSlots: blockedSlots,
              dayIncome: bookings
                  .where((b) => b.status == AppointmentBookingStatus.completed)
                  .fold<double>(0, (total, booking) => total + booking.price),
              totalBookings: bookings.length,
              completedCount: bookings
                  .where((b) => b.status == AppointmentBookingStatus.completed)
                  .length,
              cancelledCount: bookings
                  .where((b) => b.status == AppointmentBookingStatus.cancelled)
                  .length,
            ),
          ),
          onError: (_) =>
              emit(const BarberAgendaError('No se pudo cargar la agenda')),
        );
  }

  List<Booking> _activeBookingsForSelectedDay() {
    final current = state;
    if (current is! BarberAgendaLoaded) return const <Booking>[];
    return current.bookings
        .where((booking) => booking.isActive)
        .toList(growable: false);
  }

  List<AgendaBlockedSlot> _activeBlockedSlotsForSelectedDay() {
    final current = state;
    if (current is! BarberAgendaLoaded) return const <AgendaBlockedSlot>[];
    return current.blockedSlots
        .where((slot) => slot.isActive)
        .toList(growable: false);
  }

  Future<List<AgendaBlockedSlot>> _loadBlockedSlotsForSelectedDay() async {
    final barbershopId = _barbershopId;
    if (barbershopId == null || barbershopId.isEmpty) return const [];

    final snapshot = await _firestore
        .collection('barbershops')
        .doc(barbershopId)
        .collection('barbers')
        .doc(_userId)
        .collection('blocked_slots')
        .where('dateKey', isEqualTo: _dateKey(_selectedDay))
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return AgendaBlockedSlot(
            id: doc.id,
            start: _dateTime(data['start']),
            end: _dateTime(data['end']),
            reason: data['reason'] as String? ?? '',
            isActive: data['isActive'] as bool? ?? true,
          );
        })
        .where((slot) => slot.isActive)
        .toList(growable: false)
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }
}
