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
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});

final radiusProvider = StateProvider<double>((ref) {
  return 2.0; // Default radius: 2.0 km
});
