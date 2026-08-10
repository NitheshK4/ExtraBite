enum ReservationStatus {
  reserved,
  completed,
  cancelled,
}

class Reservation {
  final String id;
  final String foodListingId;
  final String foodName;
  final String propertyName;
  final int quantity;
  final double amountToCollect;
  final DateTime pickupStarts;
  final DateTime pickupEnds;
  final DateTime reservedAt;
  final ReservationStatus status;

  Reservation({
    required this.id,
    required this.foodListingId,
    required this.foodName,
    required this.propertyName,
    required this.quantity,
    required this.amountToCollect,
    required this.pickupStarts,
    required this.pickupEnds,
    required this.reservedAt,
    required this.status,
  });
}
