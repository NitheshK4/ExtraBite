class PgProfileModel {
  final String id;
  final String ownerId;
  final String pgName;
  final String description;
  final String address;
  final String neighborhood;
  final String city;
  final double latitude;
  final double longitude;
  final String contactPhone;
  final String? fssaiLicenseNumber;
  final bool isApproved;
  final bool isActive;
  final double rating;
  final int totalReviews;
  final int mealsRescuedCount;
  final double totalRevenueCollected;

  const PgProfileModel({
    required this.id,
    required this.ownerId,
    required this.pgName,
    required this.description,
    required this.address,
    required this.neighborhood,
    this.city = 'Bengaluru',
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    this.fssaiLicenseNumber,
    this.isApproved = true,
    this.isActive = true,
    this.rating = 4.8,
    this.totalReviews = 24,
    this.mealsRescuedCount = 142,
    this.totalRevenueCollected = 7850.0,
  });

  PgProfileModel copyWith({
    String? id,
    String? ownerId,
    String? pgName,
    String? description,
    String? address,
    String? neighborhood,
    String? city,
    double? latitude,
    double? longitude,
    String? contactPhone,
    String? fssaiLicenseNumber,
    bool? isApproved,
    bool? isActive,
    double? rating,
    int? totalReviews,
    int? mealsRescuedCount,
    double? totalRevenueCollected,
  }) {
    return PgProfileModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      pgName: pgName ?? this.pgName,
      description: description ?? this.description,
      address: address ?? this.address,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactPhone: contactPhone ?? this.contactPhone,
      fssaiLicenseNumber: fssaiLicenseNumber ?? this.fssaiLicenseNumber,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      mealsRescuedCount: mealsRescuedCount ?? this.mealsRescuedCount,
      totalRevenueCollected: totalRevenueCollected ?? this.totalRevenueCollected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'pg_name': pgName,
        'description': description,
        'address': address,
        'neighborhood': neighborhood,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'contact_phone': contactPhone,
        'fssai_license_number': fssaiLicenseNumber,
        'is_approved': isApproved,
        'is_active': isActive,
        'rating': rating,
        'total_reviews': totalReviews,
        'meals_rescued_count': mealsRescuedCount,
        'total_revenue_collected': totalRevenueCollected,
      };

  factory PgProfileModel.fromJson(Map<String, dynamic> json) {
    return PgProfileModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      pgName: json['pg_name'] as String,
      description: json['description'] as String? ?? '',
      address: json['address'] as String,
      neighborhood: json['neighborhood'] as String? ?? 'Bengaluru Central',
      city: json['city'] as String? ?? 'Bengaluru',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      contactPhone: json['contact_phone'] as String? ?? '',
      fssaiLicenseNumber: json['fssai_license_number'] as String?,
      isApproved: json['is_approved'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalReviews: json['total_reviews'] as int? ?? 0,
      mealsRescuedCount: json['meals_rescued_count'] as int? ?? 0,
      totalRevenueCollected: (json['total_revenue_collected'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
