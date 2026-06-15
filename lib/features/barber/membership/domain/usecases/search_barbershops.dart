import '../../../../../core/usecases/usecase.dart';
import '../../../barbershop_management/domain/entities/barbershop.dart';
import '../repositories/membership_repository.dart';

class SearchBarbershopsParams {
  final String query;
  final double radiusKm;

  const SearchBarbershopsParams({required this.query, required this.radiusKm});
}

class SearchBarbershops
    implements UseCase<List<Barbershop>, SearchBarbershopsParams> {
  final MembershipRepository _repository;
  const SearchBarbershops(this._repository);

  @override
  Future<Result<List<Barbershop>>> call(SearchBarbershopsParams params) =>
      _repository.searchBarbershops(
        query: params.query,
        radiusKm: params.radiusKm,
      );
}
