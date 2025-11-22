import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/inventory_item.dart';
import '../models/pharmacy_branch.dart';
import '../services/sqlite_service.dart';
import '../theme/app_theme.dart';
import 'branch_detail_page.dart';
import '../widgets/company_logo.dart';
import '../services/recently_viewed_service.dart';
import '../widgets/findmed_logo.dart';

class MedicineDetailPage extends StatefulWidget {
  final Medicine medicine;
  const MedicineDetailPage({super.key, required this.medicine});
  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  bool _loading = true;
  bool _error = false;
  List<InventoryItem> _inventory = [];
  int? _userId;
  bool _favLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Record this medicine as recently viewed
    RecentlyViewedService.instance.add(widget.medicine);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
      _favLoading = true;
    });
    try {
      final inv = await SqliteService.fetchInventory();
      final uid = await SqliteService.ensureUser('demo@gmail.com', 'Customer');
      final fav = await SqliteService.isFavorite(uid, widget.medicine.id);
      setState(() {
        _inventory = inv
            .where((i) => i.medicine.id == widget.medicine.id)
            .toList();
        _userId = uid;
        _isFavorite = fav;
        _loading = false;
        _favLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
        _favLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userId == null) return;
    setState(() => _favLoading = true);
    final newState = await SqliteService.toggleFavorite(
      _userId!,
      widget.medicine.id,
    );
    if (!mounted) return;
    setState(() {
      _isFavorite = newState;
      _favLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branches = _inventory.map((i) => i.branch).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            FindMedLogo(size: 34),
            SizedBox(width: 10),
            Text(
              'FindMed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (_favLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.redAccent : Colors.grey,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _MedicineHeader(medicine: widget.medicine),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                ? _ErrorRetry(onRetry: _load)
                : branches.isEmpty
                ? const Center(
                    child: Text('No branch currently stocks this medicine'),
                  )
                : ListView.builder(
                    itemCount: branches.length,
                    itemBuilder: (context, i) => _BranchTile(
                      branch: branches[i],
                      inventory: _inventory.firstWhere(
                        (inv) => inv.branch.id == branches[i].id,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MedicineHeader extends StatelessWidget {
  final Medicine medicine;
  const _MedicineHeader({required this.medicine});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medicine.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              medicine.dosage.isEmpty ? 'No dosage info' : medicine.dosage,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 16,
                  color: AppTheme.brandBlueDark,
                ),
                const SizedBox(width: 4),
                Text('₱${medicine.price.toStringAsFixed(2)}'),
                const SizedBox(width: 12),
                const Icon(
                  Icons.inventory_2,
                  size: 16,
                  color: AppTheme.brandBlueDark,
                ),
                const SizedBox(width: 4),
                Text('Stock: ${medicine.stock}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final PharmacyBranch branch;
  final InventoryItem inventory;
  const _BranchTile({required this.branch, required this.inventory});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CompanyLogo(companyName: branch.company.name, size: 48),
        title: Text(
          branch.branchName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          branch.branchAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₱${inventory.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.brandBlueDark,
              ),
            ),
            Text('Stock: ${inventory.stock}'),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BranchDetailPage(branch: branch)),
          );
        },
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
        const Text('Failed to load inventory'),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
