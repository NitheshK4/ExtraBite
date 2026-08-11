import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationNotifier extends StateNotifier<String> {
  LocationNotifier() : super('Near VIT-AP University');

  void updateLocation(String newLocation) {
    if (newLocation.trim().isNotEmpty) {
      state = newLocation.trim();
    }
  }

  void resetToDefault() {
    state = 'Near VIT-AP University';
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, String>((ref) {
  return LocationNotifier();
});
