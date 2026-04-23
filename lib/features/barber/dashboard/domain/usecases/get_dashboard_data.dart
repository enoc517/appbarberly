import '../../../../../core/usecases/usecase.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardData implements UseCase<DashboardData, String> {
  final DashboardRepository _repository;
  const GetDashboardData(this._repository);

  @override
  Future<Result<DashboardData>> call(String barberId) =>
      _repository.getDashboardData(barberId);
}