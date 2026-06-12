import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../barber/services/domain/entities/barber_schedule.dart';
import '../../domain/repositories/barber_booking_repository.dart';
import '../../../bookings/domain/entities/booking.dart';
import 'barber_booking_state.dart';

class BarberBookingCubit extends Cubit<BarberBookingState> {
  final String shopId;
  final String barberId;
  final String? clientId;
  final BarberBookingRepository _repository;

  BarberBookingCubit({
    required this.shopId,
    required this.barberId,
    this.clientId,
    required BarberBookingRepository repository,
  }) : _repository = repository,
       super(const BarberBookingState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final result = await _repository.loadBarberData(shopId, barberId);

      final availableDays = _computeAvailableDays(result.schedule);

      emit(
        state.copyWith(
          isLoading: false,
          barberName: result.barberName,
          barberAvatarUrl: result.barberAvatarUrl,
          services: result.services,
          schedule: result.schedule,
          availableDays: availableDays,
          errorMessage: null,
        ),
      );

      if (availableDays.isNotEmpty) {
        emit(
          state.copyWith(
            selectedDay: availableDays.first,
            clearSelectedTime: true,
            errorMessage: null,
          ),
        );
      }

      await _loadAvailableTimes();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void selectService(Map<String, dynamic> service) {
    emit(
      state.copyWith(
        selectedService: service,
        clearSelectedTime: true,
        availableTimes: const [],
        isLoadingSlots: false,
        errorMessage: null,
      ),
    );
    _loadAvailableTimes();
  }

  void selectDay(DateTime day) {
    emit(
      state.copyWith(
        selectedDay: day,
        clearSelectedTime: true,
        availableTimes: const [],
        isLoadingSlots: false,
        errorMessage: null,
      ),
    );
    _loadAvailableTimes();
  }

  void selectTime(String time) {
    emit(state.copyWith(selectedTime: time));
  }

  Future<void> confirmBooking() async {
    if (!state.canConfirm || clientId == null || clientId!.isEmpty) return;

    emit(state.copyWith(isBooking: true, errorMessage: null));

    try {
      final clientName = await _repository.getClientName(clientId!);
      final shopName = await _repository.getShopName(shopId);

      final serviceName = state.selectedService!['name'] as String;
      final price = (state.selectedService!['price'] as num).toDouble();
      final durationMin = state.selectedService!['durationMinutes'] as int;

      final timeParts = state.selectedTime!.split(':');
      final slotStart = DateTime(
        state.selectedDay!.year,
        state.selectedDay!.month,
        state.selectedDay!.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final dateKey =
          '${slotStart.year}-${slotStart.month.toString().padLeft(2, '0')}-${slotStart.day.toString().padLeft(2, '0')}';

      await _repository.createBooking(
        BookingDraft(
          clientId: clientId!,
          barberId: barberId,
          barbershopId: shopId,
          serviceId: state.selectedService!['id'] as String,
          dateKey: dateKey,
          slotStart: slotStart,
          slotEnd: slotStart.add(Duration(minutes: durationMin)),
          price: price,
          durationMinutes: durationMin,
          clientSnapshot: BookingSnapshot(name: clientName),
          barberSnapshot: BookingSnapshot(
            name: state.barberName ?? 'Barbero',
            imageUrl: state.barberAvatarUrl,
          ),
          shopSnapshot: BookingSnapshot(name: shopName),
          serviceSnapshot: BookingSnapshot(name: serviceName),
        ),
      );

      emit(state.copyWith(isBooking: false));
    } catch (e) {
      emit(state.copyWith(isBooking: false, errorMessage: e.toString()));
    }
  }

  List<DateTime> _computeAvailableDays(Map<int, BarberSchedule> schedule) {
    final today = DateTime.now();
    final days = <DateTime>[];
    for (var i = 0; i < 14; i++) {
      final day = today.add(Duration(days: i));
      final dow = day.weekday;
      if (schedule[dow]?.isActive == true) {
        days.add(DateTime(day.year, day.month, day.day));
      }
    }
    return days;
  }

  Future<void> _loadAvailableTimes() async {
    final selectedService = state.selectedService;
    final selectedDay = state.selectedDay;
    if (selectedService == null || selectedDay == null) return;

    final durationMinutes = (selectedService['durationMinutes'] as int?) ?? 0;
    if (durationMinutes <= 0) return;

    emit(state.copyWith(isLoadingSlots: true, availableTimes: const []));

    try {
      final availableTimes = await _repository.loadAvailableTimeSlots(
        shopId: shopId,
        barberId: barberId,
        day: selectedDay,
        durationMinutes: durationMinutes,
      );

      emit(
        state.copyWith(
          isLoadingSlots: false,
          availableTimes: availableTimes,
          clearSelectedTime: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingSlots: false, errorMessage: e.toString()));
    }
  }
}
