import 'package:flutter/foundation.dart';
import '../models/medicine.dart';

/// Simple in-memory tracker of recently viewed medicines.
/// Keeps the last [maxItems] unique medicines (most recent first).
class RecentlyViewedService {
  RecentlyViewedService._();
  static final RecentlyViewedService instance = RecentlyViewedService._();

  final int maxItems = 5;
  final ValueNotifier<List<Medicine>> _notifier = ValueNotifier<List<Medicine>>(
    [],
  );

  ValueListenable<List<Medicine>> get listenable => _notifier;

  void add(Medicine medicine) {
    final current = List<Medicine>.from(_notifier.value);
    // Remove any existing occurrence
    current.removeWhere((m) => m.id == medicine.id);
    // Insert at front
    current.insert(0, medicine);
    // Trim
    if (current.length > maxItems) {
      current.removeRange(maxItems, current.length);
    }
    _notifier.value = current;
  }

  void clear() {
    _notifier.value = [];
  }
}
