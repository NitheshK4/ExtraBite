import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/location/location_service.dart';
import '../core/location/location_state.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  static const Map<String, (double, double)> presetCoordinates = {
    'Near VIT-AP University': (16.4971, 80.5005),
    'Near SRM University-AP': (16.4710, 80.5100),
    'Thullur Center': (16.5300, 80.4700),
    'Mangalagiri Town': (16.4300, 80.5600),
    'Vijayawada Benz Circle': (16.5000, 80.6400),
  };

  LocationNotifier(
    this._locationService, [
    LocationState initialState = const LocationState.initial(),
  ]) : super(initialState);

  Future<void> determinePosition() async {
    state = const LocationState.loading();
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = const LocationState.serviceDisabled();
        return;
      }

      var permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
        if (permission == LocationPermission.denied) {
          state = const LocationState.permissionDenied();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = const LocationState.permissionPermanentlyDenied();
        return;
      }

      final position = await _locationService.getCurrentPosition();
      state = LocationState.available(position.latitude, position.longitude);
    } on TimeoutException {
      state = const LocationState.error('Location request timed out. Please try again.');
    } catch (_) {
      state = const LocationState.error('Unable to determine location. Please try again.');
    }
  }

  void setMockLocation(double latitude, double longitude) {
    state = LocationState.available(latitude, longitude);
  }

  void updateLocation(String newLocation) {
    final clean = newLocation.trim();
    if (clean.isEmpty) return;

    double lat = 16.4971;
    double lon = 80.5005;

    for (final entry in presetCoordinates.entries) {
      if (clean.toLowerCase().contains(entry.key.toLowerCase())) {
        lat = entry.value.$1;
        lon = entry.value.$2;
        break;
      }
    }

    state = LocationState.available(lat, lon, clean);
  }

  void resetToDefault() {
    state = const LocationState.initial();
    determinePosition();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});

final radiusProvider = StateProvider<double>((ref) {
  return 2.0; // Default radius: 2.0 km
});
