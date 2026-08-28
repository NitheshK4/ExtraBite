import 'user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? propertyName;
  final DateTime createdAt;

  // Onboarding / eligibility flags from public.profiles
  final bool roleFinalized;
  final bool isOwnerEligible;
  final bool isSuspended;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.propertyName,
    DateTime? createdAt,
    this.roleFinalized = false,
    this.isOwnerEligible = false,
    this.isSuspended = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'propertyName': propertyName,
      'createdAt': createdAt.toIso8601String(),
      'roleFinalized': roleFinalized,
      'isOwnerEligible': isOwnerEligible,
      'isSuspended': isSuspended,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.personal,
      ),
      propertyName: json['propertyName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      roleFinalized: (json['roleFinalized'] as bool?) ?? false,
      isOwnerEligible: (json['isOwnerEligible'] as bool?) ?? false,
      isSuspended: (json['isSuspended'] as bool?) ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? propertyName,
    DateTime? createdAt,
    bool? roleFinalized,
    bool? isOwnerEligible,
    bool? isSuspended,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      propertyName: propertyName ?? this.propertyName,
      createdAt: createdAt ?? this.createdAt,
      roleFinalized: roleFinalized ?? this.roleFinalized,
      isOwnerEligible: isOwnerEligible ?? this.isOwnerEligible,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }
}
