import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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
  }) : _repository = repository,
       _clientId = clientId,
       super(const ClientBookingsLoading());

  final BookingsRepository _repository;
  final String _clientId;
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
      onError: (_) =>
          emit(const ClientBookingsError('No se pudieron cargar tus citas')),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
