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
  final String status; // e.g. "active", "paused", "sold_out", "expired", "removed", "draft"
  final bool allowsDineIn; // whether students can dine-in at the PG or takeaway only

  final double latitude;
  final double longitude;

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
    this.status = 'active',
    this.allowsDineIn = true,
    required this.latitude,
    required this.longitude,
  });

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

  bool get isActive {
    return status == 'active';
  }

  bool get isAvailable {
    return isActive && availablePortions > 0 && !isExpired && verificationStatus == 'verified';
  }

  FoodListing copyWith({
    double? distanceKm,
    int? availablePortions,
    String? status,
    bool? allowsDineIn,
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
      status: status ?? this.status,
      allowsDineIn: allowsDineIn ?? this.allowsDineIn,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': foodName,
      'description': description,
      'pg_id': propertyId,
      'propertyName': propertyName,
      'locationAddress': locationAddress,
      'distanceKm': distanceKm,
      'category': category,
      'dietary_type': isVegetarian ? 'vegetarian' : 'non_vegetarian',
      'original_price': originalPrice,
      'discounted_price': sellingPrice,
      'available_portions': availablePortions,
      'preparedTime': preparedTime.toIso8601String(),
      'pickup_start_time': pickupStarts.toIso8601String(),
      'pickup_end_time': pickupEnds.toIso8601String(),
      'ingredients': ingredients,
      'allergens': allergens,
      'verificationStatus': verificationStatus,
      'status': status,
      'allows_dine_in': allowsDineIn,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory FoodListing.fromMap(Map<String, dynamic> map) {
    final isVeg = (map['dietary_type'] as String? ?? 'vegetarian') == 'vegetarian' ||
        (map['isVegetarian'] as bool? ?? true);
    final origPrice = (map['original_price'] as num? ?? map['originalPrice'] as num? ?? 100.0).toDouble();
    final discPrice = (map['discounted_price'] as num? ?? map['sellingPrice'] as num? ?? 50.0).toDouble();
    final dineInOption = map['allows_dine_in'] as bool? ??
        map['isDineInAvailable'] as bool? ??
        map['allowsDineIn'] as bool? ??
        true;

    return FoodListing(
      id: map['id'] as String? ?? '',
      foodName: map['title'] as String? ?? map['foodName'] as String? ?? 'Surplus Meal',
      description: map['description'] as String? ?? '',
      propertyId: map['pg_id'] as String? ?? map['propertyId'] as String? ?? '',
      propertyName: map['propertyName'] as String? ?? map['pg_name'] as String? ?? 'PG / Hostel',
      locationAddress: map['locationAddress'] as String? ?? 'Near VIT-AP University',
      distanceKm: (map['distanceKm'] as num? ?? 0.8).toDouble(),
      category: map['category'] as String? ?? 'Lunch',
      isVegetarian: isVeg,
      originalPrice: origPrice,
      sellingPrice: discPrice,
      availablePortions: (map['available_portions'] as num? ?? map['availablePortions'] as num? ?? 0).toInt(),
      preparedTime: map['preparedTime'] != null
          ? DateTime.parse(map['preparedTime'] as String)
          : DateTime.now().subtract(const Duration(minutes: 30)),
      pickupStarts: map['pickup_start_time'] != null
          ? DateTime.parse(map['pickup_start_time'] as String)
          : map['pickupStarts'] != null
              ? DateTime.parse(map['pickupStarts'] as String)
              : DateTime.now(),
      pickupEnds: map['pickup_end_time'] != null
          ? DateTime.parse(map['pickup_end_time'] as String)
          : map['pickupEnds'] != null
              ? DateTime.parse(map['pickupEnds'] as String)
              : DateTime.now().add(const Duration(hours: 2)),
      ingredients: (map['ingredients'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      allergens: (map['allergens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      verificationStatus: map['verificationStatus'] as String? ?? 'verified',
      status: map['status'] as String? ?? 'active',
      allowsDineIn: dineInOption,
      latitude: (map['latitude'] as num? ?? 16.4971).toDouble(),
      longitude: (map['longitude'] as num? ?? 80.5005).toDouble(),
    );
  }
}

