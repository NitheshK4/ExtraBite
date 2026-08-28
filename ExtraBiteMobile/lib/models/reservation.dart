import 'order_type.dart';

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
  final OrderType? orderType; // Nullable for legacy backward compatibility
  final String paymentStatus; // 'paid', 'refunded', 'pending', etc.
  final String paymentMethod; // 'Pay at Counter', 'Online (UPI)', etc.

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
    this.orderType,
    this.paymentStatus = 'pending',
    this.paymentMethod = 'Pay at Counter / Direct UPI',
  });

  double get amountPaid => amountToCollect;

  bool get isPrepaid => paymentStatus.toLowerCase() == 'paid';

  String get orderTypeDisplayName {
    if (orderType == null) return 'Legacy Order';
    return orderType!.displayName;
  }

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
      orderType: OrderTypeExtension.fromCode(row['order_type'] as String?),
      paymentStatus: (row['payment_status'] as String?) ?? 'pending',
      paymentMethod: (row['payment_method'] as String?) ?? 'Pay at Counter / Direct UPI',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_listing_id': foodListingId,
      'food_name': foodName,
      'property_name': propertyName,
      'quantity': quantity,
      'amount_to_collect': amountToCollect,
      'amount_paid': amountPaid,
      'pickup_starts': pickupStarts.toIso8601String(),
      'pickup_ends': pickupEnds.toIso8601String(),
      'reserved_at': reservedAt.toIso8601String(),
      'status': status.name,
      'order_type': orderType?.code,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as String? ?? map['readable_id'] as String? ?? 'EB-00000',
      foodListingId: map['food_listing_id'] as String? ?? map['listing_id'] as String? ?? '',
      foodName: map['food_name'] as String? ?? map['title'] as String? ?? 'Surplus Meal',
      propertyName: map['property_name'] as String? ?? map['pg_name'] as String? ?? 'PG / Hostel',
      quantity: (map['quantity'] as num? ?? map['portions_count'] as num? ?? 1).toInt(),
      amountToCollect: (map['amount_to_collect'] as num? ?? map['amount_paid'] as num? ?? map['total_amount'] as num? ?? 0.0).toDouble(),
      pickupStarts: map['pickup_starts'] != null
          ? DateTime.parse(map['pickup_starts'] as String)
          : DateTime.now(),
      pickupEnds: map['pickup_ends'] != null
          ? DateTime.parse(map['pickup_ends'] as String)
          : map['pickup_deadline'] != null
              ? DateTime.parse(map['pickup_deadline'] as String)
              : DateTime.now().add(const Duration(hours: 2)),
      reservedAt: map['reserved_at'] != null
          ? DateTime.parse(map['reserved_at'] as String)
          : map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
      status: ReservationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ReservationStatus.reserved,
      ),
      orderType: OrderTypeExtension.fromCode(map['order_type'] as String?),
      paymentStatus: map['payment_status'] as String? ?? 'paid',
      paymentMethod: map['payment_method'] as String? ?? 'Online Platform (Prepaid)',
    );
  }
}
