import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pharmacy_branch.dart';
import '../widgets/async_widgets.dart';
import '../services/sqlite_service.dart';
import 'branches_page.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});
  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  bool _loading = true;
  bool _error = false;
  List<PharmacyBranch> _branches = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when navigating back to this page
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final branches = await SqliteService.fetchBranches();
      setState(() {
        _branches = branches;
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
    return AsyncStateSwitcher(
      loading: _loading,
      error: _error,
      onRetry: _fetch,
      loadingMessage: 'Loading pharmacy chains…',
      errorMessage: 'Failed to load chains',
      child: _buildList(),
    );
  }

  Widget _buildList() {
    final grouped = <String, List<PharmacyBranch>>{};
    for (final b in _branches) {
      grouped.putIfAbsent(b.company.name, () => []).add(b);
    }
    final chains = grouped.keys.toList()..sort();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: chains.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chain = chains[index];
        final branches = grouped[chain]!;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.12),
              child: const Icon(
                Icons.local_pharmacy,
                color: AppTheme.brandBlue,
              ),
            ),
            title: Text(
              chain,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${branches.length} branches'),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.brandBlue,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    BranchesPage(companyName: chain, branches: branches),
              ),
            ),
          ),
        );
      },
    );
  }
}
