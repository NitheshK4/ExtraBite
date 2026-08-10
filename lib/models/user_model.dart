enum UserRole {
  customer,
  pgOwner,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.pgOwner:
        return 'PG Owner / Host';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final UserRole role;
  final String? avatarUrl;
  final List<String> dietaryPreferences;
  final String? pgId; // Linked PG ID if role is pgOwner
  final bool isVerified;
  final bool isSuspended;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.avatarUrl,
    this.dietaryPreferences = const [],
    this.pgId,
    this.isVerified = true,
    this.isSuspended = false,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? avatarUrl,
    List<String>? dietaryPreferences,
    String? pgId,
    bool? isVerified,
    bool? isSuspended,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      pgId: pgId ?? this.pgId,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': role.name,
        'avatar_url': avatarUrl,
        'dietary_preferences': dietaryPreferences,
        'pg_id': pgId,
        'is_verified': isVerified,
        'is_suspended': isSuspended,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      avatarUrl: json['avatar_url'] as String?,
      dietaryPreferences: List<String>.from(json['dietary_preferences'] ?? []),
      pgId: json['pg_id'] as String?,
      isVerified: json['is_verified'] as bool? ?? true,
      isSuspended: json['is_suspended'] as bool? ?? false,
    );
  }
}
