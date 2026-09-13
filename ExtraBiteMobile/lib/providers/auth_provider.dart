import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/repositories/auth_repository.dart';
import '../core/repositories/supabase_auth_repository.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

import '../core/repositories/pg_profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final pgProfileRepositoryProvider = Provider<PgProfileRepository>((ref) {
  return PgProfileRepository(supabase.Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// AuthStatus
// ---------------------------------------------------------------------------

enum AuthStatus {
  /// App is starting up — no session determination yet.
  uninitialized,

  /// No session; user must pick a role and then sign in / sign up.
  selectingRole,

  /// Role has been selected; waiting for email/password entry.
  unauthenticated,

  /// Sign-in / sign-up network call in progress.
  authenticating,

  /// Session exists but we are loading the profile from Supabase.
  profileLoading,

  /// Session and profile loaded.
  /// Check [AuthState.user] fields for routing decisions:
  ///   • user.isSuspended        → suspended screen
  ///   • !user.roleFinalized     → role-selection / owner-pending
  ///   • user.roleFinalized      → use user.role to route
  authenticated,

  /// User chose PG Owner but is_owner_eligible = false.
  pendingOwnerApproval,

  /// Account is suspended.
  suspended,

  /// Finalized PG Owner but has not registered a property yet.
  propertyRegistrationRequired,

  /// Finalized PG Owner with a registered property awaiting admin approval.
  propertyApprovalPending,

  /// An error occurred.
  error,
}

// ---------------------------------------------------------------------------
// AuthState
// ---------------------------------------------------------------------------

class AuthState {
  final AuthStatus status;
  final UserRole? selectedRole;
  final UserModel? user;
  final String? errorMessage;
  final String? infoMessage;

  const AuthState({
    required this.status,
    this.selectedRole,
    this.user,
    this.errorMessage,
    this.infoMessage,
  });

  factory AuthState.uninitialized() =>
      const AuthState(status: AuthStatus.uninitialized);

  factory AuthState.selectingRole() =>
      const AuthState(status: AuthStatus.selectingRole);

  factory AuthState.unauthenticated({UserRole? role, String? infoMessage}) =>
      AuthState(
        status: AuthStatus.unauthenticated,
        selectedRole: role,
        infoMessage: infoMessage,
      );

  factory AuthState.authenticating({UserRole? role}) =>
      AuthState(status: AuthStatus.authenticating, selectedRole: role);

  factory AuthState.profileLoading({UserRole? role, UserModel? user}) =>
      AuthState(status: AuthStatus.profileLoading, selectedRole: role, user: user);

  /// Creates an [authenticated] state and applies the correct sub-status
  /// based on the profile flags.  The router watches [status] only; it does
  /// NOT inspect [user.role] until [user.roleFinalized] is true.
  factory AuthState.fromProfile(UserModel user) {
    if (user.isSuspended) {
      return AuthState(status: AuthStatus.suspended, user: user);
    }
    return AuthState(
      status: AuthStatus.authenticated,
      selectedRole: user.role,
      user: user,
    );
  }

  factory AuthState.pendingOwnerApproval(UserModel user) => AuthState(
        status: AuthStatus.pendingOwnerApproval,
        selectedRole: UserRole.owner,
        user: user,
      );

  factory AuthState.propertyRegistrationRequired(UserModel user) => AuthState(
        status: AuthStatus.propertyRegistrationRequired,
        selectedRole: UserRole.owner,
        user: user,
      );

  factory AuthState.propertyApprovalPending(UserModel user) => AuthState(
        status: AuthStatus.propertyApprovalPending,
        selectedRole: UserRole.owner,
        user: user,
      );

  factory AuthState.suspended(UserModel user) =>
      AuthState(status: AuthStatus.suspended, user: user);

  factory AuthState.error(String message, {UserRole? role}) =>
      AuthState(status: AuthStatus.error, selectedRole: role, errorMessage: message);
}

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;
  bool _isDisposed = false;

  AuthNotifier(this._repo, this._ref) : super(AuthState.uninitialized()) {
    _listenToSupabaseAuthChanges();
    _init();
  }

  // -------------------------------------------------------------------------
  // Initialisation — restore persisted session on app start
  // -------------------------------------------------------------------------

  Future<void> _init() async {
    final user = await _repo.getCurrentUser();
    if (_isDisposed) return;

    if (user == null) {
      state = AuthState.selectingRole();
      return;
    }

    await _resolveOnboardingState(user);
  }

  /// Evaluates user model and queries pg_profiles to set the precise AuthStatus.
  Future<void> _resolveOnboardingState(UserModel user) async {
    if (user.isSuspended) {
      state = AuthState.suspended(user);
      return;
    }

    if (!user.roleFinalized) {
      state = AuthState.fromProfile(user);
      return;
    }

    if (user.role == UserRole.owner) {
      if (!user.isOwnerEligible) {
        state = AuthState.pendingOwnerApproval(user);
        return;
      }

      // Finalized owner + eligible: query pg_profiles
      state = AuthState.profileLoading(role: UserRole.owner, user: user);
      final pgRepo = _ref.read(pgProfileRepositoryProvider);
      final pgProfile = await pgRepo.fetchOwnerPg(user.id);
      if (_isDisposed) return;

      if (pgProfile == null) {
        state = AuthState.propertyRegistrationRequired(user);
      } else {
        final isApproved = pgProfile['is_approved'] as bool? ?? false;
        if (isApproved) {
          state = AuthState.fromProfile(user);
        } else {
          state = AuthState.propertyApprovalPending(user);
        }
      }
    } else {
      // customer or admin
      state = AuthState.fromProfile(user);
    }
  }

  // -------------------------------------------------------------------------
  // Listen to Supabase auth stream
  // -------------------------------------------------------------------------

  void _listenToSupabaseAuthChanges() {
    if (_repo is! SupabaseAuthRepository) return;

    _authStateSubscription =
        supabase.Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (_isDisposed) return;

      switch (data.event) {
        case supabase.AuthChangeEvent.initialSession:
        case supabase.AuthChangeEvent.signedIn:
        case supabase.AuthChangeEvent.tokenRefreshed:
          if (data.session == null) {
            if (state.status == AuthStatus.uninitialized) {
              state = AuthState.selectingRole();
            }
            return;
          }
          // Avoid overwriting an already-resolved state emitted by the
          // sign-in / sign-up methods (they load the profile themselves).
          if (state.status == AuthStatus.authenticated ||
              state.status == AuthStatus.pendingOwnerApproval ||
              state.status == AuthStatus.propertyRegistrationRequired ||
              state.status == AuthStatus.propertyApprovalPending ||
              state.status == AuthStatus.suspended) {
            return;
          }
          final user = await _repo.getCurrentUser();
          if (_isDisposed || user == null) return;
          await _resolveOnboardingState(user);
          break;

        case supabase.AuthChangeEvent.signedOut:
        case supabase.AuthChangeEvent.userDeleted:
          state = AuthState.selectingRole();
          break;

        case supabase.AuthChangeEvent.passwordRecovery:
        case supabase.AuthChangeEvent.userUpdated:
        case supabase.AuthChangeEvent.mfaChallengeVerified:
          break;
      }
    });
  }

  // -------------------------------------------------------------------------
  // Public actions
  // -------------------------------------------------------------------------

  void selectRole(UserRole role) {
    state = AuthState.unauthenticated(role: role);
  }

  void resetToRoleSelection() {
    state = AuthState.selectingRole();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final currentRole = state.selectedRole ?? UserRole.personal;
    state = AuthState.authenticating(role: currentRole);

    final result = await _repo.signIn(email: email, password: password);
    return switch (result) {
      AuthSuccess(:final user) => () async {
          await _resolveOnboardingState(user);
          return true;
        }(),
      AuthPendingConfirmation(:final message) => () {
          state = AuthState.unauthenticated(
            role: currentRole,
            infoMessage: message,
          );
          return false;
        }(),
      AuthOwnerNotEligible() => () {
          // Should not happen from login, but handle gracefully.
          state = AuthState.error('Role error. Please contact support.', role: currentRole);
          return false;
        }(),
      AuthFailure(:final message) => () {
          state = AuthState.error(message, role: currentRole);
          return false;
        }(),
    };
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? propertyName,
  }) async {
    state = AuthState.authenticating(role: role);

    final result = await _repo.signUp(
      email: email,
      password: password,
      fullName: name,
      role: role,
      phone: phone,
      propertyName: propertyName,
    );

    return switch (result) {
      AuthSuccess(:final user) => () async {
          // Signup succeeded — profile is loaded.
          // role_finalized is ALWAYS false at this point (DB default).
          // The router will see !roleFinalized and send the user to role
          // selection — do NOT call setUserRole here.
          await _resolveOnboardingState(user);
          return true;
        }(),
      AuthPendingConfirmation(:final message) => () {
          state = AuthState.unauthenticated(role: role, infoMessage: message);
          return true;
        }(),
      AuthOwnerNotEligible() => () {
          state = AuthState.error('Role error. Please contact support.', role: role);
          return false;
        }(),
      AuthFailure(:final message) => () {
          state = AuthState.error(message, role: role);
          return false;
        }(),
    };
  }

  Future<bool> signInWithGoogle() async {
    final currentRole = state.selectedRole ?? UserRole.personal;
    state = AuthState.authenticating(role: currentRole);

    try {
      await _repo.signInWithGoogle();
      return true;
    } catch (_) {
      state = AuthState.error(
        'Google sign-in could not be started. Please try again.',
        role: currentRole,
      );
      return false;
    }
  }

  /// Calls the `set_user_role` RPC to finalize the user's chosen role.
  ///
  /// Called explicitly from the Role Selection screen AFTER the user has
  /// a valid session.  Must NOT be called automatically after signup.
  Future<void> setUserRole(UserRole role) async {
    final currentUser = state.user;
    // Show loading while the RPC executes.
    state = AuthState.profileLoading(role: role, user: currentUser);

    final result = await _repo.setUserRole(role);

    switch (result) {
      case AuthSuccess(:final user):
        // role_finalized is now true — route to the appropriate dashboard.
        await _resolveOnboardingState(user);

      case AuthOwnerNotEligible():
        // User is not yet eligible for pg_owner.
        // Keep the profile as-is (role=customer, role_finalized=false) and
        // show the pending approval screen.
        if (currentUser != null) {
          state = AuthState.pendingOwnerApproval(currentUser);
        } else {
          // Fallback: re-fetch profile.
          final user = await _repo.getCurrentUser();
          if (!_isDisposed) {
            state = user != null
                ? AuthState.pendingOwnerApproval(user)
                : AuthState.error('Could not load your profile. Please restart the app.');
          }
        }

      case AuthFailure(:final message):
        state = AuthState.error(message, role: role);

      case AuthPendingConfirmation():
        // setUserRole never returns this — guard for exhaustiveness.
        state = AuthState.error('Unexpected state. Please try again.');
    }
  }

  /// Public API to re-evaluate property registration status
  Future<void> recheckPropertyStatus() async {
    final user = state.user;
    if (user != null) {
      await _resolveOnboardingState(user);
    }
  }

  /// Re-fetches the profile and checks if owner eligibility has been granted.
  /// Used by the "Check Status" button on the pending approval screen.
  Future<void> recheckOwnerEligibility() async {
    final currentUser = state.user;
    state = AuthState.profileLoading(role: UserRole.owner, user: currentUser);

    final user = await _repo.getCurrentUser();
    if (_isDisposed) return;

    if (user == null) {
      state = AuthState.error('Could not load your profile. Please sign in again.');
      return;
    }

    if (user.isOwnerEligible) {
      // Now eligible — finalize the role.
      await setUserRole(UserRole.owner);
    } else {
      // Still pending.
      state = AuthState.pendingOwnerApproval(user);
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = AuthState.selectingRole();
  }

  Future<void> clearAppData() async {
    await _repo.signOut();
    state = AuthState.selectingRole();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_authStateSubscription?.cancel());
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});
