class Medicine {
  final int id;
  final String name;
  final String dosage;
  final double price;
  final int stock;
  final int storeId; // branch / branch_id
  final String? genericName;
  final String? description;
  final String? branchName;
  final String? companyName;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.price,
    required this.stock,
    required this.storeId,
    this.genericName,
    this.description,
    this.branchName,
    this.companyName,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'price': price,
    'stock': stock,
    'store_id': storeId,
    'generic_name': genericName,
    'description': description,
    'branch_name': branchName,
    'company_name': companyName,
  };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
    id: map['id'] as int,
    name: (map['name'] as String?) ?? 'Unknown',
    dosage: (map['dosage'] as String?) ?? '',
    price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
    stock: map['stock'] is int ? map['stock'] as int : 0,
    storeId: (map['store_id'] ?? map['branch_id'] ?? -1) as int,
    genericName: map['generic_name'] as String?,
    description: map['description'] as String?,
    branchName: map['branch_name'] as String?,
    companyName: map['company_name'] as String?,
  );
}
