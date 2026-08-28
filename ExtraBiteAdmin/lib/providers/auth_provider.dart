import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../core/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

enum AuthStatus {
  uninitialized,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.uninitialized() => const AuthState(status: AuthStatus.uninitialized);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.authenticating() => const AuthState(status: AuthStatus.authenticating);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AdminRepository _repo;
  final supabase.SupabaseClient _client;
  StreamSubscription<supabase.AuthState>? _subscription;

  AuthNotifier(this._repo, [supabase.SupabaseClient? client])
      : _client = client ?? supabase.Supabase.instance.client,
        super(AuthState.uninitialized()) {
    _listenToAuthChanges();
    checkCurrentSession();
  }

  void _listenToAuthChanges() {
    _subscription = _client.auth.onAuthStateChange.listen((data) async {
      if (data.event == supabase.AuthChangeEvent.signedOut) {
        state = AuthState.unauthenticated();
      }
    });
  }

  Future<void> checkCurrentSession() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final userModel = await _fetchAndVerifyAdmin(session.user.id);
      if (userModel != null) {
        state = AuthState.authenticated(userModel);
      } else {
        await _repo.signOut();
        state = AuthState.error('Admin access required');
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = AuthState.authenticating();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.session == null || response.user == null) {
        state = AuthState.error('Sign-in failed. Please try again.');
        return false;
      }

      final userModel = await _fetchAndVerifyAdmin(response.user!.id);
      if (userModel != null) {
        state = AuthState.authenticated(userModel);
        return true;
      } else {
        await _repo.signOut();
        state = AuthState.error('Admin access required');
        return false;
      }
    } on supabase.AuthException catch (e) {
      state = AuthState.error(_mapAuthError(e.message));
      return false;
    } catch (_) {
      state = AuthState.error('Connection error. Please try again.');
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = AuthState.unauthenticated();
  }

  Future<UserModel?> _fetchAndVerifyAdmin(String userId) async {
    final Map<String, dynamic> profile = await _client.from('profiles').select().eq('id', userId).single();
    
    // Check role from profiles table
    if (profile['role'] == 'admin') {
      return UserModel(
        id: profile['id'] as String,
        name: (profile['full_name'] as String?) ?? '',
        email: (profile['email'] as String?) ?? '',
        phone: (profile['phone_number'] as String?) ?? '',
        role: UserRole.admin,
        roleFinalized: (profile['role_finalized'] as bool?) ?? false,
        isOwnerEligible: (profile['is_owner_eligible'] as bool?) ?? false,
        isSuspended: (profile['is_suspended'] as bool?) ?? false,
      );
    }
    return null;
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return message;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(adminRepositoryProvider);
  return AuthNotifier(repo);
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
