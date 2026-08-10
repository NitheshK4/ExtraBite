enum UserRole {
  customer,
  pgOwner,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.pgOwner:
        return 'PG Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
