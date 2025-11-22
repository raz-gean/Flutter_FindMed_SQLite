import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'medicines_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import '../auth/login_page.dart';
import '../auth/signup_page.dart';
import 'branches_page.dart';
import '../models/pharmacy_branch.dart';
import '../services/sqlite_service.dart';
import 'notes_page.dart';
import 'manager_dashboard.dart';
import 'admin_dashboard.dart';
import '../widgets/findmed_logo.dart';
import '../widgets/company_logo.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const FindMedLogo(size: 34),
            const SizedBox(width: 10),
            const Text(
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
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('Sign Up'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const SignupPage()));
                },
              ),
              const Divider(),
              // Panel button - only for managers and admins
              Consumer<AuthService>(
                builder: (context, authService, _) {
                  final isManagerOrAdmin =
                      authService.isManager || authService.isAdmin;

                  if (!isManagerOrAdmin) {
                    return const SizedBox.shrink(); // Hide for customers
                  }

                  // For managers, we need to check if they have an assigned branch
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
                            onTap: null,
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

                  // Admin panel - always available
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
    return FutureBuilder<List<PharmacyBranch>>(
      future: SqliteService.fetchBranches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load branches'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final data = snapshot.data ?? [];
        final grouped = <String, List<PharmacyBranch>>{};
        for (final b in data) {
          grouped.putIfAbsent(b.company.name, () => []).add(b);
        }
        final chains = grouped.keys.toList()..sort();
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

// Legacy _buildLogo function removed in favor of reusable CompanyLogo widget.
