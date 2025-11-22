import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'medicines_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import '../auth/login_page.dart';
import 'branches_page.dart';
import '../models/pharmacy_branch.dart';
import '../services/sqlite_service.dart';
import 'notes_page.dart';
import 'manager_dashboard.dart';
import 'admin_dashboard.dart';
import '../widgets/findmed_logo.dart';
import '../widgets/company_logo.dart';
import '../services/recently_viewed_service.dart';
import '../models/medicine.dart';
import 'medicine_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  // Recreate pages except index 0 dynamically so that Chains can refresh
  final List<Widget> _pages = [
    const SizedBox(), // placeholder, index 0 handled separately
    const MedicinesPage(),
    const ProfilePage(),
    const SettingsPage(),
  ];

  // Company logos are now provided by CompanyLogo widget mapping.
  bool _hideTip = false;
  static const List<String> _healthTips = [
    'Stay hydrated: drink water regularly throughout the day.',
    'Store medicines in a cool, dry place away from sunlight.',
    'Always check expiry dates before taking any medication.',
    'Consult a pharmacist when combining over-the-counter drugs.',
    'Finish antibiotic courses unless instructed otherwise.',
  ];

  Future<Map<String, dynamic>> _loadHomeMetrics() async {
    final branches = await SqliteService.fetchBranches();
    final inventory = await SqliteService.fetchInventory();
    final uniqueMedIds = <int>{};
    for (final item in inventory) {
      uniqueMedIds.add(item.medicine.id);
    }
    return {
      'branches': branches,
      'medicineCount': uniqueMedIds.length,
      'inventoryItems': inventory.length,
    };
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
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppTheme.brandBlue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FindMedLogo(size: 60),
                    const SizedBox(height: 12),
                    const Text(
                      'FindMed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your medicine & branch companion',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick Access label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Browse Pharmacies'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _index = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: const Text('Medicines'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _index = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Favorites'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _index = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_outlined),
                title: const Text('Notes'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const NotesPage()));
                },
              ),
              ValueListenableBuilder<List<Medicine>>(
                valueListenable: RecentlyViewedService.instance.listenable,
                builder: (context, viewed, _) {
                  if (viewed.isEmpty) return const SizedBox.shrink();
                  return ExpansionTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Recently Viewed'),
                    children: [
                      ...viewed.map(
                        (m) => ListTile(
                          dense: true,
                          title: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            m.dosage.isEmpty ? 'No dosage' : m.dosage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MedicineDetailPage(medicine: m),
                              ),
                            );
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.clear, size: 18),
                        title: const Text(
                          'Clear list',
                          style: TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          RecentlyViewedService.instance.clear();
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              Consumer<AuthService>(
                builder: (context, authService, _) {
                  final isManagerOrAdmin =
                      authService.isManager || authService.isAdmin;
                  if (!isManagerOrAdmin) {
                    return const SizedBox.shrink();
                  }
                  if (authService.isManager) {
                    return FutureBuilder<bool>(
                      future: authService.hasAssignedBranch(),
                      builder: (context, snapshot) {
                        final hasAssignedBranch = snapshot.data ?? false;
                        if (!hasAssignedBranch) {
                          return ListTile(
                            leading: const Icon(
                              Icons.dashboard,
                              color: Colors.grey,
                            ),
                            title: const Text(
                              'Manager Panel',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Waiting for admin assignment',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            enabled: false,
                          );
                        }
                        return ListTile(
                          leading: const Icon(
                            Icons.dashboard,
                            color: AppTheme.brandBlue,
                          ),
                          title: const Text(
                            'Manager Panel',
                            style: TextStyle(
                              color: AppTheme.brandBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ManagerDashboard(),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: AppTheme.brandBlue,
                    ),
                    title: const Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: AppTheme.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboard(),
                        ),
                      );
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(_hideTip ? 'Show Health Tip' : 'Hide Health Tip'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _hideTip = !_hideTip);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About & Coming Soon'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAboutDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: _index == 0 ? _buildChainsWithHero() : _pages[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.brandBlue.withValues(alpha: 0.15),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppTheme.brandBlue),
            label: 'Chains',
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
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.brandBlue),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildChainsWithHero() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadHomeMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load data'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final map = snapshot.data ?? {};
        final branches = (map['branches'] as List<PharmacyBranch>?) ?? [];
        final grouped = <String, List<PharmacyBranch>>{};
        for (final b in branches) {
          grouped.putIfAbsent(b.company.name, () => []).add(b);
        }
        final chains = grouped.keys.toList()..sort();
        final medicineCount = map['medicineCount'] as int? ?? 0;
        final inventoryItems = map['inventoryItems'] as int? ?? 0;
        final tip = _healthTips[DateTime.now().day % _healthTips.length];
        return ListView(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/imgs/medicinebackground.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppTheme.brandBlueDark.withValues(alpha: 0.55),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to FindMed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Find medicines and check availability across your nearest pharmacy branches.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Browse Pharmacies'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Availability summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Availability Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.brandBlueDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tracking $medicineCount medicines across ${branches.length} branches.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Inventory entries: $inventoryItems',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.analytics_outlined,
                        color: AppTheme.brandBlue,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Health tip card (dismissible)
            if (!_hideTip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Dismissible(
                  key: const ValueKey('healthTip'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => setState(() => _hideTip = true),
                  child: Card(
                    color: Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.green.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.health_and_safety,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Health Tip',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tip,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Swipe to dismiss',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!_hideTip)
              const SizedBox(height: 16)
            else
              const SizedBox(height: 4),
            // Recently Viewed Section
            ValueListenableBuilder<List<Medicine>>(
              valueListenable: RecentlyViewedService.instance.listenable,
              builder: (context, viewed, _) {
                if (viewed.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Recently Viewed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: viewed.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final med = viewed[i];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MedicineDetailPage(medicine: med),
                                ),
                              );
                            },
                            child: Container(
                              width: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brandBlueDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    med.dosage.isEmpty
                                        ? 'No dosage'
                                        : med.dosage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₱${med.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brandBlueDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stock: ${med.stock}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Pharmacies',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: chains.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chain = chains[index];
                final branches = grouped[chain]!;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BranchesPage(
                            companyName: chain,
                            branches: branches,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CompanyLogo(companyName: chain, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chain,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${branches.length} branches',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: AppTheme.brandBlue.withValues(alpha: 0.12),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandBlueDark.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Save favorite medicines or check your notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandBlueDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _index = 2);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border.all(
                                    color: AppTheme.brandBlue.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                child: Column(
                                  children: const [
                                    Icon(
                                      Icons.favorite_border,
                                      size: 28,
                                      color: Color(0xFFE53935),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Favorites',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.brandBlueDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border.all(
                                    color: AppTheme.brandBlue.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                child: Column(
                                  children: const [
                                    Icon(
                                      Icons.note_outlined,
                                      size: 28,
                                      color: Color(0xFFFFA726),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Notes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.brandBlueDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Future-ready hooks placeholder
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.brandBlue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.brandBlue.withValues(alpha: 0.15),
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.upcoming,
                              color: AppTheme.brandBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Coming Soon',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.brandBlueDark,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '• Order reminders & refill alerts\n• Nearest branch detection\n• Smart price comparisons\nStay tuned for updates!',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: Text(
                  '@ 2025 FindMed • Health environment - By Group nila Raz',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // Legacy _buildLogo function removed in favor of reusable CompanyLogo widget.

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FindMed'),
        content: const Text(
          'FindMed is a demo application showcasing branch availability, medicine browsing, and upcoming features like reminders and smart comparisons.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
