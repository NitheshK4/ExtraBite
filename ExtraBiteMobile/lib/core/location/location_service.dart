import 'package:geolocator/geolocator.dart';

abstract class LocationService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}
