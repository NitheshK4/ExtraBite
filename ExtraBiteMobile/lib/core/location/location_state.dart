enum LocationStateStatus {
  initial,
  loading,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  available,
  error,
}

class LocationState {
  final LocationStateStatus status;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;
  final String? customName;

  const LocationState({
    required this.status,
    this.latitude,
    this.longitude,
    this.errorMessage,
    this.customName,
  });

  const LocationState.initial() : this(status: LocationStateStatus.initial);
  const LocationState.loading() : this(status: LocationStateStatus.loading);
  const LocationState.permissionDenied() : this(status: LocationStateStatus.permissionDenied);
  const LocationState.permissionPermanentlyDenied() : this(status: LocationStateStatus.permissionPermanentlyDenied);
  const LocationState.serviceDisabled() : this(status: LocationStateStatus.serviceDisabled);
  const LocationState.available(double lat, double lon, [String? name]) : this(status: LocationStateStatus.available, latitude: lat, longitude: lon, customName: name);
  const LocationState.error(String message) : this(status: LocationStateStatus.error, errorMessage: message);

  String get displayName {
    if (customName != null && customName!.isNotEmpty) {
      return customName!;
    }
    if (status == LocationStateStatus.loading) {
      return 'Detecting your location...';
    }
    if (status == LocationStateStatus.available) {
      return 'Near VIT-AP University';
    }
    if (status == LocationStateStatus.error) {
      return errorMessage ?? 'Error';
    }
    if (status == LocationStateStatus.permissionDenied) {
      return 'Location permission required';
    }
    if (status == LocationStateStatus.serviceDisabled) {
      return 'Location services are turned off';
    }
    return 'Near VIT-AP University';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          errorMessage == other.errorMessage &&
          customName == other.customName;

  @override
  int get hashCode => status.hashCode ^ latitude.hashCode ^ longitude.hashCode ^ errorMessage.hashCode ^ customName.hashCode;

  @override
  String toString() {
    return 'LocationState(status: $status, latitude: $latitude, longitude: $longitude, errorMessage: $errorMessage, customName: $customName)';
  }
}
