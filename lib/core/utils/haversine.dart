import 'dart:math' as math;

/// Utility for precise Earth surface distance calculations using the Haversine formula.
class Haversine {
  static const double earthRadiusKm = 6371.0;

  /// Calculates the great-circle distance between two geographic coordinates in kilometers.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) *
            math.cos(rLat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Calculates distance in meters.
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateDistanceKm(lat1, lon1, lat2, lon2) * 1000.0;
  }

  /// Checks if point (lat2, lon2) is within [radiusKm] of point (lat1, lon1).
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusKm,
  ) {
    final distance = calculateDistanceKm(lat1, lon1, lat2, lon2);
    return distance <= radiusKm;
  }

  /// Formats the distance into human readable string (e.g. "450 m" or "1.8 km").
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
