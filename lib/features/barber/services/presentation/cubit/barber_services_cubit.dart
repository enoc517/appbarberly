import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/add_service.dart';
import '../../domain/usecases/delete_service.dart';
import '../../domain/usecases/get_barber_services.dart';
import '../../domain/usecases/update_service.dart';
import 'barber_services_state.dart';

const int kMinServiceDurationMinutes = 5;
const int kMaxServiceDurationMinutes = 240;
const int kDefaultServiceDurationMinutes = 60;

class BarberServicesCubit extends Cubit<BarberServicesState> {
  final GetBarberServices _getBarberServices;
  final AddService _addService;
  final UpdateService _updateService;
  final DeleteService _deleteService;

  BarberServicesCubit({
    required GetBarberServices getBarberServices,
    required AddService addService,
    required UpdateService updateService,
    required DeleteService deleteService,
  }) : _getBarberServices = getBarberServices,
       _addService = addService,
       _updateService = updateService,
       _deleteService = deleteService,
       super(const BarberServicesInitial());

  String? _barbershopId;
  String? _barberId;

  Future<void> load(String barbershopId, String barberId) async {
    if (barbershopId.isEmpty || barberId.isEmpty) return;

    _barbershopId = barbershopId;
    _barberId = barberId;
    emit(const BarberServicesLoading());
    final result = await _getBarberServices(
      GetBarberServicesParams(barbershopId: barbershopId, barberId: barberId),
    );
    emit(
      result.when(
        ok: (services) => BarberServicesLoaded(services),
        fail: (f) => BarberServicesError(f.message),
      ),
    );
  }

  Future<void> addService({
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    required String category,
  }) async {
    if (_barbershopId == null || _barberId == null) return;
    final validationError = _validateDuration(durationMinutes);
    if (validationError != null) {
      emit(BarberServicesError(validationError));
      return;
    }

    final result = await _addService(
      AddServiceParams(
        barbershopId: _barbershopId!,
        barberId: _barberId!,
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        category: category,
      ),
    );

    emit(
      result.when(
        ok: (service) => BarberServiceAdded(service),
        fail: (f) => BarberServicesError(f.message),
      ),
    );
  }

  Future<void> updateService({
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? category,
  }) async {
    if (_barbershopId == null || _barberId == null) return;
    if (durationMinutes != null) {
      final validationError = _validateDuration(durationMinutes);
      if (validationError != null) {
        emit(BarberServicesError(validationError));
        return;
      }
    }

    final result = await _updateService(
      UpdateServiceParams(
        barbershopId: _barbershopId!,
        barberId: _barberId!,
        serviceId: serviceId,
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        category: category,
      ),
    );

    emit(
      result.when(
        ok: (service) => BarberServiceUpdated(service),
        fail: (f) => BarberServicesError(f.message),
      ),
    );
  }

  Future<void> deleteService(String serviceId) async {
    if (_barbershopId == null || _barberId == null) return;

    final result = await _deleteService(
      DeleteServiceParams(
        barbershopId: _barbershopId!,
        barberId: _barberId!,
        serviceId: serviceId,
      ),
    );

    emit(
      result.when(
        ok: (_) => const BarberServiceDeleted(),
        fail: (f) => BarberServicesError(f.message),
      ),
    );
  }

  void reload() {
    if (_barbershopId != null && _barberId != null) {
      load(_barbershopId!, _barberId!);
    }
  }

  String? _validateDuration(int durationMinutes) {
    if (durationMinutes < kMinServiceDurationMinutes ||
        durationMinutes > kMaxServiceDurationMinutes) {
      return 'La duración debe estar entre $kMinServiceDurationMinutes y $kMaxServiceDurationMinutes minutos';
    }
    return null;
  }
}
