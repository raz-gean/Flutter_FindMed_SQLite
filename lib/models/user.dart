enum UserRole { customer, manager, admin }

extension UserRoleExt on UserRole {
  String get value => toString().split('.').last;
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.manager:
        return 'Pharmacy Manager';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromValue(String value) => UserRole.values.firstWhere(
    (r) => r.value == value,
    orElse: () => UserRole.customer,
  );
}

class AppUser {
  final int id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.role = UserRole.customer,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'role': role.value,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as int,
    email: map['email'] as String,
    displayName: (map['display_name'] as String?) ?? '',
    role: UserRoleExt.fromValue(map['role'] as String? ?? 'customer'),
    isActive: ((map['is_active'] as int?) ?? 1) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    ),
  );
}
