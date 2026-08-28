enum UserRole {
  personal,
  owner,
  admin;

  String get displayName => switch (this) {
        UserRole.personal => 'Personal User',
        UserRole.owner => 'PG Owner',
        UserRole.admin => 'Admin',
      };
}
