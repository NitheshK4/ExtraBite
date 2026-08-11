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

  FoodListing copyWith({
    double? distanceKm,
  }) {
    return FoodListing(
      id: id,
      foodName: foodName,
      description: description,
      propertyId: propertyId,
      propertyName: propertyName,
      distanceKm: distanceKm ?? this.distanceKm,
      category: category,
      isVegetarian: isVegetarian,
      originalPrice: originalPrice,
      sellingPrice: sellingPrice,
      availablePortions: availablePortions,
      preparedTime: preparedTime,
      pickupStarts: pickupStarts,
      pickupEnds: pickupEnds,
      ingredients: ingredients,
      allergens: allergens,
      verificationStatus: verificationStatus,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
