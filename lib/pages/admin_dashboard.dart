import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../auth/login_page.dart';
import 'home.dart';
import '../widgets/findmed_logo.dart';
import 'edit_branch_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Bottom nav: 0 = Managers, 1 = Create Branch, 2 = Manage Branches
  int _selectedTabIndex = 0;
  bool _isLoading = true;

  // Data
  List<AppUser> _unassignedManagers = [];
  List<Map<String, dynamic>> _managersWithBranches = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _companies = [];

  // Pagination
  static const int pageSize = 10;
  int _managerOffset = 0;
  int _branchOffset = 0;
  int _managerTotal = 0;
  int _branchTotal = 0;
  bool _loadingMoreManagers = false;
  bool _loadingMoreBranches = false;

  // Create branch form
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  int? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    _loadAdminData(reset: true);
  }

  Future<void> _loadAdminData({bool reset = false}) async {
    if (reset) {
      _managerOffset = 0;
      _branchOffset = 0;
      _managersWithBranches.clear();
      _branches.clear();
    }
    setState(() => _isLoading = true);
    try {
      _companies = await DatabaseHelper.instance.getAllCompanies();
      _managerTotal = await DatabaseHelper.instance.getManagersCount();
      _branchTotal = await DatabaseHelper.instance.getBranchesCount();

      final firstManagers = await DatabaseHelper.instance
          .getManagersWithBranchesPaged(
            limit: pageSize,
            offset: _managerOffset,
          );
      final firstBranches = await DatabaseHelper.instance.getBranchesPaged(
        limit: pageSize,
        offset: _branchOffset,
      );
      _unassignedManagers = await DatabaseHelper.instance
          .getUnassignedManagers();

      if (!mounted) return;
      setState(() {
        _managersWithBranches = firstManagers;
        _branches = firstBranches;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _loadMoreManagers() async {
    if (_loadingMoreManagers) return;
    if (_managersWithBranches.length >= _managerTotal) return;
    setState(() => _loadingMoreManagers = true);
    _managerOffset += pageSize;
    final more = await DatabaseHelper.instance.getManagersWithBranchesPaged(
      limit: pageSize,
      offset: _managerOffset,
    );
    if (!mounted) return;
    setState(() {
      _managersWithBranches.addAll(more);
      _loadingMoreManagers = false;
    });
  }

  Future<void> _loadMoreBranches() async {
    if (_loadingMoreBranches) return;
    if (_branches.length >= _branchTotal) return;
    setState(() => _loadingMoreBranches = true);
    _branchOffset += pageSize;
    final more = await DatabaseHelper.instance.getBranchesPaged(
      limit: pageSize,
      offset: _branchOffset,
    );
    if (!mounted) return;
    setState(() {
      _branches.addAll(more);
      _loadingMoreBranches = false;
    });
  }

  void _showAssignManagerDialog(AppUser manager) {
    String? selectedBranchId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Manager: ${manager.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a branch:'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Choose branch...'),
                value: selectedBranchId,
                items: _branches
                    .map(
                      (branch) => DropdownMenuItem(
                        value: branch['id'].toString(),
                        child: Text(branch['branch_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedBranchId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedBranchId == null
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await DatabaseHelper.instance
                          .assignManagerToBranchAdmin(
                            manager.id,
                            int.parse(selectedBranchId!),
                          );
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Manager assigned successfully'
                                : 'Failed to assign manager',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) _loadAdminData();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
              ),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReassignManagerDialog(Map<String, dynamic> managerData) {
    final managerId = managerData['id'] as int;
    final managerName = managerData['display_name'] as String;
    String? selectedBranchId = managerData['branch_id']?.toString();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reassign Manager: $managerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new branch:'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedBranchId,
                items: _branches
                    .map(
                      (branch) => DropdownMenuItem(
                        value: branch['id'].toString(),
                        child: Text(branch['branch_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedBranchId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedBranchId == null
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await DatabaseHelper.instance
                          .reassignManagerToBranch(
                            managerId,
                            int.parse(selectedBranchId!),
                          );
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Manager reassigned successfully'
                                : 'Failed to reassign manager',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) _loadAdminData();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
              ),
              child: const Text('Reassign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBranch() async {
    if (_branchNameController.text.isEmpty ||
        _branchAddressController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await DatabaseHelper.instance.createBranchAdmin(
      companyId: _selectedCompanyId!,
      branchName: _branchNameController.text,
      branchAddress: _branchAddressController.text,
      phoneNumber: _phoneNumberController.text,
    );

    if (mounted) {
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _branchNameController.clear();
        _branchAddressController.clear();
        _phoneNumberController.clear();
        setState(() => _selectedCompanyId = null);
        _loadAdminData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create branch'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
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
                tooltip: 'Home',
                icon: const Icon(Icons.home_outlined),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await authService.logout();
                  if (!mounted) return;
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    adminBodyHeader(user: user, currentTab: _selectedTabIndex),
                    const Divider(height: 1),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTabIndex,
                        children: [
                          _buildManagersMergedTab(),
                          _buildCreateBranchTab(),
                          _buildManageBranchesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (i) => setState(() => _selectedTabIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.supervisor_account_outlined),
                selectedIcon: Icon(
                  Icons.supervisor_account,
                  color: AppTheme.brandBlue,
                ),
                label: 'Managers',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_business_outlined),
                selectedIcon: Icon(
                  Icons.add_business,
                  color: AppTheme.brandBlue,
                ),
                label: 'Create',
              ),
              NavigationDestination(
                icon: Icon(Icons.store_mall_directory_outlined),
                selectedIcon: Icon(
                  Icons.store_mall_directory,
                  color: AppTheme.brandBlue,
                ),
                label: 'Branches',
              ),
            ],
          ),
        );
      },
    );
  }

  String _tabTitle(int index) {
    switch (index) {
      case 0:
        return 'Managers Overview';
      case 1:
        return 'Create Branch';
      case 2:
        return 'Manage Branches';
      default:
        return '';
    }
  }

  Widget _adminMetaChip(String label, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    decoration: BoxDecoration(
      color: (color ?? AppTheme.brandBlue).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: (color ?? AppTheme.brandBlue).withValues(alpha: 0.25),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? AppTheme.brandBlueDark,
      ),
    ),
  );

  Widget adminBodyHeader({required AppUser? user, required int currentTab}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandBlueDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (user != null) _adminMetaChip('User: ${user.displayName}'),
              _adminMetaChip(_tabTitle(currentTab)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage pharmacy managers, create branches, and maintain branch records.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateBranchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Branch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandBlueDark,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Company dropdown
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      border: OutlineInputBorder(),
                    ),
                    // Flutter latest prefers FormField.initialValue over deprecated value
                    initialValue: _selectedCompanyId,
                    items: _companies
                        .map(
                          (company) => DropdownMenuItem(
                            value: company['id'] as int,
                            child: Text(company['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCompanyId = value),
                  ),
                  const SizedBox(height: 16),

                  // Branch name
                  TextField(
                    controller: _branchNameController,
                    decoration: const InputDecoration(
                      labelText: 'Branch Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Downtown Branch',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Branch address
                  TextField(
                    controller: _branchAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Branch Address',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 123 Main St, City',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Phone number
                  TextField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., +1 (555) 123-4567',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createBranch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Create Branch',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to dedicated edit branch page
  void _navigateEditBranch(Map<String, dynamic> branch) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditBranchPage(branch: branch, companies: _companies),
      ),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch updated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAdminData();
    }
  }

  Future<void> _deleteBranch(int branchId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Branch'),
        content: const Text(
          'This will remove the branch and its inventory. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await DatabaseHelper.instance.deleteBranchAdmin(branchId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Branch deleted' : 'Failed to delete branch'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) _loadAdminData();
    }
  }

  Widget _buildManageBranchesTab() {
    // Map company id to name for quick lookup
    final companyNameById = {
      for (final c in _companies) c['id'] as int: c['name'] as String,
    };
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Branches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandBlueDark,
                ),
              ),
              Text(
                '${_branches.length}/$_branchTotal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_branches.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No branches found. Create one to get started.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._branches.map((b) {
              final companyName = companyNameById[b['company_id']] ?? 'Company';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.store, color: AppTheme.brandBlue),
                  title: Text(b['branch_name'] as String? ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companyName, style: const TextStyle(fontSize: 12)),
                      Text(
                        (b['branch_address'] as String? ?? '').trim(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if ((b['phone_number'] as String? ?? '').isNotEmpty)
                        Text(
                          b['phone_number'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: AppTheme.brandBlue),
                        onPressed: () => _navigateEditBranch(b),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBranch(b['id'] as int),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (_branches.length < _branchTotal)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _loadingMoreBranches
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _loadMoreBranches,
                        icon: const Icon(Icons.more_horiz),
                        label: const Text('Load More'),
                      ),
              ),
            ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Total branches: ${_branches.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagersMergedTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAdminData(reset: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Managers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandBlueDark,
                ),
              ),
              Text(
                '${_managersWithBranches.length}/$_managerTotal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_unassignedManagers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unassigned Managers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._unassignedManagers.map(
                    (m) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: AppTheme.brandBlue,
                        ),
                        title: Text(m.displayName),
                        subtitle: Text(m.email),
                        trailing: ElevatedButton(
                          onPressed: () => _showAssignManagerDialog(m),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandBlue,
                          ),
                          child: const Text('Assign'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Assigned / All Managers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandBlueDark,
            ),
          ),
          const SizedBox(height: 8),
          if (_managersWithBranches.isEmpty)
            _emptyBox('No managers found')
          else
            ..._managersWithBranches.map((managerData) {
              final branchName = managerData['branch_name'] ?? 'Not Assigned';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.store, color: AppTheme.brandBlue),
                  title: Text(managerData['display_name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        managerData['email'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Branch: $branchName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.brandBlue),
                    onPressed: () => _showReassignManagerDialog(managerData),
                  ),
                ),
              );
            }),
          if (_managersWithBranches.length < _managerTotal)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _loadingMoreManagers
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _loadMoreManagers,
                        icon: const Icon(Icons.more_horiz),
                        label: const Text('Load More'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyBox(String msg) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      msg,
      style: const TextStyle(color: Colors.grey),
      textAlign: TextAlign.center,
    ),
  );

  @override
  void dispose() {
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}
