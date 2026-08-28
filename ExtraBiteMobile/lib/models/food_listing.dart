class FoodListing {
  final String id;
  final String foodName;
  final String description;
  final String propertyId;
  final String propertyName;
  final String locationAddress;
  final double distanceKm;
  final String category;
  final bool isVegetarian;
  final double originalPrice;
  final double sellingPrice;
  final int availablePortions;
  final DateTime preparedTime;
  final DateTime pickupStarts;
  final DateTime pickupEnds;
  final List<String> ingredients;
  final List<String> allergens;
  final String verificationStatus; // e.g. "verified", "unverified"

  final double latitude;
  final double longitude;

  // New fields mapping to Supabase
  final String? imageUrl;
  final int totalPortions;
  final String? pgId;
  final String status;
  final String dietaryType; // 'vegetarian', 'non_vegetarian', 'vegan', 'egg'

  FoodListing({
    required this.id,
    required this.foodName,
    required this.description,
    required this.propertyId,
    required this.propertyName,
    this.locationAddress = 'Near VIT-AP University',
    required this.distanceKm,
    required this.category,
    required this.isVegetarian,
    required this.originalPrice,
    required this.sellingPrice,
    required this.availablePortions,
    required this.preparedTime,
    required this.pickupStarts,
    required this.pickupEnds,
    required this.ingredients,
    required this.allergens,
    required this.verificationStatus,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    int? totalPortions,
    this.pgId,
    this.status = 'active',
    String? dietaryType,
  })  : totalPortions = totalPortions ?? availablePortions,
        dietaryType = dietaryType ?? (isVegetarian ? 'vegetarian' : 'non_vegetarian');

  double get discountPercentage {
    if (originalPrice <= 0) return 0;
    final discount = originalPrice - sellingPrice;
    return ((discount / originalPrice) * 100).clamp(0, 100);
  }

  bool get isExpired {
    return DateTime.now().isAfter(pickupEnds);
  }

  bool get isPickupActive {
    final now = DateTime.now();
    return now.isAfter(pickupStarts) && now.isBefore(pickupEnds);
  }

  factory FoodListing.fromSupabase(Map<String, dynamic> row, Map<String, dynamic> pgRow) {
    final isVeg = (row['dietary_type'] as String?) == 'vegetarian' ||
        (row['dietary_type'] as String?) == 'vegan';
    
    return FoodListing(
      id: row['id'] as String,
      foodName: (row['title'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      propertyId: (pgRow['owner_id'] as String?) ?? '',
      propertyName: (pgRow['pg_name'] as String?) ?? 'ExtraBite PG',
      locationAddress: (pgRow['address'] as String?) ?? 'Near VIT-AP University',
      distanceKm: 0.0, // Computed dynamically by customer provider
      category: (row['category'] as String?) ?? 'Lunch',
      isVegetarian: isVeg,
      originalPrice: double.tryParse(row['original_price']?.toString() ?? '0') ?? 0.0,
      sellingPrice: double.tryParse(row['discounted_price']?.toString() ?? '0') ?? 0.0,
      availablePortions: (row['available_portions'] as num?)?.toInt() ?? 0,
      totalPortions: (row['total_portions'] as num?)?.toInt() ?? 0,
      preparedTime: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      pickupStarts: DateTime.tryParse(row['pickup_start_time']?.toString() ?? '') ?? DateTime.now(),
      pickupEnds: DateTime.tryParse(row['pickup_end_time']?.toString() ?? '') ?? DateTime.now(),
      ingredients: List<String>.from(row['ingredients'] ?? const []),
      allergens: List<String>.from(row['allergens'] ?? const []),
      verificationStatus: (pgRow['is_approved'] as bool? ?? false) ? 'verified' : 'unverified',
      latitude: double.tryParse(pgRow['latitude']?.toString() ?? '16.4971') ?? 16.4971,
      longitude: double.tryParse(pgRow['longitude']?.toString() ?? '80.5005') ?? 80.5005,
      imageUrl: row['image_url'] as String?,
      pgId: row['pg_id'] as String?,
      status: (row['status'] as String?) ?? 'active',
      dietaryType: (row['dietary_type'] as String?) ?? 'vegetarian',
    );
  }

  FoodListing copyWith({
    double? distanceKm,
    int? availablePortions,
  }) {
    return FoodListing(
      id: id,
      foodName: foodName,
      description: description,
      propertyId: propertyId,
      propertyName: propertyName,
      locationAddress: locationAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      category: category,
      isVegetarian: isVegetarian,
      originalPrice: originalPrice,
      sellingPrice: sellingPrice,
      availablePortions: availablePortions ?? this.availablePortions,
      preparedTime: preparedTime,
      pickupStarts: pickupStarts,
      pickupEnds: pickupEnds,
      ingredients: ingredients,
      allergens: allergens,
      verificationStatus: verificationStatus,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      totalPortions: totalPortions,
      pgId: pgId,
      status: status,
      dietaryType: dietaryType,
    );
  }
}

