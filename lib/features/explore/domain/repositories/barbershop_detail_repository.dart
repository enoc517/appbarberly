abstract class BarbershopDetailRepository {
  Future<BarbershopDetailData> getDetail(String shopId);
}

class BarbershopDetailData {
  final Map<String, dynamic>? shop;
  final List<Map<String, dynamic>> members;

  const BarbershopDetailData({this.shop, this.members = const []});
}
