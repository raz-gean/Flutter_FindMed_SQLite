import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../models/medicine.dart';
import '../models/pharmacy_branch.dart';
import '../auth/login_page.dart';
import '../widgets/findmed_logo.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  // Bottom nav: 0 = Dashboard, 1 = Medicines, 2 = Profile
  int _selectedTabIndex = 0;
  List<Medicine> _medicines = [];
  bool _isLoading = true;
  int? _userBranchId;
  PharmacyBranch? _currentBranch; // Active branch this manager handles

  @override
  void initState() {
    super.initState();
    _loadManagerData();
  }

  Future<void> _loadManagerData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) return;

      // Get manager's branch
      final branches = await DatabaseHelper.instance.getManagerBranches(
        user.id,
      );
      if (!mounted) return; // Async context safety
      if (branches.isNotEmpty) {
        _currentBranch = branches.first; // Take first assigned branch for now
        _userBranchId = _currentBranch!.id;
        _loadMedicines();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> _loadMedicines() async {
    if (_userBranchId == null) return;

    setState(() => _isLoading = true);
    try {
      final medicines = await DatabaseHelper.instance.getMedicinesForBranch(
        _userBranchId!,
      );
      if (!mounted) return;
      setState(() {
        _medicines = medicines;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading medicines: $e')));
    }
  }

  void _showAddMedicineDialog() {
    showDialog(
      context: context,
      builder: (_) => _MedicineFormDialog(
        title: 'Add Medicine',
        onSave: (name, genericName, description, stock, price) async {
          try {
            final authService = Provider.of<AuthService>(
              context,
              listen: false,
            );
            final user = authService.currentUser!;

            if (_userBranchId == null) {
              throw Exception('No branch assigned');
            }

            await DatabaseHelper.instance.addMedicine(
              name: name,
              genericName: genericName,
              description: description,
              managerId: user.id,
              branchId: _userBranchId!,
              initialStock: stock,
              initialPrice: price,
            );
            await _loadMedicines();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medicine added successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  void _showEditMedicineDialog(Medicine medicine) {
    showDialog(
      context: context,
      builder: (_) => _MedicineFormDialog(
        title: 'Edit Medicine',
        initialName: medicine.name,
        initialGenericName: medicine.genericName,
        initialDescription: medicine.description,
        initialStock: medicine.stock,
        initialPrice: medicine.price,
        onSave: (name, genericName, description, stock, price) async {
          try {
            final authService = Provider.of<AuthService>(
              context,
              listen: false,
            );
            final user = authService.currentUser!;

            if (_userBranchId == null) {
              throw Exception('No branch assigned');
            }

            await DatabaseHelper.instance.updateMedicine(
              medicineId: medicine.id,
              name: name,
              genericName: genericName,
              description: description,
              managerId: user.id,
              branchId: _userBranchId!,
            );
            // Update inventory stock / price
            await DatabaseHelper.instance.updateMedicineInventory(
              medicineId: medicine.id,
              branchId: _userBranchId!,
              managerId: user.id,
              newStock: stock,
              newPrice: price,
            );
            await _loadMedicines();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medicine updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Medicine medicine) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                final user = authService.currentUser!;

                if (_userBranchId == null) {
                  throw Exception('No branch assigned');
                }

                await DatabaseHelper.instance.deleteMedicine(
                  medicine.id,
                  user.id,
                  _userBranchId!,
                );
                await _loadMedicines();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medicine deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const FindMedLogo(size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager • ${user?.displayName ?? 'Account'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (_currentBranch != null)
                        Text(
                          _currentBranch!.branchName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade200,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
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
          body: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildDashboard(user),
              _buildMedicinesTab(),
              _buildProfileTab(user),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (i) => setState(() => _selectedTabIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppTheme.brandBlue),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication, color: AppTheme.brandBlue),
                label: 'Medicines',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppTheme.brandBlue),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboard(AppUser? user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.brandBlue, AppTheme.brandBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.displayName ?? 'Manager',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              if (_currentBranch != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Branch: ${_currentBranch!.branchName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _currentBranch!.company.name,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Medicines',
                _medicines.length.toString(),
                Icons.medication,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'In Stock',
                _medicines.where((m) => m.stock > 0).length.toString(),
                Icons.inventory,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Quick Actions
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.brandBlueDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildActionCard(
                'Add Medicine',
                Icons.add_circle_outline,
                AppTheme.brandBlue,
                () => _showAddMedicineDialog(),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                'View All',
                Icons.list,
                Colors.orange,
                () => setState(() => _selectedTabIndex = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Recent Medicines
        const Text(
          'Recent Medicines',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.brandBlueDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_medicines.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No medicines yet. Add one to get started!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._medicines.take(3).map((medicine) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(medicine.name),
                subtitle: Text('${medicine.dosage} • Stock: ${medicine.stock}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditMedicineDialog(medicine),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMedicinesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showAddMedicineDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add New Medicine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No medicines added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _medicines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final medicine = _medicines[index];
                    return Card(
                      child: InkWell(
                        onTap: () => _showEditMedicineDialog(medicine),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          medicine.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          medicine.dosage,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: AppTheme.brandBlue,
                                        ),
                                        onPressed: () =>
                                            _showEditMedicineDialog(medicine),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _showDeleteConfirmation(medicine),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Price: ₱${medicine.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brandBlue,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: medicine.stock > 0
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Stock: ${medicine.stock}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: medicine.stock > 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProfileTab(AppUser? user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandBlueDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileField('Name', user?.displayName ?? 'N/A'),
                _buildProfileField('Email', user?.email ?? 'N/A'),
                _buildProfileField('Role', user?.role.displayName ?? 'N/A'),
                _buildProfileField(
                  'Member Since',
                  user?.createdAt.toString().split(' ')[0] ?? 'N/A',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await Provider.of<AuthService>(context, listen: false).logout();
            if (!mounted) return;
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.brandBlueDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineFormDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String? initialGenericName;
  final String? initialDescription;
  final int? initialStock;
  final double? initialPrice;
  final Function(String, String, String, int, double) onSave;

  const _MedicineFormDialog({
    required this.title,
    required this.onSave,
    this.initialName,
    this.initialGenericName,
    this.initialDescription,
    this.initialStock,
    this.initialPrice,
  });

  @override
  State<_MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<_MedicineFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _genericNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _genericNameController = TextEditingController(
      text: widget.initialGenericName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _stockController = TextEditingController(
      text: widget.initialStock?.toString() ?? '0',
    );
    _priceController = TextEditingController(
      text: widget.initialPrice?.toStringAsFixed(2) ?? '0.00',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine name is required')),
      );
      return;
    }

    // Parse & validate stock
    final stockRaw = _stockController.text.trim();
    final priceRaw = _priceController.text.trim();
    int stock;
    double price;
    try {
      stock = int.parse(stockRaw);
      if (stock < 0) stock = 0; // Prevent negative
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid stock value')));
      return;
    }
    try {
      price = double.parse(priceRaw);
      if (price < 0) price = 0.0; // Prevent negative
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid price value')));
      return;
    }

    try {
      widget.onSave(
        _nameController.text.trim(),
        _genericNameController.text.trim(),
        _descriptionController.text.trim(),
        stock,
        price,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genericNameController,
              decoration: const InputDecoration(
                labelText: 'Generic Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock (integer)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price (₱)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandBlue),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
