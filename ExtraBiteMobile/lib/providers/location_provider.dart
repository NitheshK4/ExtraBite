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

  DateTime? _lastSuccessfulFetch;
  Future<void>? _inFlightRequest;

  DateTime? get lastSuccessfulFetch => _lastSuccessfulFetch;

  LocationNotifier(
    this._locationService, [
    LocationState initialState = const LocationState.initial(),
  ]) : super(initialState) {
    if (initialState.lastUpdated != null) {
      _lastSuccessfulFetch = initialState.lastUpdated;
    }
  }

  /// Determines device position.
  /// If [forceRefresh] is false and the current state has fresh coordinates within [freshnessLimit],
  /// the cached location is reused immediately without requesting GPS or permission checks.
  /// Deduplicates concurrent in-flight requests.
  Future<void> determinePosition({
    bool forceRefresh = false,
    Duration freshnessLimit = const Duration(minutes: 15),
  }) {
    // If not forcing refresh and state already has fresh location, reuse cached location immediately.
    if (!forceRefresh && state.isFresh(maxAge: freshnessLimit)) {
      return Future.value();
    }

    // In-flight request deduplication: return the active future if one is running
    if (_inFlightRequest != null) {
      return _inFlightRequest!;
    }

    final future = _executeDeterminePosition(forceRefresh: forceRefresh);
    _inFlightRequest = future.whenComplete(() {
      _inFlightRequest = null;
    });

    return _inFlightRequest!;
  }

  Future<void> _executeDeterminePosition({bool forceRefresh = false}) async {
    // Only show full loading if we do not already have a valid location.
    // This prevents UI flickering and disappearing food feeds during background refreshes.
    if (!state.hasLocation) {
      state = const LocationState.loading();
    }

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
      final now = DateTime.now();
      _lastSuccessfulFetch = now;
      state = LocationState.available(
        position.latitude,
        position.longitude,
        state.customName,
        now,
      );
    } on TimeoutException {
      state = const LocationState.error(
          'Location request timed out. Please try again.');
    } catch (_) {
      state = const LocationState.error(
          'Unable to determine location. Please try again.');
    }
  }

  void setMockLocation(double latitude, double longitude) {
    final now = DateTime.now();
    _lastSuccessfulFetch = now;
    state = LocationState.available(latitude, longitude, null, now);
  }

  void updateLocation(String newLocation,
      {double? latitude, double? longitude}) {
    final clean = newLocation.trim();
    if (clean.isEmpty) return;

    double lat = latitude ?? 16.4971;
    double lon = longitude ?? 80.5005;

    if (latitude == null || longitude == null) {
      for (final entry in presetCoordinates.entries) {
        if (clean.toLowerCase().contains(entry.key.toLowerCase())) {
          lat = entry.value.$1;
          lon = entry.value.$2;
          break;
        }
      }
    }

    final now = DateTime.now();
    _lastSuccessfulFetch = now;
    state = LocationState.available(lat, lon, clean, now);
  }

  void resetToDefault() {
    state = const LocationState.initial();
    _lastSuccessfulFetch = null;
    determinePosition(forceRefresh: true);
  }

  /// Clears cached coordinates and resets to initial state (e.g. on user logout).
  void clearLocation() {
    _lastSuccessfulFetch = null;
    _inFlightRequest = null;
    state = const LocationState.initial();
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});

final radiusProvider = StateProvider<double>((ref) {
  return 2.0; // Default radius: 2.0 km
});
