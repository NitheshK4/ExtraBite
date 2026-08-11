import 'dart:math' as math;

class FoodListing {
  final String id;
  final String foodName;
  final String description;
  final String propertyId;
  final String propertyName;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final double distanceMeters;
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

  FoodListing({
    required this.id,
    required this.foodName,
    required this.description,
    required this.propertyId,
    required this.propertyName,
    this.locationAddress = 'Near VIT-AP University',
    this.latitude = 16.4950,
    this.longitude = 80.5000,
    required this.distanceKm,
    double? distanceMeters,
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
  }) : distanceMeters = distanceMeters ?? (distanceKm * 1000.0);

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

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  FoodListing copyWith({
    String? id,
    String? foodName,
    String? description,
    String? propertyId,
    String? propertyName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    double? distanceKm,
    double? distanceMeters,
    String? category,
    bool? isVegetarian,
    double? originalPrice,
    double? sellingPrice,
    int? availablePortions,
    DateTime? preparedTime,
    DateTime? pickupStarts,
    DateTime? pickupEnds,
    List<String>? ingredients,
    List<String>? allergens,
    String? verificationStatus,
  }) {
    return FoodListing(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      description: description ?? this.description,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      category: category ?? this.category,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      originalPrice: originalPrice ?? this.originalPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      availablePortions: availablePortions ?? this.availablePortions,
      preparedTime: preparedTime ?? this.preparedTime,
      pickupStarts: pickupStarts ?? this.pickupStarts,
      pickupEnds: pickupEnds ?? this.pickupEnds,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  /// Calculates Haversine distance in meters between two GPS coordinates
  static double calculateHaversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusM = 6371000.0;
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  /// Calculates Haversine distance in kilometers between two GPS coordinates
  static double calculateHaversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateHaversineDistanceMeters(lat1, lon1, lat2, lon2) / 1000.0;
  }
}
