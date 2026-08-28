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
  final String? pickupToken;
  final String? qrPayload;
  final DateTime? pickupDeadline;
  final String rawStatus;

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
    this.pickupToken,
    this.qrPayload,
    this.pickupDeadline,
    this.rawStatus = 'confirmed',
  });

  factory Reservation.fromSupabase(
    Map<String, dynamic> row,
    Map<String, dynamic> foodRow,
    Map<String, dynamic> pgRow,
  ) {
    final statusStr = row['status'] as String? ?? 'confirmed';
    ReservationStatus status;
    if (statusStr == 'confirmed' || statusStr == 'ready_for_pickup' || statusStr == 'draft') {
      status = ReservationStatus.reserved;
    } else if (statusStr == 'picked_up' || statusStr == 'completed') {
      status = ReservationStatus.completed;
    } else {
      status = ReservationStatus.cancelled;
    }

    return Reservation(
      id: row['readable_id'] as String? ?? (row['id'] as String? ?? ''),
      foodListingId: row['listing_id'] as String? ?? '',
      foodName: foodRow['title'] as String? ?? 'Surplus Meal',
      propertyName: pgRow['pg_name'] as String? ?? 'ExtraBite PG',
      quantity: (row['portions_count'] as num?)?.toInt() ?? 1,
      amountToCollect: double.tryParse(row['total_amount']?.toString() ?? '0') ?? 0.0,
      pickupStarts: DateTime.tryParse(foodRow['pickup_start_time']?.toString() ?? '') ?? DateTime.now(),
      pickupEnds: DateTime.tryParse(foodRow['pickup_end_time']?.toString() ?? '') ?? DateTime.now(),
      reservedAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: status,
      pickupToken: row['pickup_token'] as String?,
      qrPayload: row['qr_payload'] as String?,
      pickupDeadline: row['pickup_deadline'] != null ? DateTime.tryParse(row['pickup_deadline'].toString()) : null,
      rawStatus: statusStr,
    );
  }
}
