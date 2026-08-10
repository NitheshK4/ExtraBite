import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/haversine.dart';
import '../models/food_listing_model.dart';

class LocationState {
  final double latitude;
  final double longitude;
  final String humanReadableAddress;
  final double selectedRadiusKm;
  final bool isLiveGps;
  final bool hasPermission;

  const LocationState({
    required this.latitude,
    required this.longitude,
    this.humanReadableAddress = 'Bengaluru Central, Karnataka',
    this.selectedRadiusKm = AppConstants.defaultRadiusKm,
    this.isLiveGps = false,
    this.hasPermission = false,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    String? humanReadableAddress,
    double? selectedRadiusKm,
    bool? isLiveGps,
    bool? hasPermission,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      humanReadableAddress: humanReadableAddress ?? this.humanReadableAddress,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      isLiveGps: isLiveGps ?? this.isLiveGps,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier()
      : super(const LocationState(
          latitude: AppConstants.defaultLatitude,
          longitude: AppConstants.defaultLongitude,
        )) {
    checkAndFetchCurrentLocation();
  }

  Future<void> checkAndFetchCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(hasPermission: false, isLiveGps: false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(hasPermission: false, isLiveGps: false);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(hasPermission: false, isLiveGps: false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      String address = state.humanReadableAddress;
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = '${p.subLocality ?? p.locality ?? 'Nearby'}, ${p.administrativeArea ?? 'Bengaluru'}';
        }
      } catch (_) {
        address = 'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      }

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        humanReadableAddress: address,
        isLiveGps: true,
        hasPermission: true,
      );
    } catch (_) {
      // Fallback gracefully to default coordinates without crashing
      state = state.copyWith(isLiveGps: false);
    }
  }

  void updateRadius(double radiusKm) {
    state = state.copyWith(selectedRadiusKm: radiusKm);
  }

  void setManualLocation({
    required double latitude,
    required double longitude,
    required String neighborhoodName,
  }) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      humanReadableAddress: neighborhoodName,
      isLiveGps: false,
    );
  }

  /// Filters listings by selected radius from current user position using Haversine
  List<FoodListingModel> filterByRadius(List<FoodListingModel> listings) {
    return listings.where((listing) {
      return Haversine.isWithinRadius(
        state.latitude,
        state.longitude,
        listing.latitude,
        listing.longitude,
        state.selectedRadiusKm,
      );
    }).toList();
  }

  /// Computes distance in km to a given listing
  double distanceToListing(FoodListingModel listing) {
    return Haversine.calculateDistanceKm(
      state.latitude,
      state.longitude,
      listing.latitude,
      listing.longitude,
    );
  }

  String formattedDistanceToListing(FoodListingModel listing) {
    final dist = distanceToListing(listing);
    return Haversine.formatDistance(dist);
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
