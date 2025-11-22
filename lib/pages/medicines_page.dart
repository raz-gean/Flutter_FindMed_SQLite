import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/medicine.dart';
import '../models/inventory_item.dart';
import '../models/pharmacy_branch.dart';
import '../services/sqlite_service.dart';
import '../services/auth_service.dart';
import 'medicine_detail_page.dart';

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});
  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  String _query = '';
  int? _branchFilter; // branch id
  bool _loading = true;
  bool _error = false;
  List<InventoryItem> _inventory = [];
  List<PharmacyBranch> _branches = [];
  Set<int> _favoriteIds = {};
  int? _userId; // current authenticated user id

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      // Capture auth before async gap to avoid context use after await
      final auth = Provider.of<AuthService>(context, listen: false);
      final inv = await SqliteService.fetchInventory();
      final branchMap = <int, PharmacyBranch>{};
      for (final item in inv) {
        branchMap[item.branch.id] = item.branch;
      }
      // Get user favorites if logged in
      final user = auth.currentUser;
      Set<int> favs = {};
      if (user != null) {
        _userId = user.id;
        final favMeds = await SqliteService.fetchFavoriteMedicines(user.id);
        favs = favMeds.map((m) => m.id).toSet();
      } else {
        _userId = null;
      }
      if (!mounted) return;
      setState(() {
        _inventory = inv;
        _branches = branchMap.values.toList()
          ..sort((a, b) => a.branchName.compareTo(b.branchName));
        _loading = false;
        _favoriteIds = favs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicines = _filteredMeds();
    final branches = _branches;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search medicines…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        SizedBox(
          height: 48,
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    ChoiceChip(
                      label: const Text('All Branches'),
                      selected: _branchFilter == null,
                      selectedColor: AppTheme.brandBlue,
                      labelStyle: TextStyle(
                        color: _branchFilter == null
                            ? Colors.white
                            : AppTheme.brandBlueDark,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _branchFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...branches.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            b.branchName.length > 18
                                ? '${b.branchName.substring(0, 18)}…'
                                : b.branchName,
                          ),
                          selected: _branchFilter == b.id,
                          selectedColor: AppTheme.brandBlue,
                          labelStyle: TextStyle(
                            color: _branchFilter == b.id
                                ? Colors.white
                                : AppTheme.brandBlueDark,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              setState(() => _branchFilter = b.id),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error && _inventory.isEmpty
              ? _ErrorRetry(onRetry: _load)
              : medicines.isEmpty
              ? const Center(child: Text('No medicines match filters'))
              : ListView.builder(
                  itemCount: medicines.length,
                  itemBuilder: (context, i) {
                    final med = medicines[i];
                    final isFav = _favoriteIds.contains(med.id);
                    return _MedicineRow(
                      medicine: med,
                      isFavorite: isFav,
                      canFavorite: _userId != null,
                      onToggleFavorite: _userId == null
                          ? null
                          : () async {
                              final toggled =
                                  await SqliteService.toggleFavorite(
                                    _userId!,
                                    med.id,
                                  );
                              setState(() {
                                if (toggled) {
                                  _favoriteIds.add(med.id);
                                } else {
                                  _favoriteIds.remove(med.id);
                                }
                              });
                            },
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Medicine> _filteredMeds() {
    final items = _inventory.map((i) => i.medicine).toList();
    final q = _query.toLowerCase();
    return items.where((m) {
      final matchesQuery =
          q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.dosage.toLowerCase().contains(q);
      final matchesBranch = _branchFilter == null || m.storeId == _branchFilter;
      return matchesQuery && matchesBranch;
    }).toList();
  }
}

class _MedicineRow extends StatelessWidget {
  final Medicine medicine;
  final bool isFavorite;
  final bool canFavorite;
  final VoidCallback? onToggleFavorite;
  const _MedicineRow({
    required this.medicine,
    required this.isFavorite,
    required this.canFavorite,
    required this.onToggleFavorite,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineDetailPage(medicine: medicine),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.medication_outlined, color: AppTheme.brandBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medicine.dosage.isEmpty ? 'No details' : medicine.dosage} • ${medicine.branchName ?? 'Branch'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${medicine.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandBlueDark,
                    ),
                  ),
                  Text(
                    'Stock: ${medicine.stock}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: canFavorite
                    ? (isFavorite ? 'Remove favorite' : 'Save favorite')
                    : 'Login to favorite',
                onPressed: canFavorite ? onToggleFavorite : null,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Failed to load live data'),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
