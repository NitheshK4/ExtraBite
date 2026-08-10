import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

enum AuthStatus {
  uninitialized,
  selectingRole,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserRole? selectedRole;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.selectedRole,
    this.user,
    this.errorMessage,
  });

  factory AuthState.uninitialized() => const AuthState(status: AuthStatus.uninitialized);
  factory AuthState.selectingRole() => const AuthState(status: AuthStatus.selectingRole);
  factory AuthState.unauthenticated({UserRole? role}) =>
      AuthState(status: AuthStatus.unauthenticated, selectedRole: role);
  factory AuthState.authenticating({UserRole? role}) =>
      AuthState(status: AuthStatus.authenticating, selectedRole: role);
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, selectedRole: user.role, user: user);
  factory AuthState.error(String message, {UserRole? role}) =>
      AuthState(status: AuthStatus.error, selectedRole: role, errorMessage: message);

  AuthState copyWith({
    AuthStatus? status,
    UserRole? selectedRole,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      selectedRole: selectedRole ?? this.selectedRole,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  // In-memory store for registered users to simulate backend DB keyed by ID / email
  static final Map<String, UserModel> _registeredUsers = {};
  static final Map<String, String> _userPasswords = {};

  AuthNotifier() : super(AuthState.uninitialized()) {
    _init();
  }

  void _init() {
    // Fresh launch starts at selectingRole if no authenticated session exists.
    // Zero hardcoded developer profile data ("Pavan Kumar")!
    state = AuthState.selectingRole();
  }

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

    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = email.trim().toLowerCase();
    final user = _registeredUsers[normalizedEmail];
    final storedPass = _userPasswords[normalizedEmail];

    if (user != null && storedPass == password) {
      state = AuthState.authenticated(user);
      return true;
    } else if (user != null && storedPass != password) {
      state = AuthState.error('Invalid password. Please try again.', role: currentRole);
      return false;
    }

    // Auto-create unique user session for fresh credentials (simulating auth backend registration)
    final newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final nameFromEmail = email.split('@').first;
    final formattedName = nameFromEmail.isNotEmpty
        ? nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1)
        : 'User';

    final newUser = UserModel(
      id: newId,
      name: formattedName,
      email: normalizedEmail,
      phone: '+91 9000000000',
      role: currentRole,
      propertyName: currentRole == UserRole.owner ? '$formattedName PG' : null,
    );

    _registeredUsers[normalizedEmail] = newUser;
    _userPasswords[normalizedEmail] = password;

    state = AuthState.authenticated(newUser);
    return true;
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

    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = email.trim().toLowerCase();
    final newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    final newUser = UserModel(
      id: newId,
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      role: role,
      propertyName: propertyName?.trim(),
    );

    _registeredUsers[normalizedEmail] = newUser;
    _userPasswords[normalizedEmail] = password;

    state = AuthState.authenticated(newUser);
    return true;
  }

  Future<void> logout() async {
    // Completely clear memory session, cached profile data, and navigation state
    state = AuthState.selectingRole();
  }

  Future<void> clearAppData() async {
    // Purge all stored accounts, memory caches, and session state
    _registeredUsers.clear();
    _userPasswords.clear();
    state = AuthState.selectingRole();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
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
