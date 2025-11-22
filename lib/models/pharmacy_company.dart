class PharmacyCompany {
  final int id;
  final String name;
  final String? logoUrl;
  final String? contactNumber;
  const PharmacyCompany({
    required this.id,
    required this.name,
    this.logoUrl,
    this.contactNumber,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'logo_url': logoUrl,
    'contact_number': contactNumber,
  };

  factory PharmacyCompany.fromMap(Map<String, dynamic> map) => PharmacyCompany(
    id: map['id'] as int,
    name: (map['name'] as String?) ?? 'Unknown',
    logoUrl: map['logo_url'] as String?,
    contactNumber: map['contact_number'] as String?,
  );
}
