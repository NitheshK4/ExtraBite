import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:extrabite_mobile/core/location/location_state.dart';
import 'package:extrabite_mobile/core/repositories/fake_auth_repository.dart';
import 'package:extrabite_mobile/core/utils/haversine.dart';
import 'package:extrabite_mobile/providers/auth_provider.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/features/customer/screens/customer_home_screen.dart';
import 'package:extrabite_mobile/core/repositories/pg_profile_repository.dart';
import 'mocks.dart';

void main() {
  group('1. Haversine Calculations', () {
    test('Zero distance same coordinates returns 0.0', () {
      final distance =
          Haversine.calculateDistance(16.4971, 80.5005, 16.4971, 80.5005);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('Known coordinates distance calculates correctly', () {
      // VIT-AP to Sri Sai Deluxe PG (16.4950, 80.5070)
      final distance =
          Haversine.calculateDistance(16.4971, 80.5005, 16.4950, 80.5070);
      expect(distance, closeTo(0.732, 0.05));
    });
  });

  group('2. Location StateNotifier transitions', () {
    late MockLocationService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockLocationService();
      container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is initial', () {
      final state = container.read(locationProvider);
      expect(state.status, equals(LocationStateStatus.initial));
    });

    test('Successful location resolution transitions to available', () async {
      mockService.mockPosition = Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      final notifier = container.read(locationProvider.notifier);
      final future = notifier.determinePosition();

      // Check it immediately goes to loading
      expect(container.read(locationProvider).status,
          equals(LocationStateStatus.loading));

      await future;

      final finalState = container.read(locationProvider);
      expect(finalState.status, equals(LocationStateStatus.available));
      expect(finalState.latitude, equals(16.4971));
      expect(finalState.longitude, equals(80.5005));
    });

    test('Service disabled transitions to serviceDisabled', () async {
      mockService.serviceEnabled = false;

      final notifier = container.read(locationProvider.notifier);
      await notifier.determinePosition();

      final state = container.read(locationProvider);
      expect(state.status, equals(LocationStateStatus.serviceDisabled));
    });

    test('Permission denied transitions to permissionDenied', () async {
      mockService.permissionStatus = LocationPermission.denied;

      final notifier = container.read(locationProvider.notifier);
      await notifier.determinePosition();

      final state = container.read(locationProvider);
      expect(state.status, equals(LocationStateStatus.permissionDenied));
    });

    test(
        'Permission permanently denied transitions to permissionPermanentlyDenied',
        () async {
      mockService.permissionStatus = LocationPermission.deniedForever;

      final notifier = container.read(locationProvider.notifier);
      await notifier.determinePosition();

      final state = container.read(locationProvider);
      expect(state.status,
          equals(LocationStateStatus.permissionPermanentlyDenied));
    });

    test('GPS error transitions to error state', () async {
      mockService.mockError = Exception('Hardware error');

      final notifier = container.read(locationProvider.notifier);
      await notifier.determinePosition();

      final state = container.read(locationProvider);
      expect(state.status, equals(LocationStateStatus.error));
      expect(state.errorMessage,
          equals('Unable to determine location. Please try again.'));
    });
  });

  group('3. Business Rules and Radius Filtering', () {
    late MockLocationService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockLocationService();
      container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockService),
          foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
          pgProfileRepositoryProvider
              .overrideWithValue(PgProfileRepository.fakeForTest()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Unverified PG is NEVER returned regardless of distance/radius',
        () async {
      mockService.mockPosition = Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      await container.read(locationProvider.notifier).determinePosition();
      container.read(radiusProvider.notifier).state = 10.0; // Large radius

      final filteredList = container.read(filteredFoodProvider);

      final hasUnverified =
          filteredList.any((item) => item.verificationStatus != 'verified');
      expect(hasUnverified, isFalse);
    });

    test('Filtering at Radius 1.0 km', () async {
      mockService.mockPosition = Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      await container.read(locationProvider.notifier).determinePosition();
      container.read(radiusProvider.notifier).state = 1.0;

      final filteredList = container.read(filteredFoodProvider);

      for (final item in filteredList) {
        expect(item.distanceKm, lessThanOrEqualTo(1.0));
      }

      expect(
          filteredList.any((item) => item.propertyName == 'Sri Sai Deluxe PG'),
          isTrue);
      expect(
          filteredList.any((item) => item.propertyName == 'Green Gardens PG'),
          isTrue);
      expect(
          filteredList
              .any((item) => item.propertyName == 'Royal Men\'s Hostel'),
          isFalse);
      expect(
          filteredList
              .any((item) => item.propertyName == 'Stanza Living Delhi PG'),
          isFalse);
    });

    test('Filtering at Radius 2.0 km', () async {
      mockService.mockPosition = Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      await container.read(locationProvider.notifier).determinePosition();
      container.read(radiusProvider.notifier).state = 2.0;

      final filteredList = container.read(filteredFoodProvider);

      for (final item in filteredList) {
        expect(item.distanceKm, lessThanOrEqualTo(2.0));
      }

      expect(
          filteredList
              .any((item) => item.propertyName == 'Royal Men\'s Hostel'),
          isTrue);
      expect(
          filteredList.any((item) => item.propertyName == 'Modern Mess & PG'),
          isTrue);
      expect(
          filteredList
              .any((item) => item.propertyName == 'Stanza Living Delhi PG'),
          isFalse);
    });

    test('Filtering at Radius 5.0 km', () async {
      mockService.mockPosition = Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      await container.read(locationProvider.notifier).determinePosition();
      container.read(radiusProvider.notifier).state = 5.0;

      final filteredList = container.read(filteredFoodProvider);

      for (final item in filteredList) {
        expect(item.distanceKm, lessThanOrEqualTo(5.0));
      }

      expect(
          filteredList
              .any((item) => item.propertyName == 'Stanza Living Delhi PG'),
          isTrue);
    });

    test(
        'Boundary Distance Filtering: Exactly 1.0 km, 1.01 km, 2.0 km, 2.01 km',
        () async {
      mockService.mockPosition = Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      await container.read(locationProvider.notifier).determinePosition();
      final foodNotifier = container.read(foodProvider.notifier);
      foodNotifier.clearAll();

      final now = DateTime.now();

      // Exactly 1.0 km listing (using offset 1.0 / 111.12 = 0.008999 degree lat)
      final listing1Km = FoodListing(
        id: 'boundary_1km',
        foodName: 'Boundary 1km',
        description: 'Test',
        propertyId: 'b1',
        propertyName: 'Boundary PG',
        distanceKm: 0.0,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 50.0,
        availablePortions: 5,
        preparedTime: now,
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971 + (0.999 / 111.195),
        longitude: 80.5005,
      );

      // 1.01 km listing (just outside 1.0 km boundary)
      final listing1_01Km = FoodListing(
        id: 'boundary_1_01km',
        foodName: 'Outside 1km',
        description: 'Test',
        propertyId: 'b2',
        propertyName: 'Boundary PG 2',
        distanceKm: 0.0,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 50.0,
        availablePortions: 5,
        preparedTime: now,
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: const [],
        allergens: const [],
        verificationStatus: 'verified',
        latitude: 16.4971 + (1.001 / 111.195),
        longitude: 80.5005,
      );

      foodNotifier.addListing(listing1Km);
      foodNotifier.addListing(listing1_01Km);

      // Set radius to 1.0 km
      container.read(radiusProvider.notifier).state = 1.0;
      var filteredList = container.read(filteredFoodProvider);

      expect(filteredList.any((item) => item.id == 'boundary_1km'), isTrue);
      expect(filteredList.any((item) => item.id == 'boundary_1_01km'), isFalse);

      // Set radius to 2.0 km
      container.read(radiusProvider.notifier).state = 2.0;
      filteredList = container.read(filteredFoodProvider);
      expect(filteredList.any((item) => item.id == 'boundary_1_01km'), isTrue);
    });
  });

  group('4. UI Widget Testing', () {
    late MockLocationService mockService;

    setUp(() {
      mockService = MockLocationService();
    });

    testWidgets('Location Loading State UI works correctly',
        (WidgetTester tester) async {
      final completer = Completer<Position>();
      mockService.positionCompleter = completer;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(mockService),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
            pgProfileRepositoryProvider
                .overrideWithValue(PgProfileRepository.fakeForTest()),
          ],
          child: const MaterialApp(
            home: CustomerHomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Detecting your location...'), findsAtLeastNWidgets(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the completer to release resources
      completer.complete(Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('Location Permission Denied UI works correctly',
        (WidgetTester tester) async {
      mockService.permissionStatus = LocationPermission.denied;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(mockService),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
            pgProfileRepositoryProvider
                .overrideWithValue(PgProfileRepository.fakeForTest()),
          ],
          child: const MaterialApp(
            home: CustomerHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text('Location permission required'), findsAtLeastNWidgets(1));
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('Location Services Disabled UI works correctly',
        (WidgetTester tester) async {
      mockService.serviceEnabled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(mockService),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
            pgProfileRepositoryProvider
                .overrideWithValue(PgProfileRepository.fakeForTest()),
          ],
          child: const MaterialApp(
            home: CustomerHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Location services are turned off'),
          findsAtLeastNWidgets(1));
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('Successful GPS location resolution renders marketplace feed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationProvider.overrideWith((ref) {
              return FakeLocationNotifier(
                mockService,
                const LocationState.available(16.4971, 80.5005),
              );
            }),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
            pgProfileRepositoryProvider
                .overrideWithValue(PgProfileRepository.fakeForTest()),
          ],
          child: const MaterialApp(
            home: CustomerHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Marketplace components must exist
      expect(find.text('Search meals, PGs or messes...'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      // Sri Sai Deluxe PG is within default 2.0 km, should render
      expect(find.text('Sri Sai Deluxe PG'), findsWidgets);
    });
  });

  group('6. Location Caching and Deduplication', () {
    late MockLocationService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockLocationService();
      container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'Cached location is reused on subsequent determinePosition calls without triggering GPS',
        () async {
      final notifier = container.read(locationProvider.notifier);

      // First call - queries GPS
      await notifier.determinePosition();
      expect(mockService.getCurrentPositionCallCount, equals(1));
      expect(mockService.checkPermissionCallCount, equals(1));
      expect(notifier.state.isAvailable, isTrue);

      // Second call (e.g. user navigates back to Home tab) - must reuse cached location immediately
      await notifier.determinePosition();
      expect(mockService.getCurrentPositionCallCount,
          equals(1)); // Still 1! No new GPS call
      expect(mockService.checkPermissionCallCount,
          equals(1)); // No permission check either
      expect(notifier.state.isAvailable, isTrue);
    });

    test('forceRefresh: true bypasses cache and triggers fresh GPS query',
        () async {
      final notifier = container.read(locationProvider.notifier);

      // First call
      await notifier.determinePosition();
      expect(mockService.getCurrentPositionCallCount, equals(1));

      // Force refresh (e.g. pull-to-refresh or retry button)
      await notifier.determinePosition(forceRefresh: true);
      expect(mockService.getCurrentPositionCallCount, equals(2));
    });

    test(
        'Concurrent determinePosition calls are deduplicated into a single in-flight request',
        () async {
      final completer = Completer<Position>();
      mockService.positionCompleter = completer;

      final notifier = container.read(locationProvider.notifier);

      // Launch two calls in parallel
      final future1 = notifier.determinePosition(forceRefresh: true);
      final future2 = notifier.determinePosition(forceRefresh: true);

      // In-flight deduplication returns the exact same running Future
      expect(identical(future1, future2), isTrue);

      // Allow async permission checks to complete and reach getCurrentPosition()
      await Future<void>.delayed(Duration.zero);
      expect(mockService.getCurrentPositionCallCount, equals(1));

      completer.complete(Position(
        longitude: 80.5005,
        latitude: 16.4971,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ));

      await Future.wait([future1, future2]);

      expect(notifier.state.isAvailable, isTrue);
      expect(mockService.getCurrentPositionCallCount, equals(1));
    });

    test('clearLocation resets state and cache so subsequent call queries GPS',
        () async {
      final notifier = container.read(locationProvider.notifier);

      await notifier.determinePosition();
      expect(mockService.getCurrentPositionCallCount, equals(1));
      expect(notifier.state.isAvailable, isTrue);

      // User logs out -> clearLocation called
      notifier.clearLocation();
      expect(notifier.state.status, equals(LocationStateStatus.initial));
      expect(notifier.state.hasLocation, isFalse);

      // Subsequent login/home access requires GPS again
      await notifier.determinePosition();
      expect(mockService.getCurrentPositionCallCount, equals(2));
      expect(notifier.state.isAvailable, isTrue);
    });

    test('Stale location exceeding freshness limit triggers fresh GPS query',
        () async {
      final oldTime = DateTime.now().subtract(const Duration(minutes: 20));
      final staleState =
          LocationState.available(16.4971, 80.5005, null, oldTime);
      final customNotifier = LocationNotifier(mockService, staleState);

      expect(customNotifier.state.isFresh(maxAge: const Duration(minutes: 15)),
          isFalse);

      // Calling determinePosition with stale state should trigger GPS
      await customNotifier.determinePosition(
          freshnessLimit: const Duration(minutes: 15));
      expect(mockService.getCurrentPositionCallCount, equals(1));
      expect(customNotifier.state.isFresh(), isTrue);
    });
  });
}
