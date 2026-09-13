import '../../models/user_model.dart';
import '../../models/user_role.dart';
import 'auth_repository.dart';

/// In-memory [AuthRepository] implementation for use in tests.
///
/// Mirrors the original `AuthNotifier` in-memory logic exactly so that all
/// existing tests continue to pass without any network access.
class FakeAuthRepository implements AuthRepository {
  final Map<String, UserModel> _users = {};
  final Map<String, String> _passwords = {};
  UserModel? _currentUser;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String phone,
    String? propertyName,
  }) async {
    // Minimal fake delay to simulate async operation
    await Future<void>.delayed(const Duration(milliseconds: 1));

    final normalizedEmail = email.trim().toLowerCase();
    final id = 'fake_usr_${DateTime.now().millisecondsSinceEpoch}';

    // Mirrors DB: new users always start as customer, role_finalized = false.
    final user = UserModel(
      id: id,
      name: fullName.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      role: UserRole.personal,
      propertyName: propertyName?.trim(),
      roleFinalized: false,
      isOwnerEligible: false,
      isSuspended: false,
    );

    _users[normalizedEmail] = user;
    _passwords[normalizedEmail] = password;
    _currentUser = user;

    return AuthSuccess(user);
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));

    final normalizedEmail = email.trim().toLowerCase();
    final user = _users[normalizedEmail];
    final storedPass = _passwords[normalizedEmail];

    if (user != null && storedPass == password) {
      _currentUser = user;
      return AuthSuccess(user);
    }

    if (user != null && storedPass != password) {
      return const AuthFailure('Invalid password. Please try again.');
    }

    // Auto-create user for unknown credentials (mirrors original behavior for
    // widget tests that log in without signing up first).
    final nameFromEmail = email.split('@').first;
    final formattedName = nameFromEmail.isNotEmpty
        ? nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1)
        : 'User';

    final newId = 'fake_usr_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      id: newId,
      name: formattedName,
      email: normalizedEmail,
      phone: '+91 9000000000',
      role: UserRole.personal,
      roleFinalized: false,
      isOwnerEligible: false,
      isSuspended: false,
    );

    _users[normalizedEmail] = newUser;
    _passwords[normalizedEmail] = password;
    _currentUser = newUser;

    return AuthSuccess(newUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    // No-op in fake — state is managed by the notifier
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // No persisted session in fake
    return null;
  }

  @override
  Future<AuthResult> setUserRole(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (_currentUser == null) {
      return const AuthFailure('No active session.');
    }

    if (role == UserRole.owner && !_currentUser!.isOwnerEligible) {
      return const AuthOwnerNotEligible();
    }

    final updated = _currentUser!.copyWith(
      role: role,
      roleFinalized: true,
    );
    _users[_currentUser!.email] = updated;
    _currentUser = updated;
    return AuthSuccess(updated);
  }

  /// Helper for tests: make the current user owner-eligible.
  void makeOwnerEligible() {
    if (_currentUser != null) {
      final updated = _currentUser!.copyWith(isOwnerEligible: true);
      _users[_currentUser!.email] = updated;
      _currentUser = updated;
    }
  }

  /// Clears all registered users — used by `clearAppData()`.
  void clearAll() {
    _users.clear();
    _passwords.clear();
    _currentUser = null;
  }
}
