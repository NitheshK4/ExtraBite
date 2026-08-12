import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';

void main() {
  group('Owner Food Listing Visibility & Filtering Tests', () {
    ProviderContainer createTestContainer() {
      final container = ProviderContainer();
      // Set mock location to VIT-AP so distance filtering allows items near 16.4971, 80.5005
      container.read(locationProvider.notifier).setMockLocation(16.4971, 80.5005);
      return container;
    }

    test('Food created by PG/Hostel Owner is immediately visible to Personal Users', () {
      final container = createTestContainer();
      final foodNotifier = container.read(foodProvider.notifier);
      final initialFilteredCount = container.read(filteredFoodProvider).length;

      final now = DateTime.now();
      final ownerItem = FoodListing(
        id: 'owner_item_1',
        foodName: 'Royal Special Thali',
        description: 'Delicious South Indian Thali',
        propertyId: 'owner_pg_101',
        propertyName: 'Royal Deluxe Hostel',
        distanceKm: 0.2,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 50.0,
        availablePortions: 10,
        preparedTime: now.subtract(const Duration(minutes: 30)),
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: const ['Rice', 'Sambar', 'Curd'],
        allergens: const [],
        verificationStatus: 'verified',
        status: 'active',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      foodNotifier.addListing(ownerItem);
      foodNotifier.refreshListings();

      final filteredList = container.read(filteredFoodProvider);
      expect(filteredList.length, equals(initialFilteredCount + 1));

      final found = filteredList.firstWhere((item) => item.id == 'owner_item_1');
      expect(found.foodName, equals('Royal Special Thali'));
      expect(found.propertyName, equals('Royal Deluxe Hostel'));
      expect(found.isAvailable, isTrue);
    });

    test('Inactive food items are strictly hidden from Personal Users', () {
      final container = createTestContainer();
      final foodNotifier = container.read(foodProvider.notifier);

      final now = DateTime.now();
      final inactiveItem = FoodListing(
        id: 'inactive_item_1',
        foodName: 'Draft Meal',
        description: 'Not ready for listing',
        propertyId: 'owner_pg_101',
        propertyName: 'Royal Deluxe Hostel',
        distanceKm: 0.2,
        category: 'Dinner',
        isVegetarian: false,
        originalPrice: 120.0,
        sellingPrice: 60.0,
        availablePortions: 5,
        preparedTime: now,
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: const ['Chicken'],
        allergens: const [],
        verificationStatus: 'verified',
        status: 'draft',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      foodNotifier.addListing(inactiveItem);

      final filteredList = container.read(filteredFoodProvider);
      expect(filteredList.any((item) => item.id == 'inactive_item_1'), isFalse);
    });

    test('Sold-out food items (0 portions) are strictly hidden from Personal Users', () {
      final container = createTestContainer();
      final foodNotifier = container.read(foodProvider.notifier);

      final now = DateTime.now();
      final soldOutItem = FoodListing(
        id: 'sold_out_1',
        foodName: 'Popular Biryani',
        description: 'Sold out',
        propertyId: 'owner_pg_101',
        propertyName: 'Royal Deluxe Hostel',
        distanceKm: 0.2,
        category: 'Lunch',
        isVegetarian: false,
        originalPrice: 150.0,
        sellingPrice: 75.0,
        availablePortions: 0,
        preparedTime: now,
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: const ['Rice'],
        allergens: const [],
        verificationStatus: 'verified',
        status: 'sold_out',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      foodNotifier.addListing(soldOutItem);

      final filteredList = container.read(filteredFoodProvider);
      expect(filteredList.any((item) => item.id == 'sold_out_1'), isFalse);
    });

    test('Expired food items are strictly hidden from Personal Users', () {
      final container = createTestContainer();
      final foodNotifier = container.read(foodProvider.notifier);

      final now = DateTime.now();
      final expiredItem = FoodListing(
        id: 'expired_1',
        foodName: 'Yesterday Breakfast',
        description: 'Expired',
        propertyId: 'owner_pg_101',
        propertyName: 'Royal Deluxe Hostel',
        distanceKm: 0.2,
        category: 'Breakfast',
        isVegetarian: true,
        originalPrice: 50.0,
        sellingPrice: 25.0,
        availablePortions: 5,
        preparedTime: now.subtract(const Duration(hours: 10)),
        pickupStarts: now.subtract(const Duration(hours: 5)),
        pickupEnds: now.subtract(const Duration(hours: 1)),
        ingredients: const ['Idli'],
        allergens: const [],
        verificationStatus: 'verified',
        status: 'active',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      foodNotifier.addListing(expiredItem);

      final filteredList = container.read(filteredFoodProvider);
      expect(filteredList.any((item) => item.id == 'expired_1'), isFalse);
    });

    test('Unverified PG food items are strictly hidden from Personal Users', () {
      final container = createTestContainer();
      final foodNotifier = container.read(foodProvider.notifier);

      final now = DateTime.now();
      final unverifiedItem = FoodListing(
        id: 'unverified_1',
        foodName: 'Unverified Meal',
        description: 'Unverified PG',
        propertyId: 'unverified_pg',
        propertyName: 'Fake PG',
        distanceKm: 0.2,
        category: 'Dinner',
        isVegetarian: true,
        originalPrice: 60.0,
        sellingPrice: 30.0,
        availablePortions: 5,
        preparedTime: now,
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: const ['Rice'],
        allergens: const [],
        verificationStatus: 'unverified',
        status: 'active',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      foodNotifier.addListing(unverifiedItem);

      final filteredList = container.read(filteredFoodProvider);
      expect(filteredList.any((item) => item.id == 'unverified_1'), isFalse);
    });

    test('Decrementing portions to 0 updates status to sold_out and removes from customer feed', () {
      final container = createTestContainer();
      final foodNotifier = container.read(foodProvider.notifier);

      final now = DateTime.now();
      final item = FoodListing(
        id: 'item_to_sell_out',
        foodName: 'Limited Paratha',
        description: 'Only 2 left',
        propertyId: 'owner_pg_101',
        propertyName: 'Royal Deluxe Hostel',
        distanceKm: 0.2,
        category: 'Breakfast',
        isVegetarian: true,
        originalPrice: 40.0,
        sellingPrice: 20.0,
        availablePortions: 2,
        preparedTime: now,
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: const ['Wheat'],
        allergens: const [],
        verificationStatus: 'verified',
        status: 'active',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      foodNotifier.addListing(item);
      expect(container.read(filteredFoodProvider).any((i) => i.id == 'item_to_sell_out'), isTrue);

      foodNotifier.decrementPortions('item_to_sell_out', 2);
      expect(container.read(filteredFoodProvider).any((i) => i.id == 'item_to_sell_out'), isFalse);
    });
  });
}
