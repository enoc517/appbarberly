import '../../../../../core/usecases/usecase.dart';
import '../../../barbershop_management/domain/entities/barbershop.dart';
import '../repositories/membership_repository.dart';

class SearchBarbershops implements UseCase<List<Barbershop>, String> {
  final MembershipRepository _repository;
  const SearchBarbershops(this._repository);

  @override
  Future<Result<List<Barbershop>>> call(String query) =>
      _repository.searchBarbershops(query);
}
