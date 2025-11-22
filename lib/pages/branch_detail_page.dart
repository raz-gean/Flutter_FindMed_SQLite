import 'package:flutter/material.dart';
import '../models/pharmacy_branch.dart';
import '../models/inventory_item.dart';
import '../models/medicine.dart';
import '../services/sqlite_service.dart';
import '../theme/app_theme.dart';

class BranchDetailPage extends StatefulWidget {
  final PharmacyBranch branch;
  const BranchDetailPage({super.key, required this.branch});
  @override
  State<BranchDetailPage> createState() => _BranchDetailPageState();
}

class _BranchDetailPageState extends State<BranchDetailPage> {
  bool _loading = true;
  bool _error = false;
  List<InventoryItem> _inventory = [];
  String _query = '';

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
      final inv = await SqliteService.fetchInventory();
      setState(() {
        _inventory = inv.where((i) => i.branch.id == widget.branch.id).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = _inventory.map((i) => i.medicine).where((m) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.dosage.toLowerCase().contains(q);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.branch.branchName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search medicines in branch…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _BranchInfo(branch: widget.branch),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                ? _ErrorRetry(onRetry: _load)
                : meds.isEmpty
                ? const Center(
                    child: Text('No medicines found for this branch'),
                  )
                : ListView.builder(
                    itemCount: meds.length,
                    itemBuilder: (context, i) =>
                        _MedicineTile(medicine: meds[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BranchInfo extends StatelessWidget {
  final PharmacyBranch branch;
  const _BranchInfo({required this.branch});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch.company.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(branch.branchAddress, style: const TextStyle(fontSize: 12)),
            if (branch.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.call,
                    size: 14,
                    color: AppTheme.brandBlueDark,
                  ),
                  const SizedBox(width: 4),
                  Text(branch.phoneNumber!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  final Medicine medicine;
  const _MedicineTile({required this.medicine});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(
          Icons.medication_outlined,
          color: AppTheme.brandBlue,
        ),
        title: Text(medicine.name),
        subtitle: Text(
          medicine.dosage.isEmpty ? 'No details' : medicine.dosage,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₱${medicine.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.brandBlueDark,
              ),
            ),
            Text('Stock: ${medicine.stock}'),
          ],
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
        const Text('Failed to load inventory'),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
