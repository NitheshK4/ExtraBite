class FoodListing {
  final String id;
  final String title;
  final String pgName;
  final String description;
  final int availablePortions;
  final int totalPortions;
  final double originalPrice;
  final double pickupPrice; // Pay at pickup price
  final bool isVeg;
  final String category; // Breakfast, Lunch, Dinner, Snacks
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String imageUrl;
  final bool isAvailable;

  FoodListing({
    required this.id,
    required this.title,
    required this.pgName,
    required this.description,
    required this.availablePortions,
    required this.totalPortions,
    required this.originalPrice,
    required this.pickupPrice,
    required this.isVeg,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    required this.expiresAt,
    required this.imageUrl,
    this.isAvailable = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  FoodListing copyWith({
    String? id,
    String? title,
    String? pgName,
    String? description,
    int? availablePortions,
    int? totalPortions,
    double? originalPrice,
    double? pickupPrice,
    bool? isVeg,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return FoodListing(
      id: id ?? this.id,
      title: title ?? this.title,
      pgName: pgName ?? this.pgName,
      description: description ?? this.description,
      availablePortions: availablePortions ?? this.availablePortions,
      totalPortions: totalPortions ?? this.totalPortions,
      originalPrice: originalPrice ?? this.originalPrice,
      pickupPrice: pickupPrice ?? this.pickupPrice,
      isVeg: isVeg ?? this.isVeg,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
