import 'pharmacy_company.dart';

class PharmacyBranch {
  final int id;
  final PharmacyCompany company;
  final String branchName;
  final String branchAddress;
  final String? phoneNumber;
  const PharmacyBranch({
    required this.id,
    required this.company,
    required this.branchName,
    required this.branchAddress,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'company_id': company.id,
    'branch_name': branchName,
    'branch_address': branchAddress,
    'phone_number': phoneNumber,
  };

  factory PharmacyBranch.fromMap(
    Map<String, dynamic> map,
    PharmacyCompany company,
  ) => PharmacyBranch(
    id: map['id'] as int,
    company: company,
    branchName: (map['branch_name'] as String?) ?? 'Branch',
    branchAddress: (map['branch_address'] as String?) ?? 'Address unknown',
    phoneNumber: map['phone_number'] as String?,
  );
}
