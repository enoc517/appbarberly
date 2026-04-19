import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/barber.dart';
import '../../../domain/entities/service.dart';
import '../../../domain/entities/time_slot.dart';
import '../../../domain/usecases/confirm_booking.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final ConfirmBooking _confirmBooking;
  final String barbershopId;

  BookingCubit({
    required ConfirmBooking confirmBooking,
    required this.barbershopId,
    required DateTime initialDay,
  })  : _confirmBooking = confirmBooking,
        super(BookingState(selectedDay: initialDay));

  void changeTab(ProfileTab tab) => emit(state.copyWith(activeTab: tab));

  void selectService(Service s) =>
      emit(state.copyWith(selectedService: s));

  void selectDay(DateTime day) =>
      emit(state.copyWith(selectedDay: day, clearSlot: true));

  void selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;
    emit(state.copyWith(selectedSlot: slot));
  }

  void selectBarber(Barber b) => emit(state.copyWith(selectedBarber: b));

  Future<void> confirm() async {
    if (!state.canConfirm) return;
    emit(state.copyWith(status: BookingStatus.submitting, clearError: true));

    final result = await _confirmBooking(
      ConfirmBookingParams(
        barbershopId: barbershopId,
        service: state.selectedService!,
        barber: state.selectedBarber!,
        slot: state.selectedSlot!,
      ),
    );

    emit(result.when(
      ok: (_) => state.copyWith(status: BookingStatus.success),
      fail: (f) => state.copyWith(
        status: BookingStatus.failure,
        errorMessage: f.message,
      ),
    ));
  }
}