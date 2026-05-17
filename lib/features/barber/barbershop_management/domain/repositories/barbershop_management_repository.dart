import '../../../../../core/usecases/usecase.dart';
import '../entities/barbershop.dart';

class CreateBarbershopParams {
  final String ownerId;
  final String ownerName;
  final String name;
  final String phone;
  final String address;
  final double lat;
  final double lng;
  final String imageUrl;
  final List<String> tags;

  const CreateBarbershopParams({
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.phone,
    required this.address,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.tags,
  });
}

class UpdateBarbershopParams {
  final String id;
  final String? name;
  final String? phone;
  final String? address;
  final double? lat;
  final double? lng;
  final String? imageUrl;
  final List<String>? tags;

  const UpdateBarbershopParams({
    required this.id,
    this.name,
    this.phone,
    this.address,
    this.lat,
    this.lng,
    this.imageUrl,
    this.tags,
  });
}

abstract class BarbershopManagementRepository {
  Future<Result<Barbershop>> create(CreateBarbershopParams params);
  Future<Result<Barbershop>> update(UpdateBarbershopParams params);
  Future<Result<Barbershop?>> getByOwner(String ownerId);
}
