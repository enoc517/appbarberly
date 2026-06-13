import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/events/barbershop_event_bus.dart';
import '../../../../../core/datasources/cloudinary_datasource.dart';
import '../../domain/repositories/barbershop_management_repository.dart';
import '../../domain/usecases/create_barbershop.dart';
import '../../domain/usecases/get_barbershop_by_owner.dart';
import '../../domain/usecases/update_barbershop.dart';
import 'barbershop_management_state.dart';

class BarbershopManagementCubit extends Cubit<BarbershopManagementState> {
  BarbershopManagementCubit({
    required CreateBarbershop createBarbershop,
    required UpdateBarbershop updateBarbershop,
    required GetBarbershopByOwner getBarbershopByOwner,
    required ImageUploadDatasource imageUploader,
    required BarbershopEventBus eventBus,
  }) : _createBarbershop = createBarbershop,
       _updateBarbershop = updateBarbershop,
       _getBarbershopByOwner = getBarbershopByOwner,
       _imageUploader = imageUploader,
       _eventBus = eventBus,
       super(const BarbershopManagementInitial());

  final CreateBarbershop _createBarbershop;
  final UpdateBarbershop _updateBarbershop;
  final GetBarbershopByOwner _getBarbershopByOwner;
  final ImageUploadDatasource _imageUploader;
  final BarbershopEventBus _eventBus;

  Future<void> create(CreateBarbershopParams params, {File? imageFile}) async {
    emit(const BarbershopManagementLoading());
    try {
      final result = await _createBarbershop(
        await _maybeUploadCreateParams(params, imageFile),
      );
      emit(
        result.when(
          ok: (shop) {
            _eventBus.emit(BarbershopEvent.barbershopCreated);
            return BarbershopCreated(shop);
          },
          fail: (f) => BarbershopManagementError(f.message),
        ),
      );
    } on StateError catch (e) {
      emit(BarbershopManagementError(e.message));
    }
  }

  Future<void> update(UpdateBarbershopParams params, {File? imageFile}) async {
    emit(const BarbershopManagementLoading());
    try {
      final result = await _updateBarbershop(
        await _maybeUploadUpdateParams(params, imageFile),
      );
      emit(
        result.when(
          ok: (shop) {
            _eventBus.emit(BarbershopEvent.barbershopUpdated);
            return BarbershopUpdated(shop);
          },
          fail: (f) => BarbershopManagementError(f.message),
        ),
      );
    } on StateError catch (e) {
      emit(BarbershopManagementError(e.message));
    }
  }

  Future<void> load(String ownerId) async {
    emit(const BarbershopManagementLoading());
    final result = await _getBarbershopByOwner(ownerId);
    emit(
      result.when(
        ok: (shop) => BarbershopLoaded(shop),
        fail: (f) => BarbershopManagementError(f.message),
      ),
    );
  }

  Future<CreateBarbershopParams> _maybeUploadCreateParams(
    CreateBarbershopParams params,
    File? imageFile,
  ) async {
    if (imageFile == null) return params;

    try {
      final imageUrl = await _imageUploader.uploadImage(
        file: imageFile,
        folder: 'barbershops',
        publicId: '${params.ownerId}/barbershop',
      );
      return CreateBarbershopParams(
        ownerId: params.ownerId,
        ownerName: params.ownerName,
        name: params.name,
        phone: params.phone,
        address: params.address,
        lat: params.lat,
        lng: params.lng,
        imageUrl: imageUrl,
        tags: params.tags,
      );
    } catch (e) {
      throw StateError('Error al subir imagen: ${e.toString()}');
    }
  }

  Future<UpdateBarbershopParams> _maybeUploadUpdateParams(
    UpdateBarbershopParams params,
    File? imageFile,
  ) async {
    if (imageFile == null) return params;

    try {
      final imageUrl = await _imageUploader.uploadImage(
        file: imageFile,
        folder: 'barbershops',
        publicId: '${params.id}/barbershop',
      );
      return UpdateBarbershopParams(
        id: params.id,
        name: params.name,
        phone: params.phone,
        address: params.address,
        lat: params.lat,
        lng: params.lng,
        imageUrl: imageUrl,
        tags: params.tags,
      );
    } catch (e) {
      throw StateError('Error al subir imagen: ${e.toString()}');
    }
  }
}
