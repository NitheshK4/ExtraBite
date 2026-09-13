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
  final DateTime? lastUpdated;

  const LocationState({
    required this.status,
    this.latitude,
    this.longitude,
    this.errorMessage,
    this.customName,
    this.lastUpdated,
  });

  const LocationState.initial() : this(status: LocationStateStatus.initial);
  const LocationState.loading(
      {double? latitude,
      double? longitude,
      String? customName,
      DateTime? lastUpdated})
      : this(
          status: LocationStateStatus.loading,
          latitude: latitude,
          longitude: longitude,
          customName: customName,
          lastUpdated: lastUpdated,
        );
  const LocationState.permissionDenied()
      : this(status: LocationStateStatus.permissionDenied);
  const LocationState.permissionPermanentlyDenied()
      : this(status: LocationStateStatus.permissionPermanentlyDenied);
  const LocationState.serviceDisabled()
      : this(status: LocationStateStatus.serviceDisabled);
  const LocationState.available(double lat, double lon,
      [String? name, DateTime? updatedAt])
      : this(
            status: LocationStateStatus.available,
            latitude: lat,
            longitude: lon,
            customName: name,
            lastUpdated: updatedAt);
  const LocationState.error(String message)
      : this(status: LocationStateStatus.error, errorMessage: message);

  /// Whether valid coordinates are present in the state.
  bool get hasLocation => latitude != null && longitude != null;

  /// Whether location is successfully resolved and coordinates exist.
  bool get isAvailable =>
      status == LocationStateStatus.available && hasLocation;

  /// Returns true if valid coordinates are present and fresh within [maxAge].
  bool isFresh({Duration maxAge = const Duration(minutes: 15)}) {
    if (!isAvailable || lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated!) < maxAge;
  }

  LocationState copyWith({
    LocationStateStatus? status,
    double? latitude,
    double? longitude,
    String? errorMessage,
    String? customName,
    DateTime? lastUpdated,
  }) {
    return LocationState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      errorMessage: errorMessage ?? this.errorMessage,
      customName: customName ?? this.customName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get displayName {
    if (customName != null && customName!.isNotEmpty) {
      return customName!;
    }
    if (status == LocationStateStatus.loading) {
      return hasLocation
          ? 'Refreshing location...'
          : 'Detecting your location...';
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
          customName == other.customName &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      status.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      errorMessage.hashCode ^
      customName.hashCode ^
      lastUpdated.hashCode;

  @override
  String toString() {
    return 'LocationState(status: $status, latitude: $latitude, longitude: $longitude, errorMessage: $errorMessage, customName: $customName, lastUpdated: $lastUpdated)';
  }
}
