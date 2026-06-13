import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/events/barbershop_event_bus.dart';
import '../../../client/favorites/domain/repositories/favorites_repository.dart';
import '../../../barber/services/domain/entities/barber_schedule.dart';
import '../../domain/repositories/barber_booking_repository.dart';
import '../../../bookings/domain/entities/booking.dart';
import 'barber_booking_state.dart';

enum FavoriteSuggestionStatus { skipped, alreadyFavoriteRecorded, shouldPrompt }

class BarberBookingCubit extends Cubit<BarberBookingState> {
  final String shopId;
  final String barberId;
  final String? clientId;
  final Booking? rescheduleBooking;
  final BarberBookingRepository _repository;
  final BarbershopEventBus _eventBus;
  final FavoritesRepository _favoritesRepository;

  BarberBookingCubit({
    required this.shopId,
    required this.barberId,
    this.clientId,
    this.rescheduleBooking,
    required BarberBookingRepository repository,
    required FavoritesRepository favoritesRepository,
    required BarbershopEventBus eventBus,
  }) : _repository = repository,
       _favoritesRepository = favoritesRepository,
       _eventBus = eventBus,
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

      await _applyRescheduleDefaults();

      if (state.selectedDay == null && availableDays.isNotEmpty) {
        emit(
          state.copyWith(
            selectedDay: availableDays.first,
            clearSelectedTime: true,
            errorMessage: null,
          ),
        );
      }

      await _loadAvailableTimes();

      if (rescheduleBooking != null) {
        final originalTime = _formatTime(rescheduleBooking!.slotStart);
        if (state.availableTimes.contains(originalTime)) {
          emit(state.copyWith(selectedTime: originalTime));
        }
      }
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
    final effectiveClientId = rescheduleBooking?.clientId ?? clientId;
    if (!state.canConfirm ||
        effectiveClientId == null ||
        effectiveClientId.isEmpty) {
      return;
    }

    emit(state.copyWith(isBooking: true, errorMessage: null));

    try {
      final clientName = await _repository.getClientName(effectiveClientId);
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
      final draft = BookingDraft(
        clientId: effectiveClientId,
        barberId: barberId,
        barbershopId: shopId,
        serviceId: state.selectedService!['id'] as String,
        dateKey:
            '${slotStart.year}-${slotStart.month.toString().padLeft(2, '0')}-${slotStart.day.toString().padLeft(2, '0')}',
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
      );

      if (rescheduleBooking != null) {
        await _repository.rescheduleBooking(
          bookingId: rescheduleBooking!.id,
          draft: draft,
        );
      } else {
        await _repository.createBooking(draft);
      }

      _eventBus.emit(BarbershopEvent.bookingUpdated);

      emit(state.copyWith(isBooking: false));
    } catch (e) {
      emit(state.copyWith(isBooking: false, errorMessage: e.toString()));
    }
  }

  Future<FavoriteSuggestionStatus> evaluateFavoriteSuggestion() async {
    final effectiveClientId = clientId;
    if (rescheduleBooking != null ||
        effectiveClientId == null ||
        effectiveClientId.isEmpty) {
      return FavoriteSuggestionStatus.skipped;
    }

    final isFavorite = await _favoritesRepository.isFavorite(
      effectiveClientId,
      shopId,
    );

    if (!isFavorite) return FavoriteSuggestionStatus.shouldPrompt;

    await _recordFavoriteUsage(effectiveClientId);
    return FavoriteSuggestionStatus.alreadyFavoriteRecorded;
  }

  Future<void> addFavoriteSuggestion() async {
    final effectiveClientId = clientId;
    final selectedService = state.selectedService;
    if (effectiveClientId == null ||
        effectiveClientId.isEmpty ||
        selectedService == null) {
      return;
    }

    await _favoritesRepository.addFavorite(
      userId: effectiveClientId,
      barbershopId: shopId,
      lastBookedAt: state.selectedDay,
      lastServiceId: selectedService['id'] as String?,
      lastServiceName: selectedService['name'] as String?,
      lastBarberId: barberId,
      lastBarberName: state.barberName,
      bookingCount: 1,
    );
  }

  Future<void> _recordFavoriteUsage(String userId) async {
    final selectedService = state.selectedService;
    if (selectedService == null) return;

    await _favoritesRepository.recordFavoriteBooking(
      userId: userId,
      barbershopId: shopId,
      bookedAt: DateTime.now(),
      serviceId: selectedService['id'] as String,
      serviceName: selectedService['name'] as String,
      barberId: barberId,
      barberName: state.barberName ?? 'Barbero',
    );
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
        excludeBookingId: rescheduleBooking?.id,
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

  Future<void> _applyRescheduleDefaults() async {
    final booking = rescheduleBooking;
    if (booking == null) return;

    final service = state.services.firstWhere(
      (svc) => svc['id'] == booking.serviceId,
      orElse: () => <String, dynamic>{},
    );

    if (service.isNotEmpty) {
      emit(state.copyWith(selectedService: service, clearSelectedTime: true));
    }

    final originalDay = DateTime(
      booking.slotStart.year,
      booking.slotStart.month,
      booking.slotStart.day,
    );
    final hasOriginalDay = state.availableDays.any(
      (candidate) =>
          candidate.year == originalDay.year &&
          candidate.month == originalDay.month &&
          candidate.day == originalDay.day,
    );
    final day = hasOriginalDay
        ? originalDay
        : (state.availableDays.isNotEmpty ? state.availableDays.first : null);

    if (day != null) {
      emit(state.copyWith(selectedDay: day, clearSelectedTime: true));
    }
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
