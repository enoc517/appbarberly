import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bookings/domain/entities/booking.dart';
import '../../../../bookings/domain/repositories/bookings_repository.dart';

sealed class BarberAgendaState {
  const BarberAgendaState();
}

class BarberAgendaLoading extends BarberAgendaState {
  const BarberAgendaLoading();
}

class BarberAgendaLoaded extends BarberAgendaState {
  const BarberAgendaLoaded({required this.bookings, required this.selectedDay});

  final List<Booking> bookings;
  final DateTime selectedDay;
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
    required String userId,
  }) : _bookingsRepository = bookingsRepository,
       _firestore = firestore,
       _userId = userId,
       super(const BarberAgendaLoading());

  final BookingsRepository _bookingsRepository;
  final FirebaseFirestore _firestore;
  final String _userId;
  StreamSubscription<List<Booking>>? _subscription;
  DateTime _selectedDay = DateTime.now();

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

    await _subscription?.cancel();
    _subscription = _bookingsRepository
        .watchBarberAgenda(
          barbershopId: barbershopId,
          dateKey: _dateKey(_selectedDay),
        )
        .listen(
          (bookings) => emit(
            BarberAgendaLoaded(bookings: bookings, selectedDay: _selectedDay),
          ),
          onError: (_) =>
              emit(const BarberAgendaError('No se pudo cargar la agenda')),
        );
  }

  Future<void> selectDay(DateTime day) => load(day: day);

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
}
