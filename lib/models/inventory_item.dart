import 'pharmacy_branch.dart';
import 'medicine.dart';

class InventoryItem {
  final int id;
  final PharmacyBranch branch;
  final Medicine medicine;
  final int stock;
  final double price;
  const InventoryItem({
    required this.id,
    required this.branch,
    required this.medicine,
    required this.stock,
    required this.price,
  });
}
