import '../core/constants/app_constants.dart';

enum ReservationStatus {
  draft,
  confirmed,
  readyForPickup,
  pickedUp,
  cancelled,
  expired,
  noShow,
  rejected;

  String get displayName {
    switch (this) {
      case ReservationStatus.draft:
        return 'Draft';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.readyForPickup:
        return 'Ready for Pickup';
      case ReservationStatus.pickedUp:
        return 'Picked Up';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.expired:
        return 'Expired';
      case ReservationStatus.noShow:
        return 'No Show';
      case ReservationStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isActive =>
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.readyForPickup;
}

class ReservationModel {
  final String id;
  final String readableId; // e.g. EB-49120
  final String listingId;
  final String listingTitle;
  final String pgId;
  final String pgName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final int portionsCount;
  final double unitPrice;
  final double totalAmount;
  final String paymentMethod; // Always 'Pay at pickup'
  final ReservationStatus status;
  final String pickupToken;
  final String qrPayload;
  final DateTime pickupStartTime;
  final DateTime pickupDeadline;
  final String pickupInstructions;
  final String pgAddress;
  final double pgLatitude;
  final double pgLongitude;
  final DateTime? pickedUpAt;
  final String? cancellationReason;
  final DateTime createdAt;

  const ReservationModel({
    required this.id,
    required this.readableId,
    required this.listingId,
    required this.listingTitle,
    required this.pgId,
    required this.pgName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.portionsCount,
    required this.unitPrice,
    required this.totalAmount,
    this.paymentMethod = AppConstants.paymentMethodLabel,
    this.status = ReservationStatus.confirmed,
    required this.pickupToken,
    required this.qrPayload,
    required this.pickupStartTime,
    required this.pickupDeadline,
    required this.pickupInstructions,
    required this.pgAddress,
    required this.pgLatitude,
    required this.pgLongitude,
    this.pickedUpAt,
    this.cancellationReason,
    required this.createdAt,
  });

  /// Cancellation is permitted only if before the cutoff window (e.g. 15m before deadline)
  bool get canCancel {
    if (!status.isActive) return false;
    final cutoffTime = pickupDeadline.subtract(
      const Duration(minutes: AppConstants.cancelCutoffMinutes),
    );
    return DateTime.now().isBefore(cutoffTime);
  }

  bool get isExpired {
    if (status == ReservationStatus.pickedUp || status == ReservationStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(pickupDeadline);
  }

  ReservationModel copyWith({
    String? id,
    String? readableId,
    String? listingId,
    String? listingTitle,
    String? pgId,
    String? pgName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    int? portionsCount,
    double? unitPrice,
    double? totalAmount,
    String? paymentMethod,
    ReservationStatus? status,
    String? pickupToken,
    String? qrPayload,
    DateTime? pickupStartTime,
    DateTime? pickupDeadline,
    String? pickupInstructions,
    String? pgAddress,
    double? pgLatitude,
    double? pgLongitude,
    DateTime? pickedUpAt,
    String? cancellationReason,
    DateTime? createdAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      readableId: readableId ?? this.readableId,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      pgId: pgId ?? this.pgId,
      pgName: pgName ?? this.pgName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      portionsCount: portionsCount ?? this.portionsCount,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      pickupToken: pickupToken ?? this.pickupToken,
      qrPayload: qrPayload ?? this.qrPayload,
      pickupStartTime: pickupStartTime ?? this.pickupStartTime,
      pickupDeadline: pickupDeadline ?? this.pickupDeadline,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      pgAddress: pgAddress ?? this.pgAddress,
      pgLatitude: pgLatitude ?? this.pgLatitude,
      pgLongitude: pgLongitude ?? this.pgLongitude,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'readable_id': readableId,
        'listing_id': listingId,
        'listing_title': listingTitle,
        'pg_id': pgId,
        'pg_name': pgName,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'portions_count': portionsCount,
        'unit_price': unitPrice,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'status': status.name,
        'pickup_token': pickupToken,
        'qr_payload': qrPayload,
        'pickup_start_time': pickupStartTime.toIso8601String(),
        'pickup_deadline': pickupDeadline.toIso8601String(),
        'pickup_instructions': pickupInstructions,
        'pg_address': pgAddress,
        'pg_latitude': pgLatitude,
        'pg_longitude': pgLongitude,
        'picked_up_at': pickedUpAt?.toIso8601String(),
        'cancellation_reason': cancellationReason,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      readableId: json['readable_id'] as String,
      listingId: json['listing_id'] as String,
      listingTitle: json['listing_title'] as String? ?? 'ExtraBite Meal',
      pgId: json['pg_id'] as String,
      pgName: json['pg_name'] as String? ?? 'PG Host',
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String? ?? 'Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      portionsCount: json['portions_count'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? AppConstants.paymentMethodLabel,
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReservationStatus.confirmed,
      ),
      pickupToken: json['pickup_token'] as String,
      qrPayload: json['qr_payload'] as String,
      pickupStartTime: DateTime.parse(json['pickup_start_time'] as String),
      pickupDeadline: DateTime.parse(json['pickup_deadline'] as String),
      pickupInstructions: json['pickup_instructions'] as String? ?? '',
      pgAddress: json['pg_address'] as String? ?? '',
      pgLatitude: (json['pg_latitude'] as num?)?.toDouble() ?? AppConstants.defaultLatitude,
      pgLongitude: (json['pg_longitude'] as num?)?.toDouble() ?? AppConstants.defaultLongitude,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.parse(json['picked_up_at'] as String) : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
