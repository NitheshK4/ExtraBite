import 'dart:math';

class Haversine {
  const Haversine._();

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return r * c; // Distance in kilometers
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}
