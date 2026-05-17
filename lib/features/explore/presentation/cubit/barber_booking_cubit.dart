import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/bookings/data/repositories/firestore_bookings_repository.dart';
import '../../../../features/bookings/domain/entities/booking.dart';
import 'barber_booking_state.dart';

class BarberBookingCubit extends Cubit<BarberBookingState> {
  final String shopId;
  final String barberId;
  final String? clientId;

  BarberBookingCubit({
    required this.shopId,
    required this.barberId,
    this.clientId,
  }) : super(const BarberBookingState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final db = FirebaseFirestore.instance;

      final memberDoc = await db
          .collection('barbershops')
          .doc(shopId)
          .collection('members')
          .doc(barberId)
          .get();

      final barberName = memberDoc.data()?['barberName'] as String? ?? 'Barbero';

      final servicesSnapshot = await db
          .collection('barbershops')
          .doc(shopId)
          .collection('barbers')
          .doc(barberId)
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      final scheduleSnapshot = await db
          .collection('barbershops')
          .doc(shopId)
          .collection('barbers')
          .doc(barberId)
          .collection('schedule')
          .get();

      final services = servicesSnapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      final schedule = <int, bool>{};
      for (final doc in scheduleSnapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == true) {
          schedule[data['dayOfWeek'] as int] = true;
        }
      }

      final availableDays = _computeAvailableDays(schedule);

      emit(state.copyWith(
        isLoading: false,
        barberName: barberName,
        services: services,
        schedule: schedule,
        availableDays: availableDays,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void selectService(Map<String, dynamic> service) {
    emit(state.copyWith(selectedService: service));
  }

  void selectDay(DateTime day) {
    emit(state.copyWith(selectedDay: day, clearSelectedTime: true));
  }

  void selectTime(String time) {
    emit(state.copyWith(selectedTime: time));
  }

  Future<void> confirmBooking() async {
    if (!state.canConfirm || clientId == null || clientId!.isEmpty) return;

    emit(state.copyWith(isBooking: true, errorMessage: null));

    try {
      final db = FirebaseFirestore.instance;

      final clientDoc = await db.collection('users').doc(clientId).get();
      final clientName = clientDoc.data()?['fullName'] as String? ?? 'Cliente';

      final shopDoc = await db.collection('barbershops').doc(shopId).get();
      final shopName = shopDoc.data()?['name'] as String? ?? '';

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

      final repository = FirestoreBookingsRepository(firestore: db);
      await repository.createBooking(
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
          barberSnapshot: BookingSnapshot(name: state.barberName ?? 'Barbero'),
          shopSnapshot: BookingSnapshot(name: shopName),
          serviceSnapshot: BookingSnapshot(name: serviceName),
        ),
      );

      emit(state.copyWith(isBooking: false));
    } catch (e) {
      emit(state.copyWith(isBooking: false, errorMessage: e.toString()));
    }
  }

  List<DateTime> _computeAvailableDays(Map<int, bool> schedule) {
    final today = DateTime.now();
    final days = <DateTime>[];
    for (var i = 0; i < 14; i++) {
      final day = today.add(Duration(days: i));
      final dow = day.weekday;
      if (schedule[dow] == true) {
        days.add(DateTime(day.year, day.month, day.day));
      }
    }
    return days;
  }
}
