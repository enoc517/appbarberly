import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/events/barbershop_event_bus.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../../../../bookings/domain/repositories/bookings_repository.dart';

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
    for (final booking in bookings) {
      if (booking.isActive) return booking;
    }
    return null;
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
    required String clientId,
    required BarbershopEventBus eventBus,
  }) : _repository = repository,
       _clientId = clientId,
       _eventBus = eventBus,
       super(const ClientBookingsLoading());

  final BookingsRepository _repository;
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

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
