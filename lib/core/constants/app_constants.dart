class AppConstants {
  static const String appName = 'ExtraBite';
  static const String appTagline = 'Good food shouldn\'t go to waste';

  // Distance & Location
  static const double defaultRadiusKm = 2.0;
  static const List<double> radiusOptionsKm = [1.0, 2.0, 5.0, 10.0];
  static const double defaultLatitude = 12.9716; // Bengaluru central
  static const double defaultLongitude = 77.5946;

  // Reservation Timing
  static const int cancelCutoffMinutes = 15; // Can cancel until 15m before pickup window ends
  static const int qrVersion = 1;
  static const String qrSecretPrefix = 'EB_SEC_';

  // Payment Rule (Invariant)
  static const String paymentMethodLabel = 'Pay at pickup';
  static const String paymentInstruction = 'Pay directly to the PG/Hostel manager when you collect your meal in person.';
}
