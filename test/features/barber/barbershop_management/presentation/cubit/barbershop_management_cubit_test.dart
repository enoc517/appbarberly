import 'dart:io';

import 'package:barberly/core/datasources/cloudinary_datasource.dart';
import 'package:barberly/core/events/barbershop_event_bus.dart';
import 'package:barberly/core/usecases/usecase.dart';
import 'package:barberly/features/barber/barbershop_management/domain/entities/barbershop.dart';
import 'package:barberly/features/barber/barbershop_management/domain/repositories/barbershop_management_repository.dart';
import 'package:barberly/features/barber/barbershop_management/domain/usecases/create_barbershop.dart';
import 'package:barberly/features/barber/barbershop_management/domain/usecases/get_barbershop_by_owner.dart';
import 'package:barberly/features/barber/barbershop_management/domain/usecases/update_barbershop.dart';
import 'package:barberly/features/barber/barbershop_management/presentation/cubit/barbershop_management_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarbershopManagementCubit', () {
    late _FakeRepository repository;
    late _FakeImageUploader imageUploader;
    late BarbershopManagementCubit cubit;

    setUp(() {
      repository = _FakeRepository();
      imageUploader = _FakeImageUploader();
      cubit = BarbershopManagementCubit(
        createBarbershop: CreateBarbershop(repository),
        updateBarbershop: UpdateBarbershop(repository),
        getBarbershopByOwner: GetBarbershopByOwner(repository),
        imageUploader: imageUploader,
        eventBus: BarbershopEventBus.instance,
      );
    });

    test('create uploads image before delegating to usecase', () async {
      await cubit.create(
        _createParams(imageUrl: ''),
        imageFile: File('shop.jpg'),
      );

      expect(imageUploader.calls, ['shop.jpg:barbershops:owner-1/barbershop']);
      expect(
        repository.createCalls.single.imageUrl,
        'https://cdn.example/shop.jpg',
      );
    });

    test('update uploads image before delegating to usecase', () async {
      await cubit.update(_updateParams(), imageFile: File('updated.jpg'));

      expect(imageUploader.calls, [
        'updated.jpg:barbershops:shop-1/barbershop',
      ]);
      expect(
        repository.updateCalls.single.imageUrl,
        'https://cdn.example/updated.jpg',
      );
    });
  });
}

class _FakeRepository implements BarbershopManagementRepository {
  final createCalls = <CreateBarbershopParams>[];
  final updateCalls = <UpdateBarbershopParams>[];

  @override
  Future<Result<Barbershop>> create(CreateBarbershopParams params) async {
    createCalls.add(params);
    return Ok(
      _barbershop(
        params.ownerId,
        params.ownerName,
        params.name,
        params.imageUrl,
      ),
    );
  }

  @override
  Future<Result<Barbershop?>> getByOwner(String ownerId) async {
    return Ok(null);
  }

  @override
  Future<Result<Barbershop>> update(UpdateBarbershopParams params) async {
    updateCalls.add(params);
    return Ok(
      _barbershop(
        'owner-1',
        'Owner',
        params.name ?? 'Shop',
        params.imageUrl ?? '',
      ),
    );
  }

  Barbershop _barbershop(
    String ownerId,
    String ownerName,
    String name,
    String imageUrl,
  ) {
    return Barbershop(
      id: 'shop-1',
      ownerId: ownerId,
      ownerName: ownerName,
      name: name,
      phone: '8888-8888',
      address: 'Address',
      lat: 8.61,
      lng: -82.95,
      imageUrl: imageUrl,
      rating: 0,
      reviewCount: 0,
      hasActivePromotion: false,
      tags: const ['Corte'],
      isActive: true,
    );
  }
}

class _FakeImageUploader implements ImageUploadDatasource {
  final calls = <String>[];

  @override
  Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    calls.add('${file.path}:$folder:$publicId');
    return 'https://cdn.example/${file.path}';
  }
}

CreateBarbershopParams _createParams({required String imageUrl}) {
  return CreateBarbershopParams(
    ownerId: 'owner-1',
    ownerName: 'Owner',
    name: 'Shop',
    phone: '8888-8888',
    address: 'Address',
    lat: 8.61,
    lng: -82.95,
    imageUrl: imageUrl,
    tags: const ['Corte'],
  );
}

UpdateBarbershopParams _updateParams() {
  return const UpdateBarbershopParams(
    id: 'shop-1',
    name: 'Shop',
    phone: '8888-8888',
    address: 'Address',
    lat: 8.61,
    lng: -82.95,
    imageUrl: null,
    tags: ['Corte'],
  );
}
