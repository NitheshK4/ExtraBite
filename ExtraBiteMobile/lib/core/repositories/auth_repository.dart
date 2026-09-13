import '../../models/user_model.dart';
import '../../models/user_role.dart';

// ---------------------------------------------------------------------------
// AuthResult — sealed result type returned by repository operations
// ---------------------------------------------------------------------------

sealed class AuthResult {
  const AuthResult();
}

/// Sign-in / sign-up succeeded and a live session exists.
final class AuthSuccess extends AuthResult {
  final UserModel user;
  const AuthSuccess(this.user);
}

/// Sign-up succeeded but the account still requires email confirmation.
final class AuthPendingConfirmation extends AuthResult {
  final String message;
  const AuthPendingConfirmation(this.message);
}

/// The operation failed with an error message suitable for display.
final class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

/// set_user_role() RPC failed because the user is not yet eligible for pg_owner.
final class AuthOwnerNotEligible extends AuthResult {
  const AuthOwnerNotEligible();
}

// ---------------------------------------------------------------------------
// AuthRepository — abstract interface
// ---------------------------------------------------------------------------

abstract class AuthRepository {
  /// Sign up a new user. Passes [fullName], [phone], and [role] as Supabase
  /// user metadata so the `handle_new_user` trigger can populate
  /// `public.profiles`.
  ///
  /// [role] must be [UserRole.personal] (→ 'customer') or
  /// [UserRole.owner] (→ 'pg_owner'). The repository enforces this
  /// mapping — no arbitrary roles are forwarded.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String phone,
    String? propertyName,
  });

  /// Sign in with email and password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  /// Starts Google OAuth sign-in through Supabase.
  Future<void> signInWithGoogle();

  /// Sign out the currently authenticated user.
  Future<void> signOut();

  /// Returns the currently authenticated [UserModel] by reading the active
  /// Supabase session + profile row, or null if no session exists.
  ///
  /// Called on app startup to restore a persisted session.
  Future<UserModel?> getCurrentUser();

  /// Starts password reset flow by sending a password reset email.
  Future<void> resetPasswordForEmail(String email);

  /// Calls the `set_user_role` RPC to finalize the user's role.
  ///
  /// Returns [AuthSuccess] with the refreshed profile on success.
  /// Returns [AuthOwnerNotEligible] if the user chose pg_owner but
  /// `is_owner_eligible = false`.
  /// Returns [AuthFailure] on any other error.
  Future<AuthResult> setUserRole(UserRole role);
}
