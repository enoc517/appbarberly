import 'package:barberly/core/datasources/user_validation_datasource.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserValidationDatasource.isPhoneRegistered', () {
    test('returns false when the phone index does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final datasource = UserValidationDatasource(firestore: firestore);

      expect(await datasource.isPhoneRegistered('8888-1234'), isFalse);
    });

    test('returns true when the phone belongs to another user', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('phone_numbers').doc('88881234').set({
        'userId': 'other-user',
        'phone': '88881234',
      });

      final datasource = UserValidationDatasource(firestore: firestore);

      expect(await datasource.isPhoneRegistered('8888 1234'), isTrue);
    });

    test('returns false when the phone belongs to the same user', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('phone_numbers').doc('88881234').set({
        'userId': 'current-user',
        'phone': '88881234',
      });

      final datasource = UserValidationDatasource(firestore: firestore);

      expect(
        await datasource.isPhoneRegistered(
          '(8888) 1234',
          excludeUserId: 'current-user',
        ),
        isFalse,
      );
    });
  });
}
