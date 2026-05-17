import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../../domain/entities/barbershop.dart';
import '../../domain/repositories/barbershop_management_repository.dart';

abstract class BarbershopManagementRemoteDatasource {
  Future<Barbershop> create({
    required String ownerId,
    required String ownerName,
    required CreateBarbershopParams params,
  });

  Future<Barbershop> update(UpdateBarbershopParams params);

  Future<Barbershop?> getByOwner(String ownerId);
}

class BarbershopManagementRemoteDatasourceImpl
    implements BarbershopManagementRemoteDatasource {
  BarbershopManagementRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _shopsCollection =>
      _db.collection('barbershops');

  CollectionReference<Map<String, dynamic>> _membersCollection(
    String shopId,
  ) => _shopsCollection.doc(shopId).collection('members');

  @override
  Future<Barbershop> create({
    required String ownerId,
    required String ownerName,
    required CreateBarbershopParams params,
  }) async {
    final docRef = _shopsCollection.doc();
    final geoFirePoint = GeoFirePoint(GeoPoint(params.lat, params.lng));

    final data = <String, dynamic>{
      'ownerId': ownerId,
      'ownerName': ownerName,
      'name': params.name,
      'phone': params.phone,
      'address': params.address,
      'lat': params.lat,
      'lng': params.lng,
      'imageUrl': params.imageUrl,
      'rating': 0.0,
      'reviewCount': 0,
      'hasActivePromotion': false,
      'tags': params.tags,
      'isActive': true,
      'position': geoFirePoint.data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);

    await _membersCollection(docRef.id).doc(ownerId).set({
      'barberId': ownerId,
      'barberName': ownerName,
      'barberAvatarUrl': '',
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(ownerId).set({
      'barbershopId': docRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return Barbershop(
      id: docRef.id,
      ownerId: ownerId,
      ownerName: ownerName,
      name: params.name,
      phone: params.phone,
      address: params.address,
      lat: params.lat,
      lng: params.lng,
      imageUrl: params.imageUrl,
      rating: 0.0,
      reviewCount: 0,
      hasActivePromotion: false,
      tags: params.tags,
      isActive: true,
    );
  }

  @override
  Future<Barbershop> update(UpdateBarbershopParams params) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (params.name != null) data['name'] = params.name;
    if (params.phone != null) data['phone'] = params.phone;
    if (params.address != null) data['address'] = params.address;
    if (params.imageUrl != null) data['imageUrl'] = params.imageUrl;
    if (params.tags != null) data['tags'] = params.tags;

    if (params.lat != null && params.lng != null) {
      final geoFirePoint = GeoFirePoint(GeoPoint(params.lat!, params.lng!));
      data['position'] = geoFirePoint.data;
      data['lat'] = params.lat;
      data['lng'] = params.lng;
    }

    await _shopsCollection.doc(params.id).set(data, SetOptions(merge: true));

    final doc = await _shopsCollection.doc(params.id).get();
    final docData = doc.data() ?? <String, dynamic>{};

    return _mapToEntity(doc.id, docData);
  }

  @override
  Future<Barbershop?> getByOwner(String ownerId) async {
    final snapshot = await _shopsCollection
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return _mapToEntity(doc.id, doc.data());
  }

  Barbershop _mapToEntity(String id, Map<String, dynamic> data) {
    return Barbershop(
      id: id,
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
  }
}
