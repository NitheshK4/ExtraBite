class AdminFoodListing {
  final String id;
  final String pgId;
  final String pgName;
  final String ownerName;
  final String title;
  final String? description;
  final String category;
  final String? imageUrl;
  final double originalPrice;
  final double discountedPrice;
  final int totalPortions;
  final int availablePortions;
  final String dietaryType;
  final DateTime pickupStartTime;
  final DateTime pickupEndTime;
  final String status;
  final bool isFeatured;
  final DateTime createdAt;

  AdminFoodListing({
    required this.id,
    required this.pgId,
    required this.pgName,
    required this.ownerName,
    required this.title,
    this.description,
    required this.category,
    this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
    required this.totalPortions,
    required this.availablePortions,
    required this.dietaryType,
    required this.pickupStartTime,
    required this.pickupEndTime,
    required this.status,
    this.isFeatured = false,
    required this.createdAt,
  });

  bool get isVegetarian => dietaryType.toLowerCase() == 'vegetarian' || dietaryType.toLowerCase() == 'vegan';
  bool get isExpired => DateTime.now().isAfter(pickupEndTime);
  double get discountPercentage => originalPrice > 0 ? ((originalPrice - discountedPrice) / originalPrice) * 100 : 0;

  factory AdminFoodListing.fromJson(Map<String, dynamic> json) {
    final pgProfile = json['pg_profiles'] as Map<String, dynamic>?;
    final pgName = pgProfile != null ? (pgProfile['pg_name'] as String? ?? 'Hostel Mess') : 'Hostel Mess';
    final ownerProfile = pgProfile?['profiles'] as Map<String, dynamic>?;
    final ownerName = ownerProfile != null ? (ownerProfile['full_name'] as String? ?? 'PG Host') : 'PG Host';

    return AdminFoodListing(
      id: json['id'] as String,
      pgId: json['pg_id'] as String? ?? '',
      pgName: pgName,
      ownerName: ownerName,
      title: json['title'] as String? ?? 'Surplus Food Meal',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'Dinner',
      imageUrl: json['image_url'] as String?,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 50.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? 25.0,
      totalPortions: (json['total_portions'] as num?)?.toInt() ?? 1,
      availablePortions: (json['available_portions'] as num?)?.toInt() ?? 0,
      dietaryType: json['dietary_type'] as String? ?? 'vegetarian',
      pickupStartTime: json['pickup_start_time'] != null
          ? DateTime.parse(json['pickup_start_time'] as String)
          : DateTime.now(),
      pickupEndTime: json['pickup_end_time'] != null
          ? DateTime.parse(json['pickup_end_time'] as String)
          : DateTime.now().add(const Duration(hours: 3)),
      status: json['status'] as String? ?? 'active',
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
