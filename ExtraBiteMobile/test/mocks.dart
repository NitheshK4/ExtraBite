import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:extrabite_mobile/core/location/location_service.dart';
import 'package:extrabite_mobile/core/location/location_state.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';

class MockLocationService implements LocationService {
  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.whileInUse;
  Position? mockPosition;
  Object? mockError;
  Completer<Position>? positionCompleter;

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (mockError != null) throw mockError!;
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    if (mockError != null) throw mockError!;
    return permissionStatus;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    if (mockError != null) throw mockError!;
    return permissionStatus;
  }

  @override
  Future<Position> getCurrentPosition() async {
    if (mockError != null) throw mockError!;
    if (positionCompleter != null) return positionCompleter!.future;
    if (mockPosition != null) return mockPosition!;
    return Position(
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
  }
}

class FakeLocationNotifier extends LocationNotifier {
  FakeLocationNotifier(super.locationService, [super.initialState]);

  @override
  Future<void> determinePosition() async {
    // No-op to prevent asynchronous permission check overrides in UI widget tests
  }
}

ProviderContainer createMockLocationContainer() {
  final mockService = MockLocationService();
  return ProviderContainer(
    overrides: [
      locationProvider.overrideWith((ref) {
        return FakeLocationNotifier(
          mockService,
          const LocationState.available(16.4971, 80.5005),
        );
      }),
    ],
  );
}
