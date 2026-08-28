
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import 'auth_repository.dart';

String _roleToDbString(UserRole role) {
  return switch (role) {
    UserRole.owner => 'pg_owner',
    UserRole.personal => 'customer',
    UserRole.admin => 'admin',
  };
}

UserRole _dbStringToRole(String? dbRole) {
  return switch (dbRole) {
    'pg_owner' => UserRole.owner,
    'admin' => UserRole.admin,
    _ => UserRole.personal,
  };
}

UserModel _profileToUserModel(Map<String, dynamic> profile) {
  return UserModel(
    id: profile['id'] as String,
    name: (profile['full_name'] as String?) ?? '',
    email: (profile['email'] as String?) ?? '',
    phone: (profile['phone_number'] as String?) ?? '',
    role: _dbStringToRole(profile['role'] as String?),
    createdAt: profile['created_at'] != null
        ? DateTime.tryParse(profile['created_at'] as String)
        : null,
    // Onboarding / eligibility flags — default false if column absent
    roleFinalized: (profile['role_finalized'] as bool?) ?? false,
    isOwnerEligible: (profile['is_owner_eligible'] as bool?) ?? false,
    isSuspended: (profile['is_suspended'] as bool?) ?? false,
  );
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;
  static const String _redirectTo = 'io.extrabite.extrabite_mobile://login-callback/';

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String phone,
    String? propertyName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        emailRedirectTo: _redirectTo,
        data: {
          'full_name': fullName.trim(),
          'role': _roleToDbString(role),
          'phone_number': phone.trim(),
          if (propertyName != null && propertyName.trim().isNotEmpty)
            'property_name': propertyName.trim(),
        },
      );

      if (response.session == null) {
        return const AuthPendingConfirmation(
          'Check your email to confirm your account, then return to ExtraBite to continue.',
        );
      }

      final userId = response.session!.user.id;
      final profile = await _fetchProfile(userId);
      if (profile == null) {
        // Profile may not be created yet by the trigger — return a minimal model
        // with role_finalized = false so the router sends the user to role selection.
        return AuthSuccess(
          UserModel(
            id: userId,
            name: fullName.trim(),
            email: email.trim().toLowerCase(),
            phone: phone.trim(),
            role: UserRole.personal,
            roleFinalized: false,
            isOwnerEligible: false,
            isSuspended: false,
          ),
        );
      }

      return AuthSuccess(_profileToUserModel(profile));
    } on AuthException catch (e) {
      return AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      return AuthFailure(AppConfig.formatErrorMessage(e));
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.session == null || response.user == null) {
        return const AuthFailure('Sign-in failed. Please try again.');
      }

      final profile = await _fetchProfile(response.user!.id);
      if (profile == null) {
        return const AuthFailure(
          'Your profile could not be found. The database schema may not be deployed. Please contact support.',
        );
      }

      return AuthSuccess(_profileToUserModel(profile));
    } on AuthException catch (e) {
      return AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      return AuthFailure(AppConfig.formatErrorMessage(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectTo,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    try {
      final profile = await _fetchProfile(session.user.id);
      if (profile == null) return null;
      return _profileToUserModel(profile);
    } catch (_) {
      return null;
    }
  }

  /// Calls the existing `set_user_role(user_role)` RPC.
  ///
  /// The RPC signature is: `set_user_role(p_role user_role) RETURNS void`
  /// On success it mutates the caller's profile row and returns void.
  /// If the user is not eligible for pg_owner the RPC raises an exception
  /// containing the text "not eligible".
  @override
  Future<AuthResult> setUserRole(UserRole role) async {
    try {
      await _client.rpc('set_user_role', params: {
        'p_role': _roleToDbString(role),
      });

      // Re-fetch profile to get updated role_finalized / role values.
      final session = _client.auth.currentSession;
      if (session == null) {
        return const AuthFailure('Session expired. Please sign in again.');
      }
      final profile = await _fetchProfile(session.user.id);
      if (profile == null) {
        return const AuthFailure('Could not reload your profile. Please try again.');
      }
      return AuthSuccess(_profileToUserModel(profile));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not eligible') || msg.contains('pg_owner')) {
        // RPC denied — user is not yet eligible for pg_owner.
        return const AuthOwnerNotEligible();
      }
      return AuthFailure('Could not set role. Please try again. ($e)');
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: _redirectTo,
    );
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final response = await _client.from('profiles').select().eq('id', userId).single();
      return response;
    } catch (_) {
      return null;
    }
  }

  String _mapAuthError(String? supabaseMessage) {
    final msg = supabaseMessage?.toLowerCase() ?? '';
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('email already registered') ||
        msg.contains('user already registered')) {
      return 'An account with this email already exists. Please log in.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('unable to validate email address')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return supabaseMessage ?? 'An unexpected error occurred.';
  }
}
