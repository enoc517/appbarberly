import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barberly/features/barber/membership/data/datasources/membership_remote_datasource.dart';

void main() {
  group('MembershipRemoteDatasourceImpl requests', () {
    test('sendRequest stores the request and owner notification', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('barbershops').doc('shop-1').set({
        'ownerId': 'owner-1',
        'name': 'Barbería Central',
      });

      final datasource = MembershipRemoteDatasourceImpl(firestore: firestore);

      final request = await datasource.sendRequest(
        barberId: 'barber-1',
        barberName: 'Juan Pérez',
        barberEmail: 'juan@example.com',
        barberAvatarUrl: 'https://example.com/avatar.png',
        barbershopId: 'shop-1',
        barbershopName: 'Barbería Central',
      );

      expect(request.id, isNotEmpty);

      final requestsSnapshot = await firestore
          .collection('barbershops')
          .doc('shop-1')
          .collection('membership_requests')
          .get();
      expect(requestsSnapshot.docs, hasLength(1));
      expect(requestsSnapshot.docs.single.data()['status'], 'pending');

      final notificationsSnapshot = await firestore
          .collection('notifications')
          .get();
      expect(notificationsSnapshot.docs, hasLength(1));
      final notification = notificationsSnapshot.docs.single.data();
      expect(notification['recipientId'], 'owner-1');
      expect(notification['type'], 'membershipRequest');
      expect(notification['barbershopId'], 'shop-1');
    });

    test('getPendingRequests returns newest requests first', () async {
      final firestore = FakeFirebaseFirestore();
      final requests = firestore
          .collection('barbershops')
          .doc('shop-1')
          .collection('membership_requests');

      await requests.doc('old').set({
        'barberId': 'barber-1',
        'barberName': 'Viejo',
        'barberEmail': 'old@example.com',
        'barberAvatarUrl': '',
        'barbershopId': 'shop-1',
        'barbershopName': 'Barbería Central',
        'status': 'pending',
        'requestedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await requests.doc('new').set({
        'barberId': 'barber-2',
        'barberName': 'Nuevo',
        'barberEmail': 'new@example.com',
        'barberAvatarUrl': '',
        'barbershopId': 'shop-1',
        'barbershopName': 'Barbería Central',
        'status': 'pending',
        'requestedAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
      });

      final datasource = MembershipRemoteDatasourceImpl(firestore: firestore);
      final result = await datasource.getPendingRequests('shop-1');

      expect(result, hasLength(2));
      expect(result.first.barberId, 'barber-2');
      expect(result.last.barberId, 'barber-1');
    });

    test(
      'getPendingRequests returns empty list for empty barbershopId',
      () async {
        final datasource = MembershipRemoteDatasourceImpl(
          firestore: FakeFirebaseFirestore(),
        );

        final result = await datasource.getPendingRequests('');

        expect(result, isEmpty);
      },
    );
  });
}
