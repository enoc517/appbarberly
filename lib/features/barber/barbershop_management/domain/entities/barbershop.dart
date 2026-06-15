class Barbershop {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String phone;
  final String address;
  final double lat;
  final double lng;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool hasActivePromotion;
  final List<String> tags;
  final bool isActive;
  final double? distanceKm;

  const Barbershop({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.phone,
    required this.address,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.hasActivePromotion,
    required this.tags,
    required this.isActive,
    this.distanceKm,
  });
}
