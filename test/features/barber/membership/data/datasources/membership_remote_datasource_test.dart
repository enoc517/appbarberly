import 'package:barberly/features/barber/membership/data/datasources/membership_remote_datasource.dart';
import 'package:barberly/features/bookings/domain/entities/booking.dart';
import 'package:barberly/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MembershipRemoteDatasource.leaveBarbershop', () {
    late FakeFirebaseFirestore firestore;
    late _SpyBookingsRepository bookingsRepository;
    late MembershipRemoteDatasourceImpl datasource;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      bookingsRepository = _SpyBookingsRepository();
      datasource = MembershipRemoteDatasourceImpl(
        firestore: firestore,
        bookingsRepository: bookingsRepository,
      );

      final bookingDay = DateTime.now().add(const Duration(days: 1));
      final bookingDateKey = _dateKey(bookingDay);

      await firestore.collection('users').doc('barber-1').set({
        'barbershopId': 'shop-1',
        'updatedAt': DateTime(2026, 6, 3),
      });

      await firestore.collection('barbershops').doc('shop-1').set({
        'ownerId': 'owner-1',
        'name': 'Shop Uno',
      });

      await firestore
          .collection('barbershops')
          .doc('shop-1')
          .collection('members')
          .doc('barber-1')
          .set({
            'barberId': 'barber-1',
            'barberName': 'Barbero Uno',
            'barberAvatarUrl': '',
            'role': 'member',
            'joinedAt': DateTime(2026, 6, 1),
          });

      await firestore.collection('bookings').doc('booking-pending').set({
        'clientId': 'client-1',
        'barberId': 'barber-1',
        'barbershopId': 'shop-1',
        'dateKey': bookingDateKey,
        'status': AppointmentBookingStatus.pending.name,
      });

      await firestore.collection('bookings').doc('booking-progress').set({
        'clientId': 'client-2',
        'barberId': 'barber-1',
        'barbershopId': 'shop-1',
        'dateKey': bookingDateKey,
        'status': AppointmentBookingStatus.inProgress.name,
      });

      await firestore.collection('bookings').doc('booking-done').set({
        'clientId': 'client-3',
        'barberId': 'barber-1',
        'barbershopId': 'shop-1',
        'dateKey': bookingDateKey,
        'status': AppointmentBookingStatus.completed.name,
      });
    });

    test('cancels active bookings before removing membership', () async {
      await datasource.leaveBarbershop('barber-1', 'shop-1');

      expect(bookingsRepository.calls, [
        'cancel:booking-pending:client-1:barber',
        'cancel:booking-progress:client-2:barber',
      ]);

      final memberDoc = await firestore
          .collection('barbershops')
          .doc('shop-1')
          .collection('members')
          .doc('barber-1')
          .get();
      expect(memberDoc.exists, isFalse);

      final userDoc = await firestore.collection('users').doc('barber-1').get();
      expect(userDoc.data()?['barbershopId'], isNull);
      expect(userDoc.data()?['activeBookingId'], isNull);
      expect(userDoc.data()?['activeBookingStatus'], isNull);
    });
  });
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _SpyBookingsRepository implements BookingsRepository {
  final calls = <String>[];

  @override
  Future<String> createBooking(BookingDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<void> rescheduleBooking({
    required String bookingId,
    required BookingDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required String clientId,
    required BookingCancellationActor cancelledBy,
    String? cancellationReason,
  }) async {
    calls.add('cancel:$bookingId:$clientId:${cancelledBy.name}');
  }

  @override
  Future<void> completeBooking({
    required String bookingId,
    required String clientId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Booking>> watchBarberAgenda({
    required String barbershopId,
    required String barberId,
    required String dateKey,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Booking>> watchBarbershopBookings({
    required String barbershopId,
    required DateTime start,
    required DateTime end,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Booking>> watchClientBookings(String clientId) {
    throw UnimplementedError();
  }
}
