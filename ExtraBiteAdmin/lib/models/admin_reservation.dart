class AdminReservation {
  final String id;
  final String readableId;
  final String listingId;
  final String foodTitle;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String pgName;
  final int portionsCount;
  final double unitPrice;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final DateTime pickupDeadline;
  final DateTime? pickedUpAt;
  final String? cancellationReason;
  final DateTime createdAt;

  AdminReservation({
    required this.id,
    required this.readableId,
    required this.listingId,
    required this.foodTitle,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.pgName,
    required this.portionsCount,
    required this.unitPrice,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.pickupDeadline,
    this.pickedUpAt,
    this.cancellationReason,
    required this.createdAt,
  });

  factory AdminReservation.fromJson(Map<String, dynamic> json) {
    final food = json['food_listings'] as Map<String, dynamic>?;
    final foodTitle = food != null ? (food['title'] as String? ?? 'Surplus Meal') : 'Surplus Meal';
    final pg = food?['pg_profiles'] as Map<String, dynamic>?;
    final pgName = pg != null ? (pg['pg_name'] as String? ?? 'PG Mess') : 'PG Mess';

    final profile = json['profiles'] as Map<String, dynamic>?;
    final customerName = profile != null ? (profile['full_name'] as String? ?? 'Student') : 'Student';
    final customerEmail = profile != null ? (profile['email'] as String? ?? '') : '';

    return AdminReservation(
      id: json['id'] as String,
      readableId: json['readable_id'] as String? ?? ('#EB-${json['id'].toString().substring(0, 5).toUpperCase()}'),
      listingId: json['listing_id'] as String? ?? '',
      foodTitle: foodTitle,
      customerId: json['customer_id'] as String? ?? '',
      customerName: customerName,
      customerEmail: customerEmail,
      pgName: pgName,
      portionsCount: (json['portions_count'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 25.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 25.0,
      paymentMethod: json['payment_method'] as String? ?? 'pay_at_pickup',
      status: json['status'] as String? ?? 'confirmed',
      pickupDeadline: json['pickup_deadline'] != null
          ? DateTime.parse(json['pickup_deadline'] as String)
          : DateTime.now().add(const Duration(hours: 2)),
      pickedUpAt: json['picked_up_at'] != null ? DateTime.tryParse(json['picked_up_at'] as String) : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
