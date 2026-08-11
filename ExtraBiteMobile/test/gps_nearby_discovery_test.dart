import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';

void main() {
  group('1. Haversine Distance & Coordinate Calculations', () {
    test('Calculates accurate distance between known GPS coordinates', () {
      // Coordinate 1: VIT-AP University (16.4950, 80.5000)
      // Coordinate 2: SRM University-AP (16.4682, 80.5085) ~ 3.1 km away
      final distanceM = FoodListing.calculateHaversineDistanceMeters(
        16.4950,
        80.5000,
        16.4682,
        80.5085,
      );
      final distanceKm = FoodListing.calculateHaversineDistanceKm(
        16.4950,
        80.5000,
        16.4682,
        80.5085,
      );

      // Expected distance is ~3.1 km (3120m)
      expect(distanceKm, closeTo(3.1, 0.2));
      expect(distanceM, closeTo(3120.0, 200.0));
    });

    test('Formatted distance outputs friendly string', () {
      final closeListing = FoodListing(
        id: 'close_1',
        foodName: 'Roti & Dal',
        description: 'Warm rotis',
        propertyId: 'p1',
        propertyName: 'Hostel A',
        distanceKm: 0.45,
        distanceMeters: 450.0,
        category: 'Dinner',
        isVegetarian: true,
        originalPrice: 60.0,
        sellingPrice: 30.0,
        availablePortions: 4,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
      );

      expect(closeListing.formattedDistance, equals('450 m away'));

      final farListing = closeListing.copyWith(
        distanceKm: 1.8,
        distanceMeters: 1800.0,
      );
      expect(farListing.formattedDistance, equals('1.8 km away'));
    });
  });

  group('2. GPS-First Filtering, Radius Control & Nearest-First Sorting', () {
    test('Default 2 km radius strictly filters out listings beyond 2,000 meters', () {
      final container = ProviderContainer();
      final foodNotifier = container.read(foodProvider.notifier);

      // User default anchor: (16.4950, 80.5000)

      // Listing 1: 500m away (Inside 2 km radius)
      final nearListing = FoodListing(
        id: 'item_near',
        foodName: 'Veg Thali',
        description: 'Fresh lunch',
        propertyId: 'p_near',
        propertyName: 'Green Valley PG',
        latitude: 16.4980,
        longitude: 80.5020,
        distanceKm: 0.5,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 50.0,
        availablePortions: 8,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
      );

      // Listing 2: 1.2 km away (Inside 2 km radius)
      final midListing = FoodListing(
        id: 'item_mid',
        foodName: 'Paneer Biryani',
        description: 'Fresh biryani',
        propertyId: 'p_mid',
        propertyName: 'Sunrise Mess',
        latitude: 16.5050,
        longitude: 80.5050,
        distanceKm: 1.2,
        category: 'Dinner',
        isVegetarian: true,
        originalPrice: 150.0,
        sellingPrice: 75.0,
        availablePortions: 5,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
      );

      // Listing 3: 3.5 km away (Outside 2 km radius, Inside 5 km radius)
      final farListing = FoodListing(
        id: 'item_far',
        foodName: 'Egg Curry Rice',
        description: 'Far meal',
        propertyId: 'p_far',
        propertyName: 'Highway PG',
        latitude: 16.5200,
        longitude: 80.5150, // ~ 3.2 km
        distanceKm: 3.2,
        category: 'Dinner',
        isVegetarian: false,
        originalPrice: 120.0,
        sellingPrice: 60.0,
        availablePortions: 10,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
      );

      foodNotifier.addListing(nearListing);
      foodNotifier.addListing(midListing);
      foodNotifier.addListing(farListing);

      // 1. With default 2 km radius, only 2 items should be visible
      final filteredList2km = container.read(filteredFoodProvider);
      expect(filteredList2km.length, equals(2));
      expect(filteredList2km.any((i) => i.id == 'item_far'), isFalse);

      // 2. Nearest item must be first in list
      expect(filteredList2km.first.id, equals('item_near'));
      expect(filteredList2km.last.id, equals('item_mid'));

      // 3. Switch radius to 1 km -> Only nearListing should be visible
      container.read(locationProvider.notifier).setRadius(1000.0);
      final filteredList1km = container.read(filteredFoodProvider);
      expect(filteredList1km.length, equals(1));
      expect(filteredList1km.first.id, equals('item_near'));

      // 4. Switch radius to 5 km -> All 3 items should become visible
      container.read(locationProvider.notifier).setRadius(5000.0);
      final filteredList5km = container.read(filteredFoodProvider);
      expect(filteredList5km.length, equals(3));
      expect(filteredList5km.first.id, equals('item_near'));
      expect(filteredList5km.last.id, equals('item_far'));
    });

    test('LocationNotifier supports manual approximate fallback if GPS disabled', () {
      final container = ProviderContainer();
      final locNotifier = container.read(locationProvider.notifier);

      locNotifier.setManualFallback(
        localityName: 'Near SRM University-AP',
        subLocality: 'Neerukonda, Mangalagiri',
        latitude: 16.4682,
        longitude: 80.5085,
      );

      final state = container.read(locationProvider);
      expect(state.localityLabel, equals('Near SRM University-AP'));
      expect(state.isManualFallback, isTrue);
      expect(state.latitude, equals(16.4682));
      expect(state.longitude, equals(80.5085));
    });
  });
}
