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

  group('2. Food Provider & Real-Time Filtering Tests', () {
    test('Starts with clean 0 sample listings and supports dynamic additions', () {
      final container = ProviderContainer();
      expect(container.read(filteredFoodProvider), isEmpty);

      final listing = FoodListing(
        id: 'real_1',
        foodName: 'Chicken Biryani',
        description: 'Fresh surplus biryani',
        propertyId: 'p1',
        propertyName: 'Sri Sai PG',
        distanceKm: 0.8,
        category: 'Dinner',
        isVegetarian: false,
        originalPrice: 140.0,
        sellingPrice: 70.0,
        availablePortions: 10,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: ['Rice', 'Chicken'],
        allergens: const [],
        verificationStatus: 'verified',
      );

      container.read(foodProvider.notifier).addListing(listing);
      final filteredList = container.read(filteredFoodProvider);
      expect(filteredList.length, equals(1));
      expect(filteredList.first.foodName, equals('Chicken Biryani'));
    });

    test('Filters listings correctly by Category Selection & Search Query', () {
      final container = ProviderContainer();
      final notifier = container.read(foodProvider.notifier);

      final vegMeal = FoodListing(
        id: 'real_veg',
        foodName: 'South Indian Veg Meals',
        description: 'Thali',
        propertyId: 'p1',
        propertyName: 'Sri Sai PG',
        distanceKm: 0.5,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 80.0,
        sellingPrice: 40.0,
        availablePortions: 6,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: ['Rice'],
        allergens: const [],
        verificationStatus: 'verified',
      );

      final nonVegMeal = FoodListing(
        id: 'real_nonveg',
        foodName: 'Chicken Biryani',
        description: 'Biryani',
        propertyId: 'p2',
        propertyName: 'Royal PG',
        distanceKm: 1.0,
        category: 'Dinner',
        isVegetarian: false,
        originalPrice: 120.0,
        sellingPrice: 25.0,
        availablePortions: 4,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: ['Chicken'],
        allergens: const [],
        verificationStatus: 'verified',
      );

      notifier.addListing(vegMeal);
      notifier.addListing(nonVegMeal);

      notifier.updateCategory('Lunch');
      var filteredList = container.read(filteredFoodProvider);
      expect(filteredList.length, equals(1));
      expect(filteredList.first.foodName, equals('South Indian Veg Meals'));

      notifier.updateCategory('Vegetarian');
      filteredList = container.read(filteredFoodProvider);
      expect(filteredList.every((item) => item.isVegetarian), isTrue);

      notifier.updateCategory('All');
      notifier.updateSearchQuery('Biryani');
      filteredList = container.read(filteredFoodProvider);
      expect(filteredList.length, equals(1));
      expect(filteredList.first.foodName, equals('Chicken Biryani'));
    });
  });

  group('3. Reservation Creation & State Tests', () {
    test('Creates new active reservations and decrements portions in real time', () {
      final container = ProviderContainer();
      final foodNotifier = container.read(foodProvider.notifier);
      final reservationNotifier = container.read(reservationProvider.notifier);

      final listing = FoodListing(
        id: 'item_100',
        foodName: 'Chapati & Curry',
        description: 'Fresh chapatis',
        propertyId: 'p1',
        propertyName: 'Royal Hostel',
        distanceKm: 0.5,
        category: 'Dinner',
        isVegetarian: true,
        originalPrice: 60.0,
        sellingPrice: 30.0,
        availablePortions: 10,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
      );

      foodNotifier.addListing(listing);

      final reservation = reservationNotifier.createReservation(
        listing: listing,
        quantity: 3,
      );
      foodNotifier.decrementPortions(listing.id, 3);

      expect(reservation.foodName, equals('Chapati & Curry'));
      expect(reservation.quantity, equals(3));
      expect(reservation.amountToCollect, equals(90.0));
      expect(reservation.status, equals(ReservationStatus.reserved));

      final activeList = container.read(activeReservationsProvider);
      expect(activeList.length, equals(1));
      expect(activeList.first.id, equals(reservation.id));

      final updatedFood = container.read(foodDetailProvider('item_100'));
      expect(updatedFood?.availablePortions, equals(7));

      // Cancel reservation
      reservationNotifier.cancelReservation(reservation.id);
      expect(container.read(activeReservationsProvider), isEmpty);
      expect(container.read(pastReservationsProvider).length, equals(1));
    });
  });

  group('4. UI Navigation & Smoke Tests', () {
    testWidgets('App UI Smoke & Navigation Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExtraBiteApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial screen must be Role Selection screen
      expect(find.text('Welcome to ExtraBite'), findsOneWidget);
      expect(find.text('Personal User'), findsOneWidget);
      expect(find.text('Hostel / PG Owner'), findsOneWidget);

      // 2. Select Personal User role
      await tester.tap(find.text('Personal User'));
      await tester.pumpAndSettle();

      // 3. Log in as Personal User
      expect(find.text('Log In as Personal User'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Log In as Personal User'));
      await tester.pumpAndSettle();

      // 4. Verify Customer Home Screen loads after login
      expect(find.text('Near VIT-AP University'), findsOneWidget);
      expect(find.text('Search meals, PGs or messes...'), findsOneWidget);

      // 5. Navigate to Search tab
      final searchIcon = find.byIcon(Icons.search_outlined);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();
      expect(find.text('Search Marketplace'), findsOneWidget);

      // 6. Navigate to Profile tab and check authenticated user info (not hardcoded developer data!)
      final profileIcon = find.byIcon(Icons.person_outline);
      expect(profileIcon, findsOneWidget);
      await tester.tap(profileIcon);
      await tester.pumpAndSettle();

      expect(find.text('Testuser'), findsOneWidget);
      expect(find.text('testuser@example.com'), findsOneWidget);
      expect(find.text('Pavan Kumar'), findsNothing);
    });
  });
}
