class PgProfile {
  final String id;
  final String ownerId;
  final String pgName;
  final String? description;
  final String address;
  final String neighborhood;
  final String city;
  final double latitude;
  final double longitude;
  final String contactPhone;
  final String? fssaiLicenseNumber;
  final bool isApproved;
  final bool isActive;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? ownerName;
  final String? ownerEmail;

  PgProfile({
    required this.id,
    required this.ownerId,
    required this.pgName,
    this.description,
    required this.address,
    required this.neighborhood,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    this.fssaiLicenseNumber,
    required this.isApproved,
    required this.isActive,
    this.imageUrl,
    this.createdAt,
    this.ownerName,
    this.ownerEmail,
  });

  factory PgProfile.fromJson(Map<String, dynamic> json) {
    final ownerProfile = json['profiles'] as Map<String, dynamic>?;
    return PgProfile(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      pgName: json['pg_name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      neighborhood: json['neighborhood'] as String? ?? '',
      city: json['city'] as String? ?? 'Bengaluru',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      contactPhone: (json['contact_phone'] as String?) ?? (json['phone'] as String?) ?? '',
      fssaiLicenseNumber: json['fssai_license_number'] as String?,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      ownerName: ownerProfile != null ? ownerProfile['full_name'] as String? : null,
      ownerEmail: ownerProfile != null ? ownerProfile['email'] as String? : null,
    );
  }
}
