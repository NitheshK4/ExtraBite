import 'package:flutter_test/flutter_test.dart';
import 'package:extrabite_mobile/core/utils/haversine.dart';
import 'package:extrabite_mobile/core/constants/app_constants.dart';
import 'package:extrabite_mobile/data/demo/seed_data.dart';

void main() {
  group('Radius & Distance Filtering Tests', () {
    // User benchmark position: Bengaluru Central
    const userLat = AppConstants.defaultLatitude;
    const userLon = AppConstants.defaultLongitude;

    final listings = SeedData.generateFoodListings();

    test('Default 2.0 km radius includes nearby listings and excludes distant ones', () {
      final within2km = listings.where((listing) {
        return Haversine.isWithinRadius(
          userLat,
          userLon,
          listing.latitude,
          listing.longitude,
          AppConstants.defaultRadiusKm,
        );
      }).toList();

      expect(within2km.isNotEmpty, true);
      // Electronic City listing (~15km) must be strictly excluded
      final hasDistant = within2km.any((l) => l.neighborhood == 'Electronic City');
      expect(hasDistant, false);
    });

    test('1 km radius only includes listings <= 1 km away', () {
      final within1km = listings.where((listing) {
        return Haversine.isWithinRadius(
          userLat,
          userLon,
          listing.latitude,
          listing.longitude,
          1.0,
        );
      }).toList();

      for (final item in within1km) {
        final dist = Haversine.calculateDistanceKm(userLat, userLon, item.latitude, item.longitude);
        expect(dist, lessThanOrEqualTo(1.0));
      }
    });

    test('10 km radius includes Koramangala, Indiranagar, and HSR Layout', () {
      final within10km = listings.where((listing) {
        return Haversine.isWithinRadius(
          userLat,
          userLon,
          listing.latitude,
          listing.longitude,
          10.0,
        );
      }).toList();

      final neighborhoods = within10km.map((l) => l.neighborhood).toSet();
      expect(neighborhoods.contains('Koramangala'), true);
      expect(neighborhoods.contains('Indiranagar'), true);
      expect(neighborhoods.contains('HSR Layout'), true);
    });
  });
}
