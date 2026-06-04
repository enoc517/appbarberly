import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../bookings/data/repositories/firestore_bookings_repository.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../../../../bookings/domain/repositories/bookings_repository.dart';
import '../../../barbershop_management/domain/entities/barbershop.dart';
import '../../domain/entities/barber_member.dart';
import '../../domain/entities/membership_request.dart';

abstract class MembershipRemoteDatasource {
  Future<List<Barbershop>> searchBarbershops(String query);
  Future<MembershipRequest> sendRequest({
    required String barberId,
    required String barberName,
    required String barberEmail,
    required String barberAvatarUrl,
    required String barbershopId,
    required String barbershopName,
  });
  Future<List<MembershipRequest>> getPendingRequests(String barbershopId);
  Future<MembershipRequest> reviewRequest({
    required String requestId,
    required String barbershopId,
    required bool approve,
    required String reviewedBy,
  });
  Future<List<BarberMember>> getMembers(String barbershopId);
  Future<void> leaveBarbershop(String barberId, String barbershopId);
}

class MembershipRemoteDatasourceImpl implements MembershipRemoteDatasource {
  MembershipRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
    BookingsRepository? bookingsRepository,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _bookingsRepository =
           bookingsRepository ??
           FirestoreBookingsRepository(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _db;
  final BookingsRepository _bookingsRepository;

  CollectionReference<Map<String, dynamic>> get _shopsCollection =>
      _db.collection('barbershops');

  CollectionReference<Map<String, dynamic>> _requestsCollection(
    String shopId,
  ) => _shopsCollection.doc(shopId).collection('membership_requests');

  CollectionReference<Map<String, dynamic>> _membersCollection(String shopId) =>
      _shopsCollection.doc(shopId).collection('members');

  @override
  Future<List<Barbershop>> searchBarbershops(String query) async {
    Query<Map<String, dynamic>> q = _shopsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name');

    if (query.isNotEmpty) {
      q = q
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff');
    }

    final snapshot = await q.limit(20).get();
    return _mapBarbershopList(snapshot);
  }

  @override
  Future<MembershipRequest> sendRequest({
    required String barberId,
    required String barberName,
    required String barberEmail,
    required String barberAvatarUrl,
    required String barbershopId,
    required String barbershopName,
  }) async {
    final docRef = _requestsCollection(barbershopId).doc();

    final data = <String, dynamic>{
      'barberId': barberId,
      'barberName': barberName,
      'barberEmail': barberEmail,
      'barberAvatarUrl': barberAvatarUrl,
      'barbershopId': barbershopId,
      'barbershopName': barbershopName,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': null,
    };

    await docRef.set(data);

    return MembershipRequest(
      id: docRef.id,
      barberId: barberId,
      barberName: barberName,
      barberEmail: barberEmail,
      barberAvatarUrl: barberAvatarUrl,
      barbershopId: barbershopId,
      barbershopName: barbershopName,
      status: MembershipRequestStatus.pending,
      requestedAt: DateTime.now(),
    );
  }

  @override
  Future<List<MembershipRequest>> getPendingRequests(
    String barbershopId,
  ) async {
    final snapshot = await _requestsCollection(barbershopId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return MembershipRequest(
        id: doc.id,
        barberId: data['barberId'] as String? ?? '',
        barberName: data['barberName'] as String? ?? '',
        barberEmail: data['barberEmail'] as String? ?? '',
        barberAvatarUrl: data['barberAvatarUrl'] as String? ?? '',
        barbershopId: data['barbershopId'] as String? ?? barbershopId,
        barbershopName: data['barbershopName'] as String? ?? '',
        status: MembershipRequestStatus.pending,
        requestedAt:
            (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<MembershipRequest> reviewRequest({
    required String requestId,
    required String barbershopId,
    required bool approve,
    required String reviewedBy,
  }) async {
    final docRef = _requestsCollection(barbershopId).doc(requestId);
    final doc = await docRef.get();
    final data = doc.data() ?? <String, dynamic>{};

    final newStatus = approve
        ? MembershipRequestStatus.approved
        : MembershipRequestStatus.rejected;

    await docRef.update({
      'status': newStatus.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
    });

    if (approve) {
      final barberId = data['barberId'] as String? ?? '';
      final barberName = data['barberName'] as String? ?? '';
      final barberAvatarUrl = data['barberAvatarUrl'] as String? ?? '';

      await _membersCollection(barbershopId).doc(barberId).set({
        'barberId': barberId,
        'barberName': barberName,
        'barberAvatarUrl': barberAvatarUrl,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(barberId).set({
        'barbershopId': barbershopId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return MembershipRequest(
      id: requestId,
      barberId: data['barberId'] as String? ?? '',
      barberName: data['barberName'] as String? ?? '',
      barberEmail: data['barberEmail'] as String? ?? '',
      barberAvatarUrl: data['barberAvatarUrl'] as String? ?? '',
      barbershopId: barbershopId,
      barbershopName: data['barbershopName'] as String? ?? '',
      status: newStatus,
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );
  }

  @override
  Future<List<BarberMember>> getMembers(String barbershopId) async {
    final snapshot = await _membersCollection(
      barbershopId,
    ).orderBy('joinedAt').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BarberMember(
        barberId: data['barberId'] as String? ?? '',
        barberName: data['barberName'] as String? ?? '',
        barberAvatarUrl: data['barberAvatarUrl'] as String? ?? '',
        role: data['role'] == 'owner'
            ? MembershipRole.owner
            : MembershipRole.member,
        joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> leaveBarbershop(String barberId, String barbershopId) async {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final bookingsSnapshot = await _db
        .collection('bookings')
        .where('barberId', isEqualTo: barberId)
        .where('barbershopId', isEqualTo: barbershopId)
        .where('dateKey', isGreaterThanOrEqualTo: todayKey)
        .get();

    final activeStatuses = {
      AppointmentBookingStatus.pending,
      AppointmentBookingStatus.confirmed,
      AppointmentBookingStatus.inProgress,
    };

    final bookingsToCancel = bookingsSnapshot.docs
        .map((doc) => _BookingRef.fromDocument(doc))
        .where((booking) => activeStatuses.contains(booking.status))
        .toList();

    for (final booking in bookingsToCancel) {
      await _bookingsRepository.cancelBooking(
        bookingId: booking.id,
        clientId: booking.clientId,
        cancelledBy: BookingCancellationActor.barber,
      );
    }

    final batch = _db.batch();
    batch.delete(_membersCollection(barbershopId).doc(barberId));

    batch.update(_db.collection('users').doc(barberId), {
      'barbershopId': FieldValue.delete(),
      'activeBookingId': FieldValue.delete(),
      'activeBookingStatus': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  List<Barbershop> _mapBarbershopList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Barbershop(
        id: doc.id,
        ownerId: data['ownerId'] as String? ?? '',
        ownerName: data['ownerName'] as String? ?? '',
        name: data['name'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        address: data['address'] as String? ?? '',
        lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
        imageUrl: data['imageUrl'] as String? ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: data['reviewCount'] as int? ?? 0,
        hasActivePromotion: data['hasActivePromotion'] as bool? ?? false,
        tags: List<String>.from(data['tags'] as List? ?? []),
        isActive: data['isActive'] as bool? ?? true,
      );
    }).toList();
  }
}

class _BookingRef {
  const _BookingRef({
    required this.id,
    required this.clientId,
    required this.status,
  });

  factory _BookingRef.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return _BookingRef(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      status: _status(data['status'] as String?),
    );
  }

  final String id;
  final String clientId;
  final AppointmentBookingStatus status;

  static AppointmentBookingStatus _status(String? value) {
    return AppointmentBookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AppointmentBookingStatus.cancelled,
    );
  }
}
