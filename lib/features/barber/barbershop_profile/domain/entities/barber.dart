class Barber {
  final String id;
  final String name;
  final String? avatarUrl;

  const Barber({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Barber && other.id == id);

  @override
  int get hashCode => id.hashCode;
}