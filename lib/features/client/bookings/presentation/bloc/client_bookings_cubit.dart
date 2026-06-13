import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/events/barbershop_event_bus.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../../../../bookings/domain/repositories/bookings_repository.dart';
import '../../../../reviews/domain/repositories/reviews_repository.dart';

sealed class ClientBookingsState {
  const ClientBookingsState();
}

class ClientBookingsLoading extends ClientBookingsState {
  const ClientBookingsLoading();
}

class ClientBookingsLoaded extends ClientBookingsState {
  const ClientBookingsLoaded(this.bookings);

  final List<Booking> bookings;

  Booking? get activeBooking {
    final upcoming = upcomingBookings;
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<Booking> get upcomingBookings {
    final upcoming = bookings.where((booking) => booking.isActive).toList();
    upcoming.sort((a, b) => a.slotStart.compareTo(b.slotStart));
    return upcoming;
  }

  List<Booking> get historyBookings {
    final history = bookings.where((booking) => !booking.isActive).toList();
    history.sort((a, b) => b.slotStart.compareTo(a.slotStart));
    return history;
  }

  List<Booking> get penaltyBookings {
    final penalties = bookings.where((booking) => booking.hasPenalty).toList();
    penalties.sort((a, b) => b.slotStart.compareTo(a.slotStart));
    return penalties;
  }
}

class ClientBookingsEmpty extends ClientBookingsState {
  const ClientBookingsEmpty();
}

class ClientBookingsError extends ClientBookingsState {
  const ClientBookingsError(this.message);

  final String message;
}

class ClientBookingsCubit extends Cubit<ClientBookingsState> {
  ClientBookingsCubit({
    required BookingsRepository repository,
    required ReviewsRepository reviewsRepository,
    required String clientId,
    required BarbershopEventBus eventBus,
  }) : _repository = repository,
       _reviewsRepository = reviewsRepository,
       _clientId = clientId,
       _eventBus = eventBus,
       super(const ClientBookingsLoading());

  final BookingsRepository _repository;
  final ReviewsRepository _reviewsRepository;
  final String _clientId;
  final BarbershopEventBus _eventBus;
  StreamSubscription<List<Booking>>? _subscription;

  void watch() {
    if (_clientId.isEmpty) {
      emit(const ClientBookingsEmpty());
      return;
    }

    _subscription?.cancel();
    _subscription = _repository.watchClientBookings(_clientId).listen(
      (bookings) {
        emit(
          bookings.isEmpty
              ? const ClientBookingsEmpty()
              : ClientBookingsLoaded(bookings),
        );
      },
      onError: (Object error) =>
          emit(const ClientBookingsError('No se pudieron cargar tus citas')),
    );
  }

  Future<void> cancelBooking(Booking booking) async {
    if (!booking.isActive) return;

    try {
      await _repository.cancelBooking(
        bookingId: booking.id,
        clientId: booking.clientId,
        cancelledBy: BookingCancellationActor.client,
      );
      _eventBus.emit(BarbershopEvent.bookingUpdated);
    } catch (_) {
      emit(const ClientBookingsError('No se pudo cancelar la cita'));
    }
  }

  Future<bool> createReview({
    required Booking booking,
    required int rating,
    String? comment,
  }) async {
    if (booking.status != AppointmentBookingStatus.completed) return false;
    if (booking.isReviewed) return false;
    if (rating < 1 || rating > 5) return false;

    try {
      await _reviewsRepository.createReview(
        bookingId: booking.id,
        clientId: booking.clientId,
        rating: rating,
        comment: comment,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
