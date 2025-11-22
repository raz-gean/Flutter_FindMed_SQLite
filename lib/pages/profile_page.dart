import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notes_page.dart';
import '../services/sqlite_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/medicine.dart';
import '../widgets/findmed_logo.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? _userId;
  bool _favoritesLoading = true;
  List<Medicine> _favorites = [];
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final current = auth.currentUser;
    if (current == null) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _favoritesLoading = false;
      });
      return;
    }
    final favs = await SqliteService.fetchFavoriteMedicines(current.id);
    if (!mounted) return;
    setState(() {
      _user = current;
      _userId = current.id;
      _favorites = favs;
      _favoritesLoading = false;
    });
  }

  Future<void> _refreshFavorites() async {
    if (_userId == null) return;
    final favs = await SqliteService.fetchFavoriteMedicines(_userId!);
    if (!mounted) return;
    setState(() => _favorites = favs);
  }

  @override
  Widget build(BuildContext context) {
    if (_favoritesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Please log in to view your profile',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshFavorites,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.displayName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user!.email,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          _user!.role.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.note_outlined,
                    color: Color(0xFFFFA726),
                  ),
                  title: const Text(
                    'Shopping Notes',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Keep track of what to buy',
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const NotesPage())),
                ),
                Divider(color: Colors.grey.shade300, height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Color(0xFFE53935)),
                  title: const Text(
                    'Favorites',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _favorites.isEmpty
                        ? 'No favorites yet'
                        : '${_favorites.length} saved medicines',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _userId == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _FavoritesPage(
                              userId: _userId!,
                              initialFavorites: _favorites,
                              onChanged: (updated) {
                                setState(() => _favorites = updated);
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesPage extends StatefulWidget {
  final int userId;
  final List<Medicine> initialFavorites;
  final ValueChanged<List<Medicine>> onChanged;
  const _FavoritesPage({
    required this.userId,
    required this.initialFavorites,
    required this.onChanged,
  });
  @override
  State<_FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<_FavoritesPage> {
  late List<Medicine> _favorites;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _favorites = widget.initialFavorites;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final favs = await SqliteService.fetchFavoriteMedicines(widget.userId);
    if (!mounted) return;
    setState(() {
      _favorites = favs;
      _loading = false;
    });
    widget.onChanged(favs);
  }

  Future<void> _remove(Medicine m) async {
    await SqliteService.toggleFavorite(widget.userId, m.id); // will remove
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? const Center(child: Text('No favorites saved'))
          : ListView.builder(
              itemCount: _favorites.length,
              itemBuilder: (context, i) {
                final med = _favorites[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(med.name),
                    subtitle: Text(
                      med.dosage.isEmpty ? 'No dosage info' : med.dosage,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () => _remove(med),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
