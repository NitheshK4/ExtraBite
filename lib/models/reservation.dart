enum ReservationStatus {
  reserved,
  pickedUp,
  cancelled,
  expired;

  String get label {
    switch (this) {
      case ReservationStatus.reserved:
        return 'Reserved (Pay at Pickup)';
      case ReservationStatus.pickedUp:
        return 'Picked Up';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.expired:
        return 'Expired';
    }
  }
}

class Reservation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String pgName;
  final String customerName;
  final String customerPhone;
  final int portions;
  final double totalPrice; // Pay at pickup amount
  final DateTime reservedAt;
  final String pickupWindow;
  final ReservationStatus status;
  final String qrCodeData;
  final String pickupPasscode;

  Reservation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.pgName,
    required this.customerName,
    required this.customerPhone,
    required this.portions,
    required this.totalPrice,
    required this.reservedAt,
    required this.pickupWindow,
    required this.status,
    required this.qrCodeData,
    required this.pickupPasscode,
  });

  Reservation copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? pgName,
    String? customerName,
    String? customerPhone,
    int? portions,
    double? totalPrice,
    DateTime? reservedAt,
    String? pickupWindow,
    ReservationStatus? status,
    String? qrCodeData,
    String? pickupPasscode,
  }) {
    return Reservation(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      pgName: pgName ?? this.pgName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      portions: portions ?? this.portions,
      totalPrice: totalPrice ?? this.totalPrice,
      reservedAt: reservedAt ?? this.reservedAt,
      pickupWindow: pickupWindow ?? this.pickupWindow,
      status: status ?? this.status,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      pickupPasscode: pickupPasscode ?? this.pickupPasscode,
    );
  }
}
