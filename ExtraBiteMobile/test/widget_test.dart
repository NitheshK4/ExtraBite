import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:extrabite_mobile/app/app.dart';
import 'package:extrabite_mobile/core/repositories/fake_auth_repository.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/models/reservation.dart';
import 'package:extrabite_mobile/providers/auth_provider.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/providers/reservation_provider.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';
import 'package:extrabite_mobile/core/location/location_state.dart';
import 'package:extrabite_mobile/features/customer/screens/food_detail_screen.dart';
import 'package:extrabite_mobile/core/repositories/pg_profile_repository.dart';
import 'mocks.dart';

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
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971,
        longitude: 80.5005,
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
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971,
        longitude: 80.5005,
      );
      expect(expiredListing.isExpired, isTrue);
    });
  });

  group('2. Food Provider & Filtering Tests', () {
    test('Initializes with verified mock listings only in filtered provider', () {
      final container = createMockLocationContainer();
      final filteredList = container.read(filteredFoodProvider);
      
      for (final item in filteredList) {
        expect(item.verificationStatus, equals('verified'));
      }
    });

    test('Filters listings correctly by Category Selection', () {
      final container = createMockLocationContainer();
      final notifier = container.read(foodProvider.notifier);
      
      notifier.updateCategory('Breakfast');
      var filteredList = container.read(filteredFoodProvider);
      for (final item in filteredList) {
        expect(item.category, equals('Breakfast'));
      }

      notifier.updateCategory('Vegetarian');
      filteredList = container.read(filteredFoodProvider);
      for (final item in filteredList) {
        expect(item.isVegetarian, isTrue);
      }
    });

    test('Filters listings correctly by Search Query', () {
      final container = createMockLocationContainer();
      final notifier = container.read(foodProvider.notifier);
      
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

    test('Starts with clean/mock sample listings and supports dynamic additions', () {
      final container = createMockLocationContainer();
      final notifier = container.read(foodProvider.notifier);
      notifier.clearAll();
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
        ingredients: const ['Rice', 'Chicken'],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      notifier.addListing(listing);
      final filteredList = container.read(filteredFoodProvider);
      expect(filteredList.length, equals(1));
      expect(filteredList.first.foodName, equals('Chicken Biryani'));
    });

    test('Filters listings correctly by Category Selection & Search Query on dynamic lists', () {
      final container = createMockLocationContainer();
      final notifier = container.read(foodProvider.notifier);
      notifier.clearAll();

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
        ingredients: const ['Rice'],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971,
        longitude: 80.5005,
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
        ingredients: const ['Chicken'],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971,
        longitude: 80.5005,
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
    test('Correctly updates and computes active reservations list', () async {
      final container = createMockLocationContainer();
      final foodList = container.read(filteredFoodProvider);
      final reservationNotifier = container.read(reservationProvider.notifier);

      final initialActiveCount = container.read(activeReservationsProvider).length;

      final targetFood = foodList.first;
      final reservation = await reservationNotifier.createReservation(
        listing: targetFood,
        quantity: 2,
      );

      expect(reservation.foodName, equals(targetFood.foodName));
      expect(reservation.quantity, equals(2));
      expect(reservation.amountToCollect, equals(targetFood.sellingPrice * 2));
      expect(reservation.status, equals(ReservationStatus.reserved));

      final activeList = container.read(activeReservationsProvider);
      expect(activeList.length, equals(initialActiveCount + 1));
      expect(activeList.first.id, equals(reservation.id));
    });

    test('Cancels active reservations correctly', () async {
      final container = createMockLocationContainer();
      final foodList = container.read(filteredFoodProvider);
      final reservationNotifier = container.read(reservationProvider.notifier);

      final targetFood = foodList.first;
      final reservation = await reservationNotifier.createReservation(
        listing: targetFood,
        quantity: 2,
      );

      final activeList = container.read(activeReservationsProvider);
      expect(activeList.isNotEmpty, isTrue);
      final targetId = reservation.id;

      await reservationNotifier.cancelReservation(targetId);

      final newActiveList = container.read(activeReservationsProvider);
      expect(newActiveList.any((item) => item.id == targetId), isFalse);

      final pastList = container.read(pastReservationsProvider);
      expect(pastList.any((item) => item.id == targetId && item.status == ReservationStatus.cancelled), isTrue);
    });

    test('Creates new active reservations and decrements portions in real time', () async {
      final container = createMockLocationContainer();
      final foodNotifier = container.read(foodProvider.notifier);
      final reservationNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

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
        latitude: 16.4971,
        longitude: 80.5005,
      );

      foodNotifier.addListing(listing);

      final reservation = await reservationNotifier.createReservation(
        listing: listing,
        quantity: 3,
      );
      await foodNotifier.decrementPortions(listing.id, 3);

      expect(reservation.foodName, equals('Chapati & Curry'));
      expect(reservation.quantity, equals(3));
      expect(reservation.amountToCollect, equals(90.0));
      expect(reservation.status, equals(ReservationStatus.reserved));

      final activeList = container.read(activeReservationsProvider);
      expect(activeList.any((item) => item.id == reservation.id), isTrue);

      final updatedFood = container.read(foodDetailProvider('item_100'));
      expect(updatedFood?.availablePortions, equals(7));
    });

    testWidgets('Sold Out listing disables Reserve button and displays Sold Out in UI', (WidgetTester tester) async {
      final mockService = MockLocationService();

      final soldOutListing = FoodListing(
        id: 'item_sold_out',
        foodName: 'Sold Out Meal',
        description: 'No portions left',
        propertyId: 'p1',
        propertyName: 'Sri Sai PG',
        distanceKm: 0.5,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 50.0,
        availablePortions: 0,
        preparedTime: DateTime.now(),
        pickupStarts: DateTime.now(),
        pickupEnds: DateTime.now().add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationProvider.overrideWith((ref) {
              return FakeLocationNotifier(
                mockService,
                const LocationState.available(16.4971, 80.5005),
              );
            }),
            foodProvider.overrideWith((ref) {
              final notifier = FoodNotifier(FakeFoodRepository());
              notifier.clearAll();
              notifier.addListing(soldOutListing);
              return notifier;
            }),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            pgProfileRepositoryProvider.overrideWithValue(PgProfileRepository.fakeForTest()),
          ],
          child: const MaterialApp(
            home: FoodDetailScreen(foodId: 'item_sold_out'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Sold Out" text is displayed on the button
      expect(find.text('Sold Out'), findsOneWidget);

      // Verify portions displayed is 0
      expect(find.text('0'), findsOneWidget);

      // Verify the ElevatedButton is disabled (onPressed is null)
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNull);
    });
  });

  group('4. UI Navigation & Smoke Tests', () {
    testWidgets('App UI Smoke & Navigation Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeLocationAndAuthOverrides(),
          child: const ExtraBiteApp(),
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

      // 4. After login, role_finalized = false (new fake user).
      //    Router shows Role Selection ("Choose Your Role") so user can confirm role.
      expect(find.text('Choose Your Role'), findsOneWidget);

      // 5. Tap Personal User to finalize the role via set_user_role('customer').
      await tester.tap(find.text('Personal User'));
      await tester.pumpAndSettle();

      // 6. Now role_finalized = true → Customer Home Screen loads.
      expect(find.text('Near VIT-AP University'), findsAtLeastNWidgets(1));
      expect(find.text('Search meals, PGs or messes...'), findsOneWidget);

      // 7. Navigate to Search tab
      final searchIcon = find.byIcon(Icons.search_outlined);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();
      expect(find.text('Search Marketplace'), findsOneWidget);

      // 8. Navigate to Profile tab and check authenticated user info
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
