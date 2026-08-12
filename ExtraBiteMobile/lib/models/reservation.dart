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
  final OrderType? orderType; // Nullable for legacy backward compatibility

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
    this.orderType,
  });

  String get orderTypeDisplayName {
    if (orderType == null) return 'Legacy Order';
    return orderType!.displayName;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_listing_id': foodListingId,
      'food_name': foodName,
      'property_name': propertyName,
      'quantity': quantity,
      'amount_to_collect': amountToCollect,
      'pickup_starts': pickupStarts.toIso8601String(),
      'pickup_ends': pickupEnds.toIso8601String(),
      'reserved_at': reservedAt.toIso8601String(),
      'status': status.name,
      'order_type': orderType?.code,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as String? ?? map['readable_id'] as String? ?? 'EB-00000',
      foodListingId: map['food_listing_id'] as String? ?? map['listing_id'] as String? ?? '',
      foodName: map['food_name'] as String? ?? map['title'] as String? ?? 'Surplus Meal',
      propertyName: map['property_name'] as String? ?? map['pg_name'] as String? ?? 'PG / Hostel',
      quantity: (map['quantity'] as num? ?? map['portions_count'] as num? ?? 1).toInt(),
      amountToCollect: (map['amount_to_collect'] as num? ?? map['total_amount'] as num? ?? 0.0).toDouble(),
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
    );
  }
}

