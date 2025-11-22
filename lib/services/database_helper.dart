import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/sample_data.dart';
import '../models/medicine.dart';
import '../models/pharmacy_company.dart';
import '../models/pharmacy_branch.dart';
import '../models/inventory_item.dart';
import '../models/note.dart';
import '../models/user.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _db;

  // Simple password hashing using crypto
  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'findmed_demo.db');
    _db = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE companies(id INTEGER PRIMARY KEY, name TEXT)',
        );
        await db.execute(
          'CREATE TABLE branches(id INTEGER PRIMARY KEY, company_id INTEGER, branch_name TEXT, branch_address TEXT, phone_number TEXT)',
        );
        await db.execute(
          'CREATE TABLE medications(id INTEGER PRIMARY KEY, name TEXT, generic_name TEXT, description TEXT, created_by_user_id INTEGER, last_updated_by_user_id INTEGER, updated_at INTEGER)',
        );
        await db.execute(
          'CREATE TABLE inventory(id INTEGER PRIMARY KEY, branch_id INTEGER, medication_id INTEGER, stock INTEGER, price REAL)',
        );
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE, display_name TEXT, hashed_password TEXT, role TEXT DEFAULT "customer", is_active INTEGER DEFAULT 1, created_at INTEGER)',
        );
        await db.execute(
          'CREATE TABLE branch_managers(id INTEGER PRIMARY KEY AUTOINCREMENT, branch_id INTEGER NOT NULL, user_id INTEGER NOT NULL, assigned_at INTEGER, FOREIGN KEY (branch_id) REFERENCES branches(id), FOREIGN KEY (user_id) REFERENCES users(id), UNIQUE(branch_id, user_id))',
        );
        await db.execute(
          'CREATE TABLE notes(id TEXT PRIMARY KEY, user_id INTEGER, title TEXT, content TEXT, created_at INTEGER)',
        );
        await db.execute(
          'CREATE TABLE favorites(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, medicine_id INTEGER, created_at INTEGER, UNIQUE(user_id, medicine_id))',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE, display_name TEXT)',
          );
          await db.execute(
            'CREATE TABLE notes(id TEXT PRIMARY KEY, user_id INTEGER, title TEXT, content TEXT, created_at INTEGER)',
          );
          await db.execute(
            'CREATE TABLE favorites(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, medicine_id INTEGER, created_at INTEGER, UNIQUE(user_id, medicine_id))',
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE users ADD COLUMN hashed_password TEXT');
          await db.execute(
            'ALTER TABLE users ADD COLUMN role TEXT DEFAULT "customer"',
          );
          await db.execute(
            'ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1',
          );
          await db.execute('ALTER TABLE users ADD COLUMN created_at INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE medications ADD COLUMN created_by_user_id INTEGER',
          );
          await db.execute(
            'ALTER TABLE medications ADD COLUMN last_updated_by_user_id INTEGER',
          );
          await db.execute(
            'ALTER TABLE medications ADD COLUMN updated_at INTEGER',
          );
          await db.execute(
            'CREATE TABLE branch_managers(id INTEGER PRIMARY KEY AUTOINCREMENT, branch_id INTEGER NOT NULL, user_id INTEGER NOT NULL, assigned_at INTEGER, FOREIGN KEY (branch_id) REFERENCES branches(id), FOREIGN KEY (user_id) REFERENCES users(id), UNIQUE(branch_id, user_id))',
          );
        }
      },
    );
    // One-time domain migration: update old demo accounts from @findmed.local to @gmail.com
    try {
      await _db!.rawUpdate(
        "UPDATE users SET email = REPLACE(email,'@findmed.local','@gmail.com') WHERE email LIKE '%@findmed.local'",
      );
    } catch (_) {}
    await _seedIfEmpty();
  }

  Future<Database> get _database async {
    if (_db == null) {
      await init();
    }
    return _db!;
  }

  Future<void> _seedIfEmpty() async {
    final db = await _database;
    final companiesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM companies'),
    );
    final adminUserCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users WHERE email = ?', [
        'admin@gmail.com',
      ]),
    );
    debugPrint(
      'DEBUG: Current companies count = $companiesCount, admin user exists = ${adminUserCount ?? 0}',
    );

    // Only skip if companies exist AND admin demo user exists
    if (companiesCount != null &&
        companiesCount > 0 &&
        adminUserCount != null &&
        adminUserCount > 0) {
      debugPrint(
        'DEBUG: Database already seeded with demo data, skipping seed',
      );
      return;
    }
    debugPrint('DEBUG: Starting database seed...');

    // Clear all tables before seeding to avoid constraint violations
    await db.delete('branch_managers');
    await db.delete('users');
    await db.delete('inventory');
    await db.delete('medications');
    await db.delete('branches');
    await db.delete('companies');
    debugPrint('DEBUG: Cleared all tables for fresh seed');

    final chains = SampleData.stores.map((s) => s.chain).toSet().toList();
    for (var i = 0; i < chains.length; i++) {
      await db.insert('companies', {'id': i + 1, 'name': chains[i]});
    }

    // Branches from stores
    for (final s in SampleData.stores) {
      final companyId = chains.indexOf(s.chain) + 1;
      await db.insert('branches', {
        'id': s.id,
        'company_id': companyId,
        'branch_name': s.name,
        'branch_address': s.address,
        'phone_number': s.phone,
      });
    }

    // Medications + inventory
    for (final m in SampleData.medicines) {
      await db.insert('medications', {
        'id': m.id,
        'name': m.name,
        'generic_name': m.genericName,
        'description': m.description,
        'created_by_user_id': null, // Seeded medicines (no manager)
        'last_updated_by_user_id': null,
        'updated_at': null,
      });
      await db.insert('inventory', {
        'id': m.id, // reuse id for demo simplicity
        'branch_id': m.storeId,
        'medication_id': m.id,
        'stock': m.stock,
        'price': m.price,
      });
    }

    // Seed demo users (customer, manager, and admin)
    final demoHash = _hashPassword('demo123');
    final now = DateTime.now().millisecondsSinceEpoch;
    debugPrint('DEBUG: Demo user password hash = $demoHash');

    await db.insert('users', {
      'email': 'customer@gmail.com',
      'display_name': 'Demo Customer',
      'hashed_password': demoHash,
      'role': UserRole.customer.value,
      'is_active': 1,
      'created_at': now,
    });

    final managerId = await db.insert('users', {
      'email': 'manager@gmail.com',
      'display_name': 'Demo Manager',
      'hashed_password': demoHash,
      'role': UserRole.manager.value,
      'is_active': 1,
      'created_at': now,
    });

    await db.insert('users', {
      'email': 'admin@gmail.com',
      'display_name': 'Admin',
      'hashed_password': demoHash,
      'role': UserRole.admin.value,
      'is_active': 1,
      'created_at': now,
    });
    debugPrint('DEBUG: Demo users created successfully');

    // Assign manager to first branch (ID 1)
    await db.insert('branch_managers', {
      'branch_id': 1,
      'user_id': managerId,
      'assigned_at': now,
    });

    // Seed sample medicines with descriptions
    final sampleMedicines = [
      {
        'name': 'Paracetamol',
        'generic_name': '500mg Tablet',
        'description':
            'Effective pain reliever and fever reducer. Used for headaches, body aches, and minor fever. Gentle on the stomach.',
      },
      {
        'name': 'Ibuprofen',
        'generic_name': '400mg Tablet',
        'description':
            'Non-steroidal anti-inflammatory drug (NSAID) for pain relief and inflammation. Ideal for muscle aches and joint pain.',
      },
      {
        'name': 'Amoxicillin',
        'generic_name': '500mg Capsule',
        'description':
            'Antibiotic used to treat bacterial infections. Effective against respiratory, ear, and urinary tract infections.',
      },
      {
        'name': 'Metformin',
        'generic_name': '500mg Tablet',
        'description':
            'First-line medication for type 2 diabetes. Helps control blood sugar levels and improve insulin sensitivity.',
      },
      {
        'name': 'Aspirin',
        'generic_name': '500mg Tablet',
        'description':
            'Pain reliever and blood thinner. Used for headaches, pain relief, and cardiovascular protection.',
      },
      {
        'name': 'Cetirizine',
        'generic_name': '10mg Tablet',
        'description':
            'Antihistamine for allergies. Provides relief from itching, sneezing, and allergic rhinitis.',
      },
      {
        'name': 'Omeprazole',
        'generic_name': '20mg Capsule',
        'description':
            'Proton pump inhibitor for acid reflux and GERD. Reduces stomach acid production for relief.',
      },
      {
        'name': 'Vitamin C',
        'generic_name': '1000mg Tablet',
        'description':
            'Essential vitamin for immune support and antioxidant protection. Boosts immunity and energy levels.',
      },
    ];

    for (final medicine in sampleMedicines) {
      await db.insert('medications', {
        'name': medicine['name'],
        'generic_name': medicine['generic_name'],
        'description': medicine['description'],
        'created_by_user_id': managerId,
        'last_updated_by_user_id': managerId,
        'updated_at': now,
      });
    }
  }

  Future<List<PharmacyCompany>> getCompanies() async {
    final db = await _database;
    final rows = await db.query('companies');
    return rows
        .map(
          (r) => PharmacyCompany(id: r['id'] as int, name: r['name'] as String),
        )
        .toList();
  }

  Future<List<PharmacyBranch>> getBranches() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT b.id, b.branch_name, b.branch_address, b.phone_number, c.id AS company_id, c.name AS company_name
      FROM branches b JOIN companies c ON b.company_id = c.id
      ORDER BY c.name, b.branch_name
    ''');
    return rows.map((r) {
      final company = PharmacyCompany(
        id: r['company_id'] as int,
        name: r['company_name'] as String,
      );
      return PharmacyBranch(
        id: r['id'] as int,
        company: company,
        branchName: r['branch_name'] as String,
        branchAddress: r['branch_address'] as String,
        phoneNumber: r['phone_number'] as String?,
      );
    }).toList();
  }

  Future<List<InventoryItem>> getInventory() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT i.id AS inventory_id, i.stock, i.price, 
             m.id AS med_id, m.name AS med_name, m.generic_name, m.description,
             b.id AS branch_id, b.branch_name, b.branch_address, b.phone_number,
             c.id AS company_id, c.name AS company_name
      FROM inventory i
      JOIN medications m ON m.id = i.medication_id
      JOIN branches b ON b.id = i.branch_id
      JOIN companies c ON c.id = b.company_id
    ''');
    return rows.map((r) {
      final company = PharmacyCompany(
        id: r['company_id'] as int,
        name: r['company_name'] as String,
      );
      final branch = PharmacyBranch(
        id: r['branch_id'] as int,
        company: company,
        branchName: r['branch_name'] as String,
        branchAddress: r['branch_address'] as String,
        phoneNumber: r['phone_number'] as String?,
      );
      final med = Medicine(
        id: r['med_id'] as int,
        name: r['med_name'] as String,
        dosage: (r['generic_name'] as String? ?? '').isNotEmpty
            ? (r['generic_name'] as String)
            : ((r['description'] as String?)?.split('\n').first ?? ''),
        price: (r['price'] as num).toDouble(),
        stock: r['stock'] as int,
        storeId: branch.id,
        genericName: r['generic_name'] as String?,
        description: r['description'] as String?,
        branchName: branch.branchName,
        companyName: company.name,
      );
      return InventoryItem(
        id: r['inventory_id'] as int,
        branch: branch,
        medicine: med,
        stock: med.stock,
        price: med.price,
      );
    }).toList();
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await _database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<int> createUserIfMissing(String email, String displayName) async {
    final existing = await getUserByEmail(email);
    if (existing != null) return existing.id;
    final db = await _database;
    return await db.insert('users', {
      'email': email,
      'display_name': displayName,
    });
  }

  Future<Note> insertNote(Note note) async {
    final db = await _database;
    await db.insert('notes', note.toMap());
    return note;
  }

  Future<List<Note>> getNotesByUser(int userId) async {
    final db = await _database;
    final rows = await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Note.fromMap(r)).toList();
  }

  Future<int> deleteNote(String id) async {
    final db = await _database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isFavorite(int userId, int medicineId) async {
    final db = await _database;
    final rows = await db.query(
      'favorites',
      where: 'user_id = ? AND medicine_id = ?',
      whereArgs: [userId, medicineId],
    );
    return rows.isNotEmpty;
  }

  Future<bool> toggleFavorite(int userId, int medicineId) async {
    final db = await _database;
    final exists = await isFavorite(userId, medicineId);
    if (exists) {
      await db.delete(
        'favorites',
        where: 'user_id = ? AND medicine_id = ?',
        whereArgs: [userId, medicineId],
      );
      return false;
    } else {
      await db.insert('favorites', {
        'user_id': userId,
        'medicine_id': medicineId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    }
  }

  Future<List<Medicine>> getFavoriteMedicines(int userId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT m.id AS med_id, m.name AS med_name, m.generic_name, m.description,
             i.price, i.stock, b.id AS branch_id, b.branch_name, b.branch_address, b.phone_number,
             c.id AS company_id, c.name AS company_name
      FROM favorites f
      JOIN medications m ON m.id = f.medicine_id
      LEFT JOIN inventory i ON i.medication_id = m.id
      LEFT JOIN branches b ON b.id = i.branch_id
      LEFT JOIN companies c ON c.id = b.company_id
      WHERE f.user_id = ?
    ''',
      [userId],
    );
    return rows.map((r) {
      final companyName = r['company_name'] as String?;
      final branchName = r['branch_name'] as String?;
      return Medicine(
        id: r['med_id'] as int,
        name: r['med_name'] as String,
        dosage: (r['generic_name'] as String? ?? '').isNotEmpty
            ? (r['generic_name'] as String)
            : ((r['description'] as String?)?.split('\n').first ?? ''),
        price: (r['price'] as num?)?.toDouble() ?? 0.0,
        stock: (r['stock'] as int?) ?? 0,
        storeId: (r['branch_id'] as int?) ?? 0,
        genericName: r['generic_name'] as String?,
        description: r['description'] as String?,
        branchName: branchName,
        companyName: companyName,
      );
    }).toList();
  }

  // =============== AUTH METHODS ===============

  /// Register a new user with email, password, display name, and optional role
  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.customer,
  }) async {
    final db = await _database;
    try {
      final hashedPassword = _hashPassword(password);
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await db.insert('users', {
        'email': email,
        'display_name': displayName,
        'hashed_password': hashedPassword,
        'role': role.value,
        'is_active': 1,
        'created_at': now,
      });
      return AppUser(
        id: id,
        email: email,
        displayName: displayName,
        role: role,
        isActive: true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    } catch (e) {
      return null; // Email already exists or other DB error
    }
  }

  /// Login: verify email & password, return AppUser if successful
  Future<AppUser?> loginUser(String email, String password) async {
    final db = await _database;
    debugPrint('DEBUG: Attempting login with email = $email');

    // Query all users and check manually (SQLite LOWER() not reliable with prepared statements)
    final rows = await db.query('users', where: 'is_active = 1');
    debugPrint('DEBUG: Total active users in DB = ${rows.length}');

    // Find user by case-insensitive email
    final normalizedInput = email.toLowerCase().trim();
    final matchingRows = rows.where((row) {
      final dbEmail = (row['email'] as String?)?.toLowerCase() ?? '';
      return dbEmail == normalizedInput;
    }).toList();

    debugPrint('DEBUG: Query returned ${matchingRows.length} matching rows');
    if (matchingRows.isEmpty) {
      debugPrint('DEBUG: No user found with email $email');
      // List all emails in database
      for (var row in rows) {
        debugPrint('DEBUG: Found user in DB: ${row['email']}');
      }
      return null;
    }

    final row = matchingRows.first;
    debugPrint('DEBUG: Found user: ${row['email']}, role: ${row['role']}');
    final storedHash = row['hashed_password'] as String?;
    debugPrint('DEBUG: Stored hash: $storedHash');
    final incomingHash = _hashPassword(password);
    debugPrint('DEBUG: Incoming hash: $incomingHash');
    if (storedHash == null || !_verifyPassword(password, storedHash)) {
      debugPrint('DEBUG: Password verification failed');
      return null; // Password mismatch
    }
    debugPrint('DEBUG: Password verified, returning user');
    return AppUser.fromMap(row);
  }

  /// Get user by ID
  Future<AppUser?> getUserById(int id) async {
    final db = await _database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  /// Update user's display name
  Future<bool> updateUserDisplayName(int userId, String newName) async {
    final db = await _database;
    final result = await db.update(
      'users',
      {'display_name': newName},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result > 0;
  }

  /// Change password for user
  Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final user = await getUserById(userId);
    if (user == null) return false;

    final rows = await (await _database).query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      columns: ['hashed_password'],
    );
    if (rows.isEmpty) return false;

    final storedHash = rows.first['hashed_password'] as String?;
    if (storedHash == null || !_verifyPassword(oldPassword, storedHash)) {
      return false; // Old password incorrect
    }

    final db = await _database;
    final newHash = _hashPassword(newPassword);
    final result = await db.update(
      'users',
      {'hashed_password': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result > 0;
  }

  /// Update user role (manager/customer)
  Future<bool> updateUserRole(int userId, UserRole newRole) async {
    final db = await _database;
    final result = await db.update(
      'users',
      {'role': newRole.value},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result > 0;
  }

  /// Deactivate user account
  Future<bool> deactivateUser(int userId) async {
    final db = await _database;
    final result = await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result > 0;
  }

  /// Get all active users (admin feature)
  Future<List<AppUser>> getAllActiveUsers() async {
    final db = await _database;
    final rows = await db.query('users', where: 'is_active = 1');
    return rows.map((r) => AppUser.fromMap(r)).toList();
  }

  /// Get users by role
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final db = await _database;
    final rows = await db.query(
      'users',
      where: 'role = ? AND is_active = 1',
      whereArgs: [role.value],
    );
    return rows.map((r) => AppUser.fromMap(r)).toList();
  }

  // =============== BRANCH-MANAGER METHODS ===============

  /// Assign a manager to a branch
  Future<bool> assignManagerToBranch(int userId, int branchId) async {
    final db = await _database;
    try {
      await db.insert('branch_managers', {
        'branch_id': branchId,
        'user_id': userId,
        'assigned_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      return false; // Duplicate or constraint violation
    }
  }

  /// Get all branches managed by a user
  Future<List<PharmacyBranch>> getManagerBranches(int userId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT b.id, b.branch_name, b.branch_address, b.phone_number, 
             c.id AS company_id, c.name AS company_name
      FROM branches b
      JOIN companies c ON b.company_id = c.id
      JOIN branch_managers bm ON bm.branch_id = b.id
      WHERE bm.user_id = ?
      ORDER BY c.name, b.branch_name
    ''',
      [userId],
    );
    return rows.map((r) {
      final company = PharmacyCompany(
        id: r['company_id'] as int,
        name: r['company_name'] as String,
      );
      return PharmacyBranch(
        id: r['id'] as int,
        company: company,
        branchName: r['branch_name'] as String,
        branchAddress: r['branch_address'] as String,
        phoneNumber: r['phone_number'] as String?,
      );
    }).toList();
  }

  /// Get all managers for a branch
  Future<List<AppUser>> getBranchManagers(int branchId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT u.* FROM users u
      JOIN branch_managers bm ON bm.user_id = u.id
      WHERE bm.branch_id = ? AND u.is_active = 1
    ''',
      [branchId],
    );
    return rows.map((r) => AppUser.fromMap(r)).toList();
  }

  /// Remove manager from branch
  Future<bool> removeManagerFromBranch(int userId, int branchId) async {
    final db = await _database;
    final result = await db.delete(
      'branch_managers',
      where: 'user_id = ? AND branch_id = ?',
      whereArgs: [userId, branchId],
    );
    return result > 0;
  }

  /// Check if user is manager of branch
  Future<bool> isManagerOfBranch(int userId, int branchId) async {
    final db = await _database;
    final rows = await db.query(
      'branch_managers',
      where: 'user_id = ? AND branch_id = ?',
      whereArgs: [userId, branchId],
    );
    return rows.isNotEmpty;
  }

  // =============== MEDICINE CRUD METHODS ===============

  /// Add medicine (manager-scoped)
  Future<int?> addMedicine({
    required String name,
    required String genericName,
    required String description,
    required int managerId,
    required int branchId,
    int initialStock = 0,
    double initialPrice = 0.0,
  }) async {
    // Verify manager owns this branch
    if (!await isManagerOfBranch(managerId, branchId)) {
      return null; // Unauthorized
    }

    final db = await _database;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final medicineId = await db.insert('medications', {
        'name': name,
        'generic_name': genericName,
        'description': description,
        'created_by_user_id': managerId,
        'last_updated_by_user_id': managerId,
        'updated_at': now,
      });

      // Create / seed inventory row for this branch
      await db.insert('inventory', {
        'branch_id': branchId,
        'medication_id': medicineId,
        'stock': initialStock,
        'price': initialPrice,
      });
      return medicineId;
    } catch (e) {
      return null;
    }
  }

  /// Update inventory (stock and/or price) for a medicine in a branch (manager-scoped)
  Future<bool> updateMedicineInventory({
    required int medicineId,
    required int branchId,
    required int managerId,
    int? newStock,
    double? newPrice,
  }) async {
    if (!await isManagerOfBranch(managerId, branchId)) {
      return false; // Unauthorized
    }

    // Nothing to update
    if (newStock == null && newPrice == null) return false;

    final db = await _database;

    // Check existing inventory row
    final existing = await db.query(
      'inventory',
      where: 'medication_id = ? AND branch_id = ?',
      whereArgs: [medicineId, branchId],
      limit: 1,
    );

    final updates = <String, Object?>{};
    if (newStock != null) updates['stock'] = newStock;
    if (newPrice != null) updates['price'] = newPrice;

    try {
      if (existing.isEmpty) {
        // Create new inventory row if missing
        await db.insert('inventory', {
          'branch_id': branchId,
          'medication_id': medicineId,
          'stock': newStock ?? 0,
          'price': newPrice ?? 0.0,
        });
        return true;
      } else {
        final result = await db.update(
          'inventory',
          updates,
          where: 'medication_id = ? AND branch_id = ?',
          whereArgs: [medicineId, branchId],
        );
        return result > 0;
      }
    } catch (e) {
      return false;
    }
  }

  /// Update medicine (manager-scoped)
  Future<bool> updateMedicine({
    required int medicineId,
    required String name,
    required String genericName,
    required String description,
    required int managerId,
    required int branchId,
  }) async {
    if (!await isManagerOfBranch(managerId, branchId)) {
      return false; // Unauthorized
    }

    final db = await _database;
    final result = await db.update(
      'medications',
      {
        'name': name,
        'generic_name': genericName,
        'description': description,
        'last_updated_by_user_id': managerId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [medicineId],
    );
    return result > 0;
  }

  /// Delete medicine (manager-scoped)
  Future<bool> deleteMedicine(
    int medicineId,
    int managerId,
    int branchId,
  ) async {
    if (!await isManagerOfBranch(managerId, branchId)) {
      return false; // Unauthorized
    }

    final db = await _database;
    // Also delete from inventory for this branch
    await db.delete(
      'inventory',
      where: 'medication_id = ? AND branch_id = ?',
      whereArgs: [medicineId, branchId],
    );
    // Delete from favorites
    await db.delete(
      'favorites',
      where: 'medicine_id = ?',
      whereArgs: [medicineId],
    );
    // Delete medicine
    final result = await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [medicineId],
    );
    return result > 0;
  }

  /// Get medicines for a specific branch (manager view)
  Future<List<Medicine>> getMedicinesForBranch(int branchId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT m.*, i.stock, i.price, i.branch_id
      FROM medications m
      LEFT JOIN inventory i ON i.medication_id = m.id AND i.branch_id = ?
      WHERE i.branch_id IS NOT NULL
    ''',
      [branchId],
    );
    return rows.map((r) {
      return Medicine(
        id: r['id'] as int,
        name: r['name'] as String,
        dosage: (r['generic_name'] as String? ?? '').isNotEmpty
            ? (r['generic_name'] as String)
            : ((r['description'] as String?)?.split('\n').first ?? ''),
        price: (r['price'] as num?)?.toDouble() ?? 0.0,
        stock: (r['stock'] as int?) ?? 0,
        storeId: branchId,
        genericName: r['generic_name'] as String?,
        description: r['description'] as String?,
      );
    }).toList();
  }

  /// Update inventory stock (manager-scoped)
  Future<bool> updateInventoryStock(
    int inventoryId,
    int newStock,
    int managerId,
    int branchId,
  ) async {
    if (!await isManagerOfBranch(managerId, branchId)) {
      return false;
    }

    final db = await _database;
    final result = await db.update(
      'inventory',
      {'stock': newStock},
      where: 'id = ? AND branch_id = ?',
      whereArgs: [inventoryId, branchId],
    );
    return result > 0;
  }

  /// Update inventory price (manager-scoped)
  Future<bool> updateInventoryPrice(
    int inventoryId,
    double newPrice,
    int managerId,
    int branchId,
  ) async {
    if (!await isManagerOfBranch(managerId, branchId)) {
      return false;
    }

    final db = await _database;
    final result = await db.update(
      'inventory',
      {'price': newPrice},
      where: 'id = ? AND branch_id = ?',
      whereArgs: [inventoryId, branchId],
    );
    return result > 0;
  }

  // =============== ADMIN METHODS ===============
  /// Get all unapproved (unassigned) managers
  Future<List<AppUser>> getUnassignedManagers() async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT u.* FROM users u
      WHERE u.role = ? AND u.is_active = 1
      AND u.id NOT IN (SELECT user_id FROM branch_managers)
    ''',
      [UserRole.manager.value],
    );
    return rows.map((r) => AppUser.fromMap(r)).toList();
  }

  /// Get all managers with their assigned branches
  Future<List<Map<String, dynamic>>> getManagersWithBranches() async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT u.id, u.email, u.display_name, u.created_at,
             b.id AS branch_id, b.branch_name, b.branch_address
      FROM users u
      LEFT JOIN branch_managers bm ON bm.user_id = u.id
      LEFT JOIN branches b ON b.id = bm.branch_id
      WHERE u.role = ? AND u.is_active = 1
      ORDER BY u.display_name
    ''',
      [UserRole.manager.value],
    );
    return rows;
  }

  /// Assign a manager to a branch (admin operation)
  Future<bool> assignManagerToBranchAdmin(int managerId, int branchId) async {
    // Check manager exists
    final manager = await getUserById(managerId);
    if (manager == null || manager.role != UserRole.manager) {
      return false;
    }

    // Check if manager already assigned to a branch
    final existingAssignment = await (await _database).query(
      'branch_managers',
      where: 'user_id = ?',
      whereArgs: [managerId],
    );
    if (existingAssignment.isNotEmpty) {
      return false; // Manager already has a branch
    }

    final db = await _database;
    try {
      await db.insert('branch_managers', {
        'branch_id': branchId,
        'user_id': managerId,
        'assigned_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reassign a manager to a different branch (admin operation)
  Future<bool> reassignManagerToBranch(int managerId, int newBranchId) async {
    final db = await _database;
    try {
      // Delete old assignment
      await db.delete(
        'branch_managers',
        where: 'user_id = ?',
        whereArgs: [managerId],
      );

      // Create new assignment
      await db.insert('branch_managers', {
        'branch_id': newBranchId,
        'user_id': managerId,
        'assigned_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all branches for branch dropdown
  Future<List<Map<String, dynamic>>> getAllBranches() async {
    final db = await _database;
    final rows = await db.query('branches', orderBy: 'branch_name');
    return rows;
  }

  // ===== Pagination Helpers =====
  Future<int> getBranchesCount() async {
    final db = await _database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM branches');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getBranchesPaged({
    required int limit,
    required int offset,
  }) async {
    final db = await _database;
    return db.rawQuery(
      'SELECT * FROM branches ORDER BY branch_name LIMIT ? OFFSET ?',
      [limit, offset],
    );
  }

  Future<int> getManagersCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM users WHERE role = ? AND is_active = 1',
      [UserRole.manager.value],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getManagersWithBranchesPaged({
    required int limit,
    required int offset,
  }) async {
    final db = await _database;
    return db.rawQuery(
      '''
      SELECT u.id, u.email, u.display_name, u.created_at,
             b.id AS branch_id, b.branch_name, b.branch_address
      FROM users u
      LEFT JOIN branch_managers bm ON bm.user_id = u.id
      LEFT JOIN branches b ON b.id = bm.branch_id
      WHERE u.role = ? AND u.is_active = 1
      ORDER BY u.display_name
      LIMIT ? OFFSET ?
      ''',
      [UserRole.manager.value, limit, offset],
    );
  }

  /// Deactivate a manager (admin operation)
  Future<bool> deactivateManagerAdmin(int managerId) async {
    final db = await _database;
    try {
      // First remove from branch_managers
      await db.delete(
        'branch_managers',
        where: 'user_id = ?',
        whereArgs: [managerId],
      );

      // Then deactivate user
      final result = await db.update(
        'users',
        {'is_active': 0},
        where: 'id = ? AND role = ?',
        whereArgs: [managerId, UserRole.manager.value],
      );
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// Create a new branch (admin operation)
  Future<Map<String, dynamic>?> createBranchAdmin({
    required int companyId,
    required String branchName,
    required String branchAddress,
    required String phoneNumber,
  }) async {
    final db = await _database;
    try {
      final branchId = await db.insert('branches', {
        'company_id': companyId,
        'branch_name': branchName,
        'branch_address': branchAddress,
        'phone_number': phoneNumber,
      });
      debugPrint(
        'DEBUG: Branch created successfully - ID: $branchId, Name: $branchName, Company: $companyId',
      );
      return {
        'id': branchId,
        'company_id': companyId,
        'branch_name': branchName,
        'branch_address': branchAddress,
        'phone_number': phoneNumber,
      };
    } catch (e) {
      debugPrint('Error creating branch: $e');
      return null;
    }
  }

  /// Update an existing branch (admin operation)
  Future<bool> updateBranchAdmin({
    required int branchId,
    required int companyId,
    required String branchName,
    required String branchAddress,
    required String phoneNumber,
  }) async {
    final db = await _database;
    try {
      final rows = await db.update(
        'branches',
        {
          'company_id': companyId,
          'branch_name': branchName,
          'branch_address': branchAddress,
          'phone_number': phoneNumber,
        },
        where: 'id = ?',
        whereArgs: [branchId],
      );
      debugPrint('DEBUG: updateBranchAdmin result rows=$rows for id=$branchId');
      return rows > 0;
    } catch (e) {
      debugPrint('Error updating branch $branchId: $e');
      return false;
    }
  }

  /// Delete a branch and cascade related data (admin operation)
  /// Removes: branch_managers assignments, inventory rows for the branch.
  /// Medicines remain (they may be used by other branches or re-linked later).
  Future<bool> deleteBranchAdmin(int branchId) async {
    final db = await _database;
    try {
      await db.delete(
        'branch_managers',
        where: 'branch_id = ?',
        whereArgs: [branchId],
      );
      await db.delete(
        'inventory',
        where: 'branch_id = ?',
        whereArgs: [branchId],
      );
      final rows = await db.delete(
        'branches',
        where: 'id = ?',
        whereArgs: [branchId],
      );
      debugPrint(
        'DEBUG: deleteBranchAdmin removed branchId=$branchId rows=$rows',
      );
      return rows > 0;
    } catch (e) {
      debugPrint('Error deleting branch $branchId: $e');
      return false;
    }
  }

  /// Get all companies (for branch creation dropdown)
  Future<List<Map<String, dynamic>>> getAllCompanies() async {
    final db = await _database;
    final rows = await db.query('companies', orderBy: 'name');
    return rows;
  }

  /// Get branches without assigned managers
  Future<List<Map<String, dynamic>>> getUnassignedBranches() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT b.* FROM branches b
      WHERE b.id NOT IN (
        SELECT DISTINCT branch_id FROM branch_managers
      )
      ORDER BY b.branch_name
    ''');
    return rows;
  }

  /// Seed additional demo medicines across all branches for richer UI.
  /// Safe to call multiple times; it will skip medicines already present.
  Future<void> seedAdditionalDemoMedicines() async {
    final db = await _database;
    final existingNamesRows = await db.rawQuery('SELECT name FROM medications');
    final existingNames = existingNamesRows
        .map((r) => r['name'] as String)
        .toSet();

    final additional = [
      {
        'name': 'Hydroxyzine',
        'generic': '25mg Tablet',
        'desc':
            'Antihistamine used to treat itching caused by allergies; also has sedative properties.',
        'basePrice': 3.20,
      },
      {
        'name': 'Azithromycin',
        'generic': '500mg Tablet',
        'desc':
            'Broad-spectrum macrolide antibiotic for respiratory and skin infections.',
        'basePrice': 15.75,
      },
      {
        'name': 'Naproxen',
        'generic': '500mg Tablet',
        'desc':
            'NSAID for relief of pain and inflammation associated with arthritis and injury.',
        'basePrice': 4.60,
      },
      {
        'name': 'Clopidogrel',
        'generic': '75mg Tablet',
        'desc':
            'Antiplatelet agent used to prevent blood clots after cardiac events.',
        'basePrice': 18.40,
      },
      {
        'name': 'Simvastatin',
        'generic': '20mg Tablet',
        'desc':
            'Statin used to control hypercholesterolemia and reduce cardiovascular risk.',
        'basePrice': 7.10,
      },
      {
        'name': 'Prednisone',
        'generic': '20mg Tablet',
        'desc':
            'Corticosteroid for reducing inflammation in various conditions.',
        'basePrice': 5.25,
      },
      {
        'name': 'Furosemide',
        'generic': '40mg Tablet',
        'desc': 'Loop diuretic for managing edema and hypertension.',
        'basePrice': 3.85,
      },
      {
        'name': 'Levothyroxine',
        'generic': '50mcg Tablet',
        'desc': 'Synthetic thyroid hormone used to treat hypothyroidism.',
        'basePrice': 6.30,
      },
      {
        'name': 'Gabapentin',
        'generic': '300mg Capsule',
        'desc': 'Used for neuropathic pain and seizure control.',
        'basePrice': 12.90,
      },
      {
        'name': 'Montelukast',
        'generic': '10mg Tablet',
        'desc':
            'Leukotriene receptor antagonist for asthma and allergy symptom prevention.',
        'basePrice': 9.40,
      },
      {
        'name': 'Doxycycline',
        'generic': '100mg Capsule',
        'desc':
            'Tetracycline antibiotic for infections including acne and respiratory tract.',
        'basePrice': 11.20,
      },
      {
        'name': 'Lansoprazole',
        'generic': '30mg Capsule',
        'desc': 'Proton pump inhibitor for acid-related disorders.',
        'basePrice': 14.30,
      },
    ];

    final branchRows = await db.query('branches');
    final rand = Random();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final med in additional) {
      final name = med['name'] as String;
      if (existingNames.contains(name)) {
        continue; // already present
      }
      final medId = await db.insert('medications', {
        'name': name,
        'generic_name': med['generic'] as String,
        'description': med['desc'] as String,
        'created_by_user_id': null,
        'last_updated_by_user_id': null,
        'updated_at': now,
      });
      for (final b in branchRows) {
        final branchId = b['id'] as int;
        // Skip some inventory rows randomly for variety (approx 25% missing)
        if (rand.nextDouble() < 0.25) continue;
        final stock = 20 + rand.nextInt(130); // 20..149
        final priceBase = (med['basePrice'] as double);
        final price = (priceBase * (0.9 + rand.nextDouble() * 0.3)); // ±30%
        // Prevent duplicate inventory rows if method called again
        final existsInv = await db.query(
          'inventory',
          where: 'branch_id = ? AND medication_id = ?',
          whereArgs: [branchId, medId],
        );
        if (existsInv.isNotEmpty) continue;
        await db.insert('inventory', {
          'branch_id': branchId,
          'medication_id': medId,
          'stock': stock,
          'price': double.parse(price.toStringAsFixed(2)),
        });
      }
    }
  }
}
