class Venue {
  final String name;
  final String address;
  final int? capacity;
  final bool indoor;

  Venue({
    required this.name,
    required this.address,
    this.capacity,
    required this.indoor,
  });
}
