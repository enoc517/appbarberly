import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../bookings/data/repositories/firestore_bookings_repository.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../../../../bookings/domain/repositories/bookings_repository.dart';
import '../../../barbershop_management/domain/entities/barbershop.dart';
import '../../domain/entities/barber_member.dart';
import '../../domain/entities/membership_request.dart';

abstract class MembershipRemoteDatasource {
  Future<List<Barbershop>> searchBarbershops({
    required String query,
    required double radiusKm,
  });
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
  static const _kBarbershopsCol = 'barbershops';

  static const _kLocationTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _shopsCollection =>
      _db.collection(_kBarbershopsCol);

  CollectionReference<Map<String, dynamic>> _requestsCollection(
    String shopId,
  ) => _shopsCollection.doc(shopId).collection('membership_requests');

  CollectionReference<Map<String, dynamic>> _membersCollection(String shopId) =>
      _shopsCollection.doc(shopId).collection('members');

  @override
  Future<List<Barbershop>> searchBarbershops({
    required String query,
    required double radiusKm,
  }) async {
    final position = await _resolvePosition();
    final geoRef = GeoCollectionReference<Map<String, dynamic>>(
      _shopsCollection,
    );

    final docs = await geoRef
        .subscribeWithin(
          center: GeoFirePoint(GeoPoint(position.latitude, position.longitude)),
          radiusInKm: radiusKm,
          field: 'position',
          geopointFrom: (data) => (data['position']['geopoint'] as GeoPoint),
          queryBuilder: (queryBuilder) {
            return queryBuilder.where('isActive', isEqualTo: true);
          },
        )
        .first;

    return _mapBarbershopList(
      docs,
      userLat: position.latitude,
      userLng: position.longitude,
      query: query,
    );
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
    List<DocumentSnapshot<Map<String, dynamic>>> docs, {
    required double userLat,
    required double userLng,
    required String query,
  }) {
    final normalizedQuery = normalizeMembershipQuery(query);
    final results = docs
        .map((doc) {
          final data = doc.data() ?? <String, dynamic>{};
          final shop = Barbershop(
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
            distanceKm: _distanceKm(
              userLat: userLat,
              userLng: userLng,
              lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
              lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
            ),
          );

          return shop;
        })
        .where((shop) {
          if (normalizedQuery.isEmpty) return true;
          return membershipMatchesQuery(shop, normalizedQuery);
        })
        .toList();

    results.sort((a, b) {
      final distanceA = a.distanceKm ?? double.infinity;
      final distanceB = b.distanceKm ?? double.infinity;
      final compareDistance = distanceA.compareTo(distanceB);
      if (compareDistance != 0) return compareDistance;
      return a.name.compareTo(b.name);
    });

    return results;
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: _kLocationTimeout,
      ),
    );
  }

  static double _distanceKm({
    required double userLat,
    required double userLng,
    required double lat,
    required double lng,
  }) {
    return Geolocator.distanceBetween(userLat, userLng, lat, lng) / 1000;
  }
}

String normalizeMembershipQuery(String value) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  var result = value.toLowerCase().trim();
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

bool membershipMatchesQuery(Barbershop shop, String query) {
  final normalizedQuery = normalizeMembershipQuery(query);
  if (normalizedQuery.isEmpty) return true;

  return normalizeMembershipQuery(shop.name).contains(normalizedQuery) ||
      normalizeMembershipQuery(shop.ownerName).contains(normalizedQuery) ||
      normalizeMembershipQuery(shop.address).contains(normalizedQuery) ||
      shop.tags.any(
        (tag) => normalizeMembershipQuery(tag).contains(normalizedQuery),
      );
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();

  @override
  String toString() =>
      'El servicio de ubicación está desactivado. Actívalo en la configuración del dispositivo.';
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();

  @override
  String toString() =>
      'Permiso de ubicación denegado. Por favor, otorga el permiso para continuar.';
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();

  @override
  String toString() =>
      'Permiso de ubicación denegado permanentemente. Ve a Configuración > Aplicaciones para habilitarlo.';
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
