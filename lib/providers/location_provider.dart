import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationState {
  final double latitude;
  final double longitude;
  final double radiusKm; // Default 2.0 km
  final String currentArea;
  final bool isLoadingLocation;

  LocationState({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 2.0, // Strict requirement: Default nearby radius of 2 km
    this.currentArea = 'Koramangala 5th Block, Bengaluru',
    this.isLoadingLocation = false,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? currentArea,
    bool? isLoadingLocation,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      currentArea: currentArea ?? this.currentArea,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier()
      : super(LocationState(
          latitude: 12.9352,
          longitude: 77.6245,
          radiusKm: 2.0, // 2 km default requirement
        ));

  void updateRadius(double newRadiusKm) {
    state = state.copyWith(radiusKm: newRadiusKm);
  }

  void updateCoordinates(double lat, double lng, String area) {
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      currentArea: area,
    );
  }

  // Haversine distance formula in kilometers
  double calculateDistance(double targetLat, double targetLng) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(targetLat - state.latitude);
    double dLon = _degreesToRadians(targetLng - state.longitude);

    double lat1 = _degreesToRadians(state.latitude);
    double lat2 = _degreesToRadians(targetLat);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
