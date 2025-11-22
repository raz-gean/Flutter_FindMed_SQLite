import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pharmacy_branch.dart';
import '../services/sqlite_service.dart';
import '../widgets/company_logo.dart';
import '../widgets/findmed_logo.dart';
import '../constants/company_descriptions.dart';
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

  void _showCompanyInfo(String name) {
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
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: _displayBranches.length + 1, // +1 for intro section
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final desc =
                        kCompanyDescriptions[widget.companyName] ??
                        'Pharmacy chain information unavailable.';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CompanyLogo(
                                      companyName: widget.companyName,
                                      size: 60,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        widget.companyName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.brandBlueDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 13,
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
                                        color: AppTheme.brandBlue.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        'Showing ${_displayBranches.length} branch${_displayBranches.length == 1 ? '' : 'es'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.brandBlueDark,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _showCompanyInfo(widget.companyName),
                                      icon: const Icon(
                                        Icons.info_outline,
                                        size: 16,
                                      ),
                                      label: const Text('Learn more'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Text(
                            'Branches',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandBlue,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  final branch = _displayBranches[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
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

// Descriptions centralized in constants/company_descriptions.dart
