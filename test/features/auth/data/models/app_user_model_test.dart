import 'package:barberly/features/auth/data/models/app_user_model.dart';
import 'package:barberly/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserModel profileImageUrl mapping', () {
    test('fromMap preserves a persisted profile image URL', () {
      final user = AppUserModel.fromMap('user-1', const {
        'email': 'client@example.com',
        'fullName': 'Client User',
        'phone': '555-0101',
        'profileImageUrl': 'https://cdn.example.com/client/avatar.jpg',
        'role': 'client',
        'isProfessional': false,
        'professionalStatus': 'none',
        'emailVerified': true,
      });

      expect(user.profileImageUrl, 'https://cdn.example.com/client/avatar.jpg');
    });

    test('fromMap remains valid when profile image URL is absent', () {
      final user = AppUserModel.fromMap('user-2', const {
        'email': 'barber@example.com',
        'role': 'barber',
        'isProfessional': true,
        'professionalStatus': 'approved',
      });

      expect(user.profileImageUrl, isNull);
      expect(user.role, UserRole.barber);
      expect(user.professionalStatus, ProfessionalStatus.approved);
    });

    test('toMap includes the profile image URL for persistence', () {
      const user = AppUserModel(
        id: 'user-3',
        email: 'saved@example.com',
        fullName: 'Saved User',
        phone: '555-0103',
        profileImageUrl: 'https://cdn.example.com/saved/avatar.jpg',
        role: UserRole.client,
        isProfessional: false,
        professionalStatus: ProfessionalStatus.none,
        emailVerified: true,
      );

      final map = user.toMap();

      expect(
        map['profileImageUrl'],
        'https://cdn.example.com/saved/avatar.jpg',
      );
    });
  });
}
