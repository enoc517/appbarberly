import 'package:flutter_test/flutter_test.dart';

import 'package:barberly/features/barber/barbershop_management/domain/entities/barbershop.dart';
import 'package:barberly/features/barber/membership/data/datasources/membership_remote_datasource.dart';

void main() {
  group('Membership search helpers', () {
    test('normalizes accents and casing', () {
      expect(normalizeMembershipQuery('Barbería Ñuño'), 'barberia nuno');
    });

    test('matches by shop name, owner and address', () {
      final shop = Barbershop(
        id: 'shop-1',
        ownerId: 'owner-1',
        ownerName: 'José Pérez',
        name: 'Barbería Central',
        phone: '1234',
        address: 'Avenida Principal',
        lat: 0,
        lng: 0,
        imageUrl: '',
        rating: 0,
        reviewCount: 0,
        hasActivePromotion: false,
        tags: const ['Fade', 'Premium'],
        isActive: true,
      );

      expect(membershipMatchesQuery(shop, 'barberia'), isTrue);
      expect(membershipMatchesQuery(shop, 'jose'), isTrue);
      expect(membershipMatchesQuery(shop, 'principal'), isTrue);
      expect(membershipMatchesQuery(shop, 'premium'), isTrue);
      expect(membershipMatchesQuery(shop, 'inexistente'), isFalse);
    });
  });
}
