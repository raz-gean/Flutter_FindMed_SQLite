import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';

/// Auth service: handles registration, login, logout, and session state
class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;
  bool get isManager => _currentUser?.role == UserRole.manager;
  bool get isCustomer => _currentUser?.role == UserRole.customer;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  AuthService() {
    _loadPersistentSession();
  }

  /// Load previously stored user session from SharedPreferences
  Future<void> _loadPersistentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('session_user_id');

      if (userId != null) {
        final user = await DatabaseHelper.instance.getUserById(userId);
        if (user != null && user.isActive) {
          _currentUser = user;
          notifyListeners();
        } else {
          // User doesn't exist or is deactivated, clear session
          await _clearPersistentSession();
        }
      }
    } catch (e) {
      // Silently fail - user will need to login
      debugPrint('Failed to load persistent session: $e');
    }
  }

  /// Save user session to SharedPreferences
  Future<void> _savePersistentSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('session_user_id', user.id);
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  /// Clear user session from SharedPreferences
  Future<void> _clearPersistentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_user_id');
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.customer,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        _error = 'Please fill in all fields';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = await DatabaseHelper.instance.registerUser(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );

      if (user == null) {
        _error = 'Email already registered or invalid';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      await _savePersistentSession(user);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        _error = 'Please enter email and password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = await DatabaseHelper.instance.loginUser(email, password);
      if (user == null) {
        _error = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      await _savePersistentSession(user);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    await _clearPersistentSession();
    notifyListeners();
  }

  /// Change password for current user
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) {
      _error = 'No user logged in';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await DatabaseHelper.instance.changePassword(
        _currentUser!.id,
        oldPassword,
        newPassword,
      );
      if (!success) {
        _error = 'Old password is incorrect or password change failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Password change failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update display name for current user
  Future<bool> updateDisplayName(String newName) async {
    if (_currentUser == null) {
      _error = 'No user logged in';
      return false;
    }

    try {
      final success = await DatabaseHelper.instance.updateUserDisplayName(
        _currentUser!.id,
        newName,
      );
      if (success) {
        _currentUser = AppUser(
          id: _currentUser!.id,
          email: _currentUser!.email,
          displayName: newName,
          role: _currentUser!.role,
          isActive: _currentUser!.isActive,
          createdAt: _currentUser!.createdAt,
        );
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Update failed: ${e.toString()}';
      return false;
    }
  }

  /// Get all active users (admin/manager feature)
  Future<List<AppUser>> getAllActiveUsers() async {
    try {
      return await DatabaseHelper.instance.getAllActiveUsers();
    } catch (e) {
      _error = 'Failed to fetch users: ${e.toString()}';
      return [];
    }
  }

  /// Get users by role
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      return await DatabaseHelper.instance.getUsersByRole(role);
    } catch (e) {
      _error = 'Failed to fetch users: ${e.toString()}';
      return [];
    }
  }

  /// Update user role (manager only)
  Future<bool> updateUserRole(int userId, UserRole newRole) async {
    if (!isManager) {
      _error = 'Only managers can update user roles';
      return false;
    }

    try {
      return await DatabaseHelper.instance.updateUserRole(userId, newRole);
    } catch (e) {
      _error = 'Failed to update role: ${e.toString()}';
      return false;
    }
  }

  /// Deactivate user account (admin only)
  Future<bool> deactivateUser(int userId) async {
    try {
      return await DatabaseHelper.instance.deactivateUser(userId);
    } catch (e) {
      _error = 'Failed to deactivate user: ${e.toString()}';
      return false;
    }
  }

  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if current manager has an assigned branch
  Future<bool> hasAssignedBranch() async {
    if (!isManager || _currentUser == null) {
      return false; // Not a manager or not logged in
    }
    try {
      final branches = await DatabaseHelper.instance.getManagerBranches(
        _currentUser!.id,
      );
      return branches.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking manager branches: $e');
      return false;
    }
  }
}
