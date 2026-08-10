import 'package:flutter_test/flutter_test.dart';
import 'package:extrabite_mobile/core/utils/haversine.dart';

void main() {
  group('Haversine Distance Tests', () {
    // Benchmark: Bengaluru Central (12.9716, 77.5946)
    const lat1 = 12.9716;
    const lon1 = 77.5946;

    test('Distance between identical coordinates is zero', () {
      final distance = Haversine.calculateDistanceKm(lat1, lon1, lat1, lon1);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('Calculates accurate straight-line distance in km and meters', () {
      // Nearby point (~0.5 km away)
      const lat2 = 12.9750;
      const lon2 = 77.5970;

      final distKm = Haversine.calculateDistanceKm(lat1, lon1, lat2, lon2);
      final distM = Haversine.calculateDistanceMeters(lat1, lon1, lat2, lon2);

      expect(distKm, greaterThan(0.3));
      expect(distKm, lessThan(0.7));
      expect(distM, closeTo(distKm * 1000, 0.01));
    });

    test('Formats distance accurately for meters (< 1km) and kilometers (>= 1km)', () {
      expect(Haversine.formatDistance(0.45), '450 m');
      expect(Haversine.formatDistance(0.08), '80 m');
      expect(Haversine.formatDistance(1.84), '1.8 km');
      expect(Haversine.formatDistance(5.0), '5.0 km');
    });
  });
}
