enum DietaryType {
  vegetarian,
  nonVegetarian,
  vegan,
  egg;

  String get displayName {
    switch (this) {
      case DietaryType.vegetarian:
        return 'Pure Veg';
      case DietaryType.nonVegetarian:
        return 'Non-Veg';
      case DietaryType.vegan:
        return 'Vegan';
      case DietaryType.egg:
        return 'Contains Egg';
    }
  }
}

enum ListingStatus {
  active,
  paused,
  soldOut,
  expired,
  removed;

  String get displayName {
    switch (this) {
      case ListingStatus.active:
        return 'Available Now';
      case ListingStatus.paused:
        return 'Paused';
      case ListingStatus.soldOut:
        return 'Sold Out';
      case ListingStatus.expired:
        return 'Pickup Closed';
      case ListingStatus.removed:
        return 'Removed';
    }
  }
}

class FoodListingModel {
  final String id;
  final String pgId;
  final String pgName;
  final String title;
  final String description;
  final String category; // Breakfast, Lunch, Dinner, Snacks
  final String imageUrl;
  final double originalPrice;
  final double discountedPrice; // The ExtraBite price payable at pickup
  final int totalPortions;
  final int availablePortions;
  final DietaryType dietaryType;
  final List<String> allergens;
  final DateTime pickupStartTime;
  final DateTime pickupEndTime;
  final String pickupInstructions;
  final String address;
  final String neighborhood;
  final double latitude;
  final double longitude;
  final ListingStatus status;
  final bool isFeatured;
  final double rating;
  final DateTime createdAt;

  const FoodListingModel({
    required this.id,
    required this.pgId,
    required this.pgName,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
    required this.totalPortions,
    required this.availablePortions,
    required this.dietaryType,
    this.allergens = const [],
    required this.pickupStartTime,
    required this.pickupEndTime,
    required this.pickupInstructions,
    required this.address,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
    this.status = ListingStatus.active,
    this.isFeatured = false,
    this.rating = 4.8,
    required this.createdAt,
  });

  bool get isAvailable =>
      status == ListingStatus.active &&
      availablePortions > 0 &&
      DateTime.now().isBefore(pickupEndTime);

  bool get isSoldOut => availablePortions <= 0 || status == ListingStatus.soldOut;

  bool get isPickupWindowActive {
    final now = DateTime.now();
    return now.isAfter(pickupStartTime) && now.isBefore(pickupEndTime);
  }

  int get savingsPercentage {
    if (originalPrice <= 0) return 0;
    final diff = originalPrice - discountedPrice;
    return ((diff / originalPrice) * 100).round();
  }

  FoodListingModel copyWith({
    String? id,
    String? pgId,
    String? pgName,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    double? originalPrice,
    double? discountedPrice,
    int? totalPortions,
    int? availablePortions,
    DietaryType? dietaryType,
    List<String>? allergens,
    DateTime? pickupStartTime,
    DateTime? pickupEndTime,
    String? pickupInstructions,
    String? address,
    String? neighborhood,
    double? latitude,
    double? longitude,
    ListingStatus? status,
    bool? isFeatured,
    double? rating,
    DateTime? createdAt,
  }) {
    return FoodListingModel(
      id: id ?? this.id,
      pgId: pgId ?? this.pgId,
      pgName: pgName ?? this.pgName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      totalPortions: totalPortions ?? this.totalPortions,
      availablePortions: availablePortions ?? this.availablePortions,
      dietaryType: dietaryType ?? this.dietaryType,
      allergens: allergens ?? this.allergens,
      pickupStartTime: pickupStartTime ?? this.pickupStartTime,
      pickupEndTime: pickupEndTime ?? this.pickupEndTime,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      address: address ?? this.address,
      neighborhood: neighborhood ?? this.neighborhood,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pg_id': pgId,
        'pg_name': pgName,
        'title': title,
        'description': description,
        'category': category,
        'image_url': imageUrl,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'total_portions': totalPortions,
        'available_portions': availablePortions,
        'dietary_type': dietaryType.name,
        'allergens': allergens,
        'pickup_start_time': pickupStartTime.toIso8601String(),
        'pickup_end_time': pickupEndTime.toIso8601String(),
        'pickup_instructions': pickupInstructions,
        'address': address,
        'neighborhood': neighborhood,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'is_featured': isFeatured,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
      };

  factory FoodListingModel.fromJson(Map<String, dynamic> json) {
    return FoodListingModel(
      id: json['id'] as String,
      pgId: json['pg_id'] as String,
      pgName: json['pg_name'] as String? ?? 'Nearby PG',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Meal',
      imageUrl: json['image_url'] as String? ?? '',
      originalPrice: (json['original_price'] as num).toDouble(),
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      totalPortions: json['total_portions'] as int,
      availablePortions: json['available_portions'] as int,
      dietaryType: DietaryType.values.firstWhere(
        (e) => e.name == json['dietary_type'],
        orElse: () => DietaryType.vegetarian,
      ),
      allergens: List<String>.from(json['allergens'] ?? []),
      pickupStartTime: DateTime.parse(json['pickup_start_time'] as String),
      pickupEndTime: DateTime.parse(json['pickup_end_time'] as String),
      pickupInstructions: json['pickup_instructions'] as String? ?? '',
      address: json['address'] as String? ?? '',
      neighborhood: json['neighborhood'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: ListingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ListingStatus.active,
      ),
      isFeatured: json['is_featured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
