import '../entities/penalty.dart';

abstract class PenaltiesRepository {
  Stream<List<Penalty>> watchPendingPenalties(String barbershopId);

  Future<void> markAsPaid(String penaltyId);

  Future<void> waive(String penaltyId);
}
