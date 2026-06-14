import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../explore/data/models/explore_models.dart';
import '../../../../explore/domain/entities/explore_entities.dart';
import '../../../../explore/data/repositories/barber_booking_repository_impl.dart';
import '../../../../explore/domain/repositories/barber_booking_repository.dart';
import '../../domain/entities/favorite_barbershop_entry.dart';
import '../../domain/repositories/favorites_repository.dart';

class FirestoreFavoritesRepository implements FavoritesRepository {
  FirestoreFavoritesRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance,
      _bookingRepository = BarberBookingRepositoryImpl(firestore: firestore);

  final FirebaseFirestore _db;
  final BarberBookingRepository _bookingRepository;

  CollectionReference<Map<String, dynamic>> _favoritesFor(String userId) =>
      _db.collection('users').doc(userId).collection('favorites');

  @override
  Stream<List<FavoriteBarbershopEntry>> watchFavoriteBarbershops(
    String userId,
  ) {
    return _favoritesFor(userId).snapshots().asyncMap(_buildEntries);
  }

  @override
  Future<bool> isFavorite(String userId, String barbershopId) async {
    final doc = await _favoritesFor(userId).doc(barbershopId).get();
    return doc.exists;
  }

  @override
  Future<void> addFavorite({
    required String userId,
    required String barbershopId,
    DateTime? lastBookedAt,
    String? lastServiceId,
    String? lastServiceName,
    String? lastBarberId,
    String? lastBarberName,
    int? bookingCount,
  }) async {
    final ref = _favoritesFor(userId).doc(barbershopId);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = <String, dynamic>{
        'barbershopId': barbershopId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (lastBookedAt != null) {
        data['lastBookedAt'] = Timestamp.fromDate(lastBookedAt);
      }
      if (lastServiceId != null) data['lastServiceId'] = lastServiceId;
      if (lastServiceName != null) data['lastServiceName'] = lastServiceName;
      if (lastBarberId != null) data['lastBarberId'] = lastBarberId;
      if (lastBarberName != null) data['lastBarberName'] = lastBarberName;
      if (bookingCount != null) data['bookingCount'] = bookingCount;
      await ref.set(data, SetOptions(merge: true));
      return;
    }

    final data = <String, dynamic>{
      'barbershopId': barbershopId,
      'addedAt': FieldValue.serverTimestamp(),
      'bookingCount': bookingCount ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (lastBookedAt != null) {
      data['lastBookedAt'] = Timestamp.fromDate(lastBookedAt);
    }
    if (lastServiceId != null) data['lastServiceId'] = lastServiceId;
    if (lastServiceName != null) data['lastServiceName'] = lastServiceName;
    if (lastBarberId != null) data['lastBarberId'] = lastBarberId;
    if (lastBarberName != null) data['lastBarberName'] = lastBarberName;
    await ref.set(data);
  }

  @override
  Future<void> removeFavorite({
    required String userId,
    required String barbershopId,
  }) async {
    await _favoritesFor(userId).doc(barbershopId).delete();
  }

  @override
  Future<void> recordFavoriteBooking({
    required String userId,
    required String barbershopId,
    required DateTime bookedAt,
    required String serviceId,
    required String serviceName,
    required String barberId,
    required String barberName,
  }) async {
    final ref = _favoritesFor(userId).doc(barbershopId);
    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? <String, dynamic>{};
    final bookingCount = (data['bookingCount'] as num?)?.toInt() ?? 0;
    await ref.set({
      'barbershopId': barbershopId,
      'lastBookedAt': Timestamp.fromDate(bookedAt),
      'lastServiceId': serviceId,
      'lastServiceName': serviceName,
      'lastBarberId': barberId,
      'lastBarberName': barberName,
      'bookingCount': bookingCount + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<FavoriteBarbershopEntry>> _buildEntries(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final favoriteDocs = snapshot.docs;
    if (favoriteDocs.isEmpty) return const [];

    final favoriteDataById = {
      for (final doc in favoriteDocs) doc.id: doc.data(),
    };

    final ids = favoriteDocs.map((doc) => doc.id).toList(growable: false);
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    final shops = <BarbershopEntity>[];
    for (final chunk in chunks) {
      final query = await _db
          .collection('barbershops')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      shops.addAll(
        query.docs.map((doc) => BarbershopModel.fromDocument(doc).toEntity()),
      );
    }

    final byId = {for (final shop in shops) shop.id: shop};
    final entries = <FavoriteBarbershopEntry>[];

    for (final id in ids) {
      final shop = byId[id];
      if (shop == null) continue;
      final data = favoriteDataById[id] ?? <String, dynamic>{};
      entries.add(
        FavoriteBarbershopEntry(
          shop: shop,
          addedAt: _dateTime(data['addedAt']),
          lastBookedAt: _dateTimeOrNull(data['lastBookedAt']),
          lastServiceId: data['lastServiceId'] as String?,
          lastServiceName: data['lastServiceName'] as String?,
          lastBarberId: data['lastBarberId'] as String?,
          lastBarberName: data['lastBarberName'] as String?,
          bookingCount: (data['bookingCount'] as num?)?.toInt() ?? 0,
          isOpenNow: await _isOpenNow(
            shopId: shop.id,
            barberId: data['lastBarberId'] as String?,
          ),
          nextAvailableLabel: await _nextAvailableLabel(
            shopId: shop.id,
            barberId: data['lastBarberId'] as String?,
            serviceId: data['lastServiceId'] as String?,
          ),
        ),
      );
    }

    entries.sort((a, b) {
      final aTime =
          a.lastBookedAt ?? a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.lastBookedAt ?? b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final compare = bTime.compareTo(aTime);
      if (compare != 0) return compare;
      return a.shop.name.compareTo(b.shop.name);
    });

    return entries;
  }

  Future<bool?> _isOpenNow({
    required String shopId,
    required String? barberId,
  }) async {
    if (barberId == null || barberId.isEmpty) return null;

    final result = await _bookingRepository.loadBarberData(shopId, barberId);
    final schedule = result.schedule[DateTime.now().weekday];
    if (schedule == null || !schedule.isActive) return false;

    final now = DateTime.now();
    final start = _timeOfDay(now, schedule.startTime);
    final end = _timeOfDay(now, schedule.endTime);
    return !now.isBefore(start) && now.isBefore(end);
  }

  Future<String?> _nextAvailableLabel({
    required String shopId,
    required String? barberId,
    required String? serviceId,
  }) async {
    if (barberId == null ||
        barberId.isEmpty ||
        serviceId == null ||
        serviceId.isEmpty) {
      return null;
    }

    final serviceDoc = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('barbers')
        .doc(barberId)
        .collection('services')
        .doc(serviceId)
        .get();
    final durationMinutes =
        (serviceDoc.data()?['durationMinutes'] as num?)?.toInt() ?? 0;
    if (durationMinutes <= 0) return null;

    for (var i = 0; i < 7; i++) {
      final day = DateTime.now().add(Duration(days: i));
      final slots = await _bookingRepository.loadAvailableTimeSlots(
        shopId: shopId,
        barberId: barberId,
        day: DateTime(day.year, day.month, day.day),
        durationMinutes: durationMinutes,
      );
      if (slots.isNotEmpty) {
        final labelDay = i == 0
            ? 'Hoy'
            : i == 1
            ? 'Mañana'
            : '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';
        return '$labelDay ${slots.first}';
      }
    }

    return null;
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) return null;
    return _dateTime(value);
  }

  static DateTime _timeOfDay(DateTime day, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}
