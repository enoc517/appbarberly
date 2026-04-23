class Service {
  final String id;
  final String name;
  final String description;
  final Duration duration;
  final double price;
  final bool featured;

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    this.featured = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Service && other.id == id);

  @override
  int get hashCode => id.hashCode;
}