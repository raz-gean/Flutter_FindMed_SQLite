import 'package:flutter/material.dart';
import '../models/pharmacy_branch.dart';
import '../models/inventory_item.dart';
import '../models/medicine.dart';
import '../services/sqlite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/findmed_logo.dart';
import '../widgets/company_logo.dart';
import '../constants/company_descriptions.dart';

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

  void _showCompanyInfo() {
    final name = widget.branch.company.name;
    final desc = companyDescription(name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text(desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: Row(
          children: const [
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? _ErrorRetry(onRetry: _load)
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              itemCount: 2 + meds.length + (meds.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // 0 -> header card, 1 -> search field, 2 -> empty message (if meds empty) else first medicine
                if (index == 0) return _buildHeaderCard();
                if (index == 1) return _buildSearchField();
                if (meds.isEmpty && index == 2) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No medicines found for this branch'),
                    ),
                  );
                }
                final med = meds[index - 2];
                return _MedicineTile(medicine: med);
              },
            ),
    );
  }

  Widget _buildSearchField() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search medicines in this branch…',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      onChanged: (v) => setState(() => _query = v.trim()),
    ),
  );

  Widget _buildHeaderCard() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CompanyLogo(companyName: widget.branch.company.name, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.branch.company.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandBlueDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kCompanyDescriptions[widget.branch.company.name] ??
                  'Pharmacy info unavailable.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Text(
                    'Branch: ${widget.branch.branchName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandBlueDark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCompanyInfo,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Learn more'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppTheme.brandBlueDark,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.branch.branchAddress,
                    style: const TextStyle(fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (widget.branch.phoneNumber != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.call,
                    size: 14,
                    color: AppTheme.brandBlueDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.branch.phoneNumber!,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
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
