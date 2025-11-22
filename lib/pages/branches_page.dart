import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pharmacy_branch.dart';
import '../services/sqlite_service.dart';
import '../widgets/company_logo.dart';
import 'branch_detail_page.dart';

class BranchesPage extends StatefulWidget {
  final String companyName;
  final List<PharmacyBranch> branches; // initial snapshot
  const BranchesPage({
    super.key,
    required this.companyName,
    required this.branches,
  });
  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  late List<PharmacyBranch> _displayBranches;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _displayBranches = widget.branches;
    _refresh(force: true); // get latest immediately
  }

  Future<void> _refresh({bool force = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final all = await SqliteService.fetchBranches();
      final filtered =
          all.where((b) => b.company.name == widget.companyName).toList()
            ..sort((a, b) => a.branchName.compareTo(b.branchName));
      if (!mounted) return;
      setState(() {
        _displayBranches = filtered;
        _loading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading && _displayBranches.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error && _displayBranches.isEmpty
            ? _ErrorBox(onRetry: _refresh)
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: _displayBranches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final branch = _displayBranches[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BranchDetailPage(branch: branch),
                        ),
                      ).then((_) => _refresh()),
                      leading: CompanyLogo(
                        companyName: branch.company.name,
                        size: 48,
                      ),
                      title: Text(
                        branch.branchName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.brandBlueDark.withValues(
                              alpha: 0.85,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              branch.branchAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.call,
                            size: 16,
                            color: AppTheme.brandBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            branch.phoneNumber ?? 'N/A',
                            style: const TextStyle(
                              color: AppTheme.brandBlueDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorBox({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Failed to load branches'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
