import 'package:flutter/foundation.dart';
import '../models/pharmacy_branch.dart';
import '../services/sqlite_service.dart';

class BranchStore extends ChangeNotifier {
  List<PharmacyBranch> _branches = [];
  int _inventoryItems = 0;
  int _uniqueMedicineCount = 0;
  bool _isLoading = false;
  bool _initialized = false;

  BranchStore() {
    _initialLoad();
  }

  List<PharmacyBranch> get branches => _branches;
  int get inventoryItems => _inventoryItems;
  int get uniqueMedicineCount => _uniqueMedicineCount;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  Future<void> _initialLoad() async {
    await refresh();
    _initialized = true;
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedBranches = await SqliteService.fetchBranches();
      final inventory = await SqliteService.fetchInventory();
      final uniqueIds = <int>{};
      for (final item in inventory) {
        uniqueIds.add(item.medicine.id);
      }
      _branches = fetchedBranches;
      _inventoryItems = inventory.length;
      _uniqueMedicineCount = uniqueIds.length;
    } catch (_) {
      // Swallow errors; UI can show empty state.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convenience trigger after branch mutation.
  Future<void> markDirtyAndRefresh() => refresh();
}
