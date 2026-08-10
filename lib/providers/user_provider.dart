import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';

class UserState {
  final UserRole currentRole;
  final String userName;
  final String userPhone;
  final String pgName;

  UserState({
    required this.currentRole,
    required this.userName,
    required this.userPhone,
    required this.pgName,
  });

  UserState copyWith({
    UserRole? currentRole,
    String? userName,
    String? userPhone,
    String? pgName,
  }) {
    return UserState(
      currentRole: currentRole ?? this.currentRole,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      pgName: pgName ?? this.pgName,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier()
      : super(UserState(
          currentRole: UserRole.customer,
          userName: 'Alex Kumar',
          userPhone: '+91 98765 43210',
          pgName: 'Sunrise Executive PG',
        ));

  void switchRole(UserRole role) {
    state = state.copyWith(currentRole: role);
  }

  void updateProfile({String? name, String? phone, String? pgName}) {
    state = state.copyWith(
      userName: name,
      userPhone: phone,
      pgName: pgName,
    );
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
