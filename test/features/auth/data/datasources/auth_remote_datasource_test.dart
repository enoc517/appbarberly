import 'package:barberly/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:barberly/features/auth/data/models/app_user_model.dart';
import 'package:barberly/features/auth/domain/entities/app_user.dart';
import 'package:barberly/core/datasources/user_validation_datasource.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reconstructAuthProfile', () {
    test(
      'preserves profileImageUrl when signIn updates email verification',
      () {
        const profile = AppUserModel(
          id: 'user-1',
          email: 'client@example.com',
          fullName: 'Client User',
          phone: '555-0101',
          profileImageUrl: 'https://cdn.example.com/client/avatar.jpg',
          role: UserRole.client,
          isProfessional: false,
          professionalStatus: ProfessionalStatus.none,
          emailVerified: false,
          barbershopId: 'shop-1',
          activeBookingId: 'booking-1',
          activeBookingStatus: 'confirmed',
        );

        final reconstructed = reconstructAuthProfile(
          profile,
          emailVerified: true,
        );

        expect(
          reconstructed.profileImageUrl,
          'https://cdn.example.com/client/avatar.jpg',
        );
        expect(reconstructed.emailVerified, isTrue);
        expect(reconstructed.barbershopId, 'shop-1');
        expect(reconstructed.activeBookingId, 'booking-1');
        expect(reconstructed.activeBookingStatus, 'confirmed');
      },
    );

    test(
      'preserves profileImageUrl when Google sign-in marks email verified',
      () {
        const profile = AppUserModel(
          id: 'user-2',
          email: 'barber@example.com',
          fullName: 'Barber User',
          phone: '555-0102',
          profileImageUrl: 'https://cdn.example.com/barber/avatar.jpg',
          role: UserRole.barber,
          isProfessional: true,
          professionalStatus: ProfessionalStatus.approved,
          emailVerified: false,
        );

        final reconstructed = reconstructAuthProfile(
          profile,
          emailVerified: true,
        );

        expect(
          reconstructed.profileImageUrl,
          'https://cdn.example.com/barber/avatar.jpg',
        );
        expect(reconstructed.emailVerified, isTrue);
        expect(reconstructed.role, UserRole.barber);
        expect(reconstructed.professionalStatus, ProfessionalStatus.approved);
      },
    );

    test(
      'keeps a missing profileImageUrl absent during current user reload',
      () {
        const profile = AppUserModel(
          id: 'user-3',
          email: 'missing@example.com',
          role: UserRole.client,
          isProfessional: false,
          professionalStatus: ProfessionalStatus.none,
          emailVerified: true,
        );

        final reconstructed = reconstructAuthProfile(
          profile,
          emailVerified: true,
        );

        expect(reconstructed.profileImageUrl, isNull);
        expect(reconstructed.email, 'missing@example.com');
      },
    );
  });

  group('AuthRemoteDatasource.updateUserProfile', () {
    test('creates and moves the phone index when updating the phone', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('user-1').set({
        'phone': '1111',
        'fullName': 'Client User',
        'profileImageUrl': null,
      });
      await firestore.collection('phone_numbers').doc('1111').set({
        'userId': 'user-1',
        'phone': '1111',
      });

      final datasource = AuthRemoteDatasourceImpl(firestore: firestore);

      await datasource.updateUserProfile(uid: 'user-1', phone: '8888-1234');

      final userDoc = await firestore.collection('users').doc('user-1').get();
      expect(userDoc.data()?['phone'], '88881234');

      final oldPhoneDoc = await firestore
          .collection('phone_numbers')
          .doc('1111')
          .get();
      expect(oldPhoneDoc.exists, isFalse);

      final newPhoneDoc = await firestore
          .collection('phone_numbers')
          .doc('88881234')
          .get();
      expect(newPhoneDoc.data()?['userId'], 'user-1');
      expect(newPhoneDoc.data()?['phone'], '88881234');
    });

    test('throws when the new phone already belongs to another user', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('user-1').set({
        'phone': '1111',
        'fullName': 'Client User',
        'profileImageUrl': null,
      });
      await firestore.collection('phone_numbers').doc('88881234').set({
        'userId': 'other-user',
        'phone': '88881234',
      });

      final datasource = AuthRemoteDatasourceImpl(firestore: firestore);

      expect(
        () => datasource.updateUserProfile(uid: 'user-1', phone: '8888 1234'),
        throwsA(isA<PhoneAlreadyRegisteredException>()),
      );

      final userDoc = await firestore.collection('users').doc('user-1').get();
      expect(userDoc.data()?['phone'], '1111');
    });
  });
}
