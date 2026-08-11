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

  const LocationState({
    required this.status,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });

  const LocationState.initial() : this(status: LocationStateStatus.initial);
  const LocationState.loading() : this(status: LocationStateStatus.loading);
  const LocationState.permissionDenied() : this(status: LocationStateStatus.permissionDenied);
  const LocationState.permissionPermanentlyDenied() : this(status: LocationStateStatus.permissionPermanentlyDenied);
  const LocationState.serviceDisabled() : this(status: LocationStateStatus.serviceDisabled);
  const LocationState.available(double lat, double lon) : this(status: LocationStateStatus.available, latitude: lat, longitude: lon);
  const LocationState.error(String message) : this(status: LocationStateStatus.error, errorMessage: message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ latitude.hashCode ^ longitude.hashCode ^ errorMessage.hashCode;

  @override
  String toString() {
    return 'LocationState(status: $status, latitude: $latitude, longitude: $longitude, errorMessage: $errorMessage)';
  }
}
