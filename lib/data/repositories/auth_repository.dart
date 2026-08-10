import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../demo/seed_data.dart';

class AuthState {
  final UserModel? currentUser;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? currentUser,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
          currentUser: SeedData.demoCustomer,
          isAuthenticated: true,
        ));

  /// Switches active role for demo exploration (Customer, PG Owner, Admin)
  void switchDemoRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        state = state.copyWith(
          currentUser: SeedData.demoCustomer,
          isAuthenticated: true,
        );
        break;
      case UserRole.pgOwner:
        state = state.copyWith(
          currentUser: SeedData.demoPgOwner,
          isAuthenticated: true,
        );
        break;
      case UserRole.admin:
        state = state.copyWith(
          currentUser: SeedData.demoAdmin,
          isAuthenticated: true,
        );
        break;
    }
  }

  void updateProfile({
    required String fullName,
    required String phoneNumber,
    List<String>? dietaryPreferences,
  }) {
    if (state.currentUser == null) return;
    final updated = state.currentUser!.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      dietaryPreferences: dietaryPreferences,
    );
    state = state.copyWith(currentUser: updated);
  }

  void signOut() {
    state = const AuthState(currentUser: null, isAuthenticated: false);
  }

  void signIn(String email, String password, UserRole role) {
    switchDemoRole(role);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
