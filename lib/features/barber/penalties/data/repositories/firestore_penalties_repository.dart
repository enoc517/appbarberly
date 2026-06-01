import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/penalty.dart';
import '../../domain/repositories/penalties_repository.dart';

class FirestorePenaltiesRepository implements PenaltiesRepository {
  FirestorePenaltiesRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _penalties =>
      _db.collection('penalties');

  @override
  Stream<List<Penalty>> watchPendingPenalties(String barbershopId) {
    return _penalties
        .where('barbershopId', isEqualTo: barbershopId)
        .snapshots()
        .map((snapshot) {
          final penalties = snapshot.docs
              .map(_PenaltyModel.fromDocument)
              .where((penalty) => penalty.status == PenaltyStatus.pending)
              .toList();
          penalties.sort(
            (a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch),
          );
          return penalties;
        });
  }

  @override
  Future<void> markAsPaid(String penaltyId) {
    return _resolve(penaltyId: penaltyId, status: PenaltyStatus.paid);
  }

  @override
  Future<void> waive(String penaltyId) {
    return _resolve(penaltyId: penaltyId, status: PenaltyStatus.waived);
  }

  Future<void> _resolve({
    required String penaltyId,
    required PenaltyStatus status,
  }) async {
    final penaltyRef = _penalties.doc(penaltyId);
    final notificationRef = _db.collection('notifications').doc();

    await _db.runTransaction((transaction) async {
      final penaltySnapshot = await transaction.get(penaltyRef);
      final penaltyData = penaltySnapshot.data();
      if (penaltyData == null) return;

      transaction.update(penaltyRef, {
        'status': status.name,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final clientId = penaltyData['clientId'] as String? ?? '';
      if (clientId.isEmpty) return;

      transaction.set(notificationRef, {
        'recipientId': clientId,
        'recipientRole': 'client',
        'type': 'penaltyResolved',
        'title': status == PenaltyStatus.paid
            ? 'Penalización pagada'
            : 'Penalización perdonada',
        'body': _resolvedNotificationBody(penaltyData, status),
        'bookingId': penaltyData['bookingId'] as String? ?? '',
        'barbershopId': penaltyData['barbershopId'] as String? ?? '',
        'penaltyId': penaltyId,
        'readAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'data': {'status': status.name},
      });
    });
  }

  static String _resolvedNotificationBody(
    Map<String, dynamic> penaltyData,
    PenaltyStatus status,
  ) {
    final serviceSnapshot = _snapshotMap(penaltyData['serviceSnapshot']);
    final serviceName = serviceSnapshot['name'] as String? ?? 'tu cita';
    final amount = ((penaltyData['penaltyAmount'] as num?)?.toDouble() ?? 0)
        .toStringAsFixed(0);
    if (status == PenaltyStatus.paid) {
      return 'Se registró el pago de \$$amount por $serviceName.';
    }
    return 'La barbería perdonó la penalización de \$$amount por $serviceName.';
  }

  static Map<String, dynamic> _snapshotMap(Object? value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }
}

class _PenaltyModel extends Penalty {
  const _PenaltyModel({
    required super.id,
    required super.bookingId,
    required super.barbershopId,
    required super.barberId,
    required super.clientId,
    required super.clientName,
    required super.serviceName,
    required super.appointmentStart,
    required super.servicePrice,
    required super.penaltyAmount,
    required super.penaltyPercent,
    required super.status,
    super.clientAvatarUrl,
    super.createdAt,
    super.resolvedAt,
  });

  factory _PenaltyModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final clientSnapshot = _map(data['clientSnapshot']);
    final serviceSnapshot = _map(data['serviceSnapshot']);

    return _PenaltyModel(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      barbershopId: data['barbershopId'] as String? ?? '',
      barberId: data['barberId'] as String? ?? '',
      clientId: data['clientId'] as String? ?? '',
      clientName: clientSnapshot['name'] as String? ?? 'Cliente',
      clientAvatarUrl: clientSnapshot['imageUrl'] as String?,
      serviceName: serviceSnapshot['name'] as String? ?? 'Servicio',
      appointmentStart: _dateTime(data['appointmentStart']),
      servicePrice: (data['servicePrice'] as num?)?.toDouble() ?? 0,
      penaltyAmount: (data['penaltyAmount'] as num?)?.toDouble() ?? 0,
      penaltyPercent: (data['penaltyPercent'] as num?)?.toInt() ?? 50,
      status: _status(data['status'] as String?),
      createdAt: _nullableDateTime(data['createdAt']),
      resolvedAt: _nullableDateTime(data['resolvedAt']),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    return _dateTime(value);
  }

  static PenaltyStatus _status(String? value) {
    return PenaltyStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PenaltyStatus.pending,
    );
  }
}

extension on Penalty {
  DateTime get createdAtOrEpoch =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}
