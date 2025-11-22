class Store {
  final int id;
  final String name; // Branch name
  final String chain; // Company name
  final String address;
  final String phone;
  final double distanceKm;
  final bool isOpen;

  const Store({
    required this.id,
    required this.name,
    required this.chain,
    required this.address,
    required this.phone,
    required this.distanceKm,
    required this.isOpen,
  });
}
