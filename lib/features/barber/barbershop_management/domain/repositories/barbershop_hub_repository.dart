class BarbershopHubInfo {
  final bool hasBarbershop;
  final String? barbershopId;
  final String? barbershopName;
  final bool isOwner;

  const BarbershopHubInfo({
    this.hasBarbershop = false,
    this.barbershopId,
    this.barbershopName,
    this.isOwner = false,
  });
}

abstract class BarbershopHubRepository {
  Future<BarbershopHubInfo> getHubInfo(String userId);
}
