import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:extrabite_mobile/core/location/location_state.dart';
import 'package:extrabite_mobile/core/utils/haversine.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/features/customer/screens/customer_home_screen.dart';
import 'mocks.dart';

void main() {
  group('1. Haversine Calculations', () {
    test('Zero distance same coordinates returns 0.0', () {
      final distance = Haversine.calculateDistance(16.4971, 80.5005, 16.4971, 80.5005);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('Known coordinates distance calculates correctly', () {
      // VIT-AP to Sri Sai Deluxe PG (16.4950, 80.5070)
      final distance = Haversine.calculateDistance(16.4971, 80.5005, 16.4950, 80.5070);
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
      expect(container.read(locationProvider).status, equals(LocationStateStatus.loading));

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

    test('Permission permanently denied transitions to permissionPermanentlyDenied', () async {
      mockService.permissionStatus = LocationPermission.deniedForever;

      final notifier = container.read(locationProvider.notifier);
      await notifier.determinePosition();

      final state = container.read(locationProvider);
      expect(state.status, equals(LocationStateStatus.permissionPermanentlyDenied));
    });

    test('GPS error transitions to error state', () async {
      mockService.mockError = Exception('Hardware error');

      final notifier = container.read(locationProvider.notifier);
      await notifier.determinePosition();

      final state = container.read(locationProvider);
      expect(state.status, equals(LocationStateStatus.error));
      expect(state.errorMessage, equals('Unable to determine location. Please try again.'));
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
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Unverified PG is NEVER returned regardless of distance/radius', () async {
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
      
      final hasUnverified = filteredList.any((item) => item.verificationStatus != 'verified');
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
      
      expect(filteredList.any((item) => item.propertyName == 'Sri Sai Deluxe PG'), isTrue);
      expect(filteredList.any((item) => item.propertyName == 'Green Gardens PG'), isTrue);
      expect(filteredList.any((item) => item.propertyName == 'Royal Men\'s Hostel'), isFalse);
      expect(filteredList.any((item) => item.propertyName == 'Stanza Living Delhi PG'), isFalse);
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

      expect(filteredList.any((item) => item.propertyName == 'Royal Men\'s Hostel'), isTrue);
      expect(filteredList.any((item) => item.propertyName == 'Modern Mess & PG'), isTrue);
      expect(filteredList.any((item) => item.propertyName == 'Stanza Living Delhi PG'), isFalse);
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

      expect(filteredList.any((item) => item.propertyName == 'Stanza Living Delhi PG'), isTrue);
    });
  });

  group('4. UI Widget Testing', () {
    late MockLocationService mockService;

    setUp(() {
      mockService = MockLocationService();
    });

    testWidgets('Location Loading State UI works correctly', (WidgetTester tester) async {
      final completer = Completer<Position>();
      mockService.positionCompleter = completer;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(mockService),
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

    testWidgets('Location Permission Denied UI works correctly', (WidgetTester tester) async {
      mockService.permissionStatus = LocationPermission.denied;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: CustomerHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Location permission required'), findsAtLeastNWidgets(1));
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('Location Services Disabled UI works correctly', (WidgetTester tester) async {
      mockService.serviceEnabled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: CustomerHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Location services are turned off'), findsAtLeastNWidgets(1));
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('Successful GPS location resolution renders marketplace feed', (WidgetTester tester) async {
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
}
