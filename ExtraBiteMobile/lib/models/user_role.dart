enum UserRole {
  owner,
  personal,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Hostel / PG Owner';
      case UserRole.personal:
        return 'Personal User';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.owner:
        return 'List surplus meals, manage properties, and verify pickup reservations.';
      case UserRole.personal:
        return 'Discover and reserve surplus meals from nearby PGs & messes.';
      case UserRole.admin:
        return 'Manage the ExtraBite platform.';
    }
  }
}
