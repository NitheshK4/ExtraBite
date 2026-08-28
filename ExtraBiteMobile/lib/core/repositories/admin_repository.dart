import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_role.dart';

// ---------------------------------------------------------------------------
// AdminUserRecord — lightweight profile model used only in the admin dashboard
// ---------------------------------------------------------------------------

class AdminUserRecord {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool roleFinalized;
  final bool isOwnerEligible;
  final bool isSuspended;
  final bool isVerified;
  final DateTime createdAt;

  const AdminUserRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.roleFinalized,
    required this.isOwnerEligible,
    required this.isSuspended,
    required this.isVerified,
    required this.createdAt,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  /// True if this user attempted PG Owner signup but is not yet approved.
  bool get isPendingOwnerApproval =>
      !roleFinalized && !isOwnerEligible;

  factory AdminUserRecord.fromJson(Map<String, dynamic> json) {
    UserRole role;
    switch (json['role'] as String?) {
      case 'pg_owner':
        role = UserRole.owner;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.personal;
    }

    return AdminUserRecord(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone_number'] as String?) ?? '',
      role: role,
      roleFinalized: (json['role_finalized'] as bool?) ?? false,
      isOwnerEligible: (json['is_owner_eligible'] as bool?) ?? false,
      isSuspended: (json['is_suspended'] as bool?) ?? false,
      isVerified: (json['is_verified'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// AdminRepository — Supabase implementation
// ---------------------------------------------------------------------------

class AdminRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all profiles, ordered by most recently created.
  Future<List<AdminUserRecord>> getAllUsers() async {
    final data = await _client
        .from('profiles')
        .select(
          'id, full_name, email, phone_number, role, role_finalized, '
          'is_owner_eligible, is_suspended, is_verified, created_at',
        )
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => AdminUserRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch only users whose role has not been finalized yet.
  /// These are new users who haven't completed the role-selection flow,
  /// which includes people who attempted PG Owner signup.
  Future<List<AdminUserRecord>> getPendingUsers() async {
    final data = await _client
        .from('profiles')
        .select(
          'id, full_name, email, phone_number, role, role_finalized, '
          'is_owner_eligible, is_suspended, is_verified, created_at',
        )
        .eq('role_finalized', false)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => AdminUserRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Grant PG Owner eligibility to a user.
  /// Calls the existing `set_owner_eligibility(uuid, boolean)` DB function.
  Future<void> approveOwner(String userId) async {
    await _client.rpc('set_owner_eligibility', params: {
      'p_user_id': userId,
      'p_eligible': true,
    });
  }

  /// Revoke PG Owner eligibility from a user.
  Future<void> revokeOwner(String userId) async {
    await _client.rpc('set_owner_eligibility', params: {
      'p_user_id': userId,
      'p_eligible': false,
    });
  }

  /// Suspend or unsuspend a user.
  /// Uses a direct profile update; protected by the `check_profile_updates`
  /// trigger which only allows admins to change is_suspended.
  Future<void> setSuspended(String userId, {required bool suspended}) async {
    await _client
        .from('profiles')
        .update({'is_suspended': suspended})
        .eq('id', userId);
  }
}
