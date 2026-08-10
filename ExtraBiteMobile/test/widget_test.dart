import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:extrabite_mobile/app/app.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/models/reservation.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/providers/reservation_provider.dart';

void main() {
  group('1. FoodListing Model Tests', () {
    test('Calculates discount percentage correctly', () {
      final listing = FoodListing(
        id: 'test_1',
        foodName: 'Test Food',
        description: 'Desc',
        propertyId: 'p1',
        propertyName: 'Sri Sai PG',
        distanceKm: 0.5,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 75.0,
        availablePortions: 5,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: [],
        allergens: [],
        verificationStatus: 'verified',
      );
      expect(listing.discountPercentage, equals(25.0));
    });

    test('Identifies expired listings correctly', () {
      final expiredListing = FoodListing(
        id: 'test_2',
        foodName: 'Expired Food',
        description: 'Desc',
        propertyId: 'p1',
        propertyName: 'Sri Sai PG',
        distanceKm: 0.5,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 75.0,
        availablePortions: 5,
        preparedTime: DateTime.now().subtract(const Duration(hours: 4)),
        pickupStarts: DateTime.now().subtract(const Duration(hours: 3)),
        pickupEnds: DateTime.now().subtract(const Duration(hours: 1)),
        ingredients: [],
        allergens: [],
        verificationStatus: 'verified',
      );
      expect(expiredListing.isExpired, isTrue);
    });
  });

  group('2. Food Provider & Filtering Tests', () {
    test('Initializes with verified mock listings only in filtered provider', () {
      final container = ProviderContainer();
      final filteredList = container.read(filteredFoodProvider);
      
      // All items in customer listings must have status 'verified'
      for (final item in filteredList) {
        expect(item.verificationStatus, equals('verified'));
      }
    });

    test('Filters listings correctly by Category Selection', () {
      final container = ProviderContainer();
      final notifier = container.read(foodProvider.notifier);
      
      // Select Breakfast category
      notifier.updateCategory('Breakfast');
      var filteredList = container.read(filteredFoodProvider);
      for (final item in filteredList) {
        expect(item.category, equals('Breakfast'));
      }

      // Select Vegetarian category
      notifier.updateCategory('Vegetarian');
      filteredList = container.read(filteredFoodProvider);
      for (final item in filteredList) {
        expect(item.isVegetarian, isTrue);
      }
    });

    test('Filters listings correctly by Search Query', () {
      final container = ProviderContainer();
      final notifier = container.read(foodProvider.notifier);
      
      // Search for Biryani
      notifier.updateSearchQuery('Biryani');
      final filteredList = container.read(filteredFoodProvider);
      for (final item in filteredList) {
        expect(
          item.foodName.toLowerCase().contains('biryani') ||
          item.propertyName.toLowerCase().contains('biryani') ||
          item.category.toLowerCase().contains('biryani'),
          isTrue,
        );
      }
    });
  });

  group('3. Reservation Creation & State Tests', () {
    test('Creates new active reservations and updates lists correctly', () {
      final container = ProviderContainer();
      final foodList = container.read(filteredFoodProvider);
      final reservationNotifier = container.read(reservationProvider.notifier);

      final initialActiveCount = container.read(activeReservationsProvider).length;

      // Reserve the first food item
      final targetFood = foodList.first;
      final reservation = reservationNotifier.createReservation(
        listing: targetFood,
        quantity: 2,
      );

      expect(reservation.foodName, equals(targetFood.foodName));
      expect(reservation.quantity, equals(2));
      expect(reservation.amountToCollect, equals(targetFood.sellingPrice * 2));
      expect(reservation.status, equals(ReservationStatus.reserved));

      // Active reservations list should grow by 1
      final activeList = container.read(activeReservationsProvider);
      expect(activeList.length, equals(initialActiveCount + 1));
      expect(activeList.first.id, equals(reservation.id));
    });

    test('Cancels active reservations correctly', () {
      final container = ProviderContainer();
      final reservationNotifier = container.read(reservationProvider.notifier);
      final activeList = container.read(activeReservationsProvider);
      
      expect(activeList.isNotEmpty, isTrue);
      final targetId = activeList.first.id;

      // Cancel the reservation
      reservationNotifier.cancelReservation(targetId);

      // Verify it is no longer in the active list
      final newActiveList = container.read(activeReservationsProvider);
      expect(newActiveList.any((item) => item.id == targetId), isFalse);

      // Verify it exists in the past list with status cancelled
      final pastList = container.read(pastReservationsProvider);
      expect(pastList.any((item) => item.id == targetId && item.status == ReservationStatus.cancelled), isTrue);
    });
  });

  group('4. UI Navigation & Smoke Tests', () {
    testWidgets('App UI Smoke & Navigation Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExtraBiteApp(),
        ),
      );
      // Wait for GoRouter to resolve initial route
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 1. Verify Home Screen loads Location Header & search bar
      expect(find.text('Near VIT-AP University'), findsOneWidget);
      expect(find.text('Search meals, PGs or messes...'), findsOneWidget);

      // 2. Verify that Chicken Rice card is rendered on screen
      expect(find.text('Chicken Rice'), findsWidgets);
      expect(find.text('Royal Men\'s Hostel'), findsWidgets);

      // 3. Tap on Search tab icon
      final searchIcon = find.byIcon(Icons.search_outlined);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Verify Search page header appears
      expect(find.text('Search Marketplace'), findsOneWidget);

      // 4. Tap on Reservations tab icon
      final reservationsIcon = find.byIcon(Icons.receipt_long_outlined);
      expect(reservationsIcon, findsOneWidget);
      await tester.tap(reservationsIcon);
      await tester.pumpAndSettle();

      // Verify Reservations page header appears
      expect(find.text('My Food Reservations'), findsOneWidget);
    });
  });
}
