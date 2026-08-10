import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../models/food_listing.dart';
import 'food_provider.dart';

class ReservationNotifier extends StateNotifier<List<Reservation>> {
  ReservationNotifier(this.ref) : super(_getInitialReservations());

  final Ref ref;

  static List<Reservation> _getInitialReservations() {
    final now = DateTime.now();
    return [
      Reservation(
        id: 'res_101',
        listingId: 'food_001',
        listingTitle: 'Paneer Butter Masala & Rotis',
        pgName: 'Sunrise Executive Boys PG',
        customerName: 'Alex Kumar',
        customerPhone: '+91 98765 43210',
        portions: 2,
        totalPrice: 90.0, // Pay at pickup: ₹90 total
        reservedAt: now.subtract(const Duration(minutes: 15)),
        pickupWindow: 'Today by 10:30 PM',
        status: ReservationStatus.reserved,
        qrCodeData: 'EXTRABITE:res_101:CODE_8492',
        pickupPasscode: '8492',
      ),
    ];
  }

  Reservation createReservation({
    required FoodListing listing,
    required String customerName,
    required String customerPhone,
    required int portions,
  }) {
    final now = DateTime.now();
    final randomCode = (1000 + Random().nextInt(9000)).toString();
    final resId = 'res_${now.millisecondsSinceEpoch.toString().substring(7)}';

    final reservation = Reservation(
      id: resId,
      listingId: listing.id,
      listingTitle: listing.title,
      pgName: listing.pgName,
      customerName: customerName,
      customerPhone: customerPhone,
      portions: portions,
      totalPrice: listing.pickupPrice * portions,
      reservedAt: now,
      pickupWindow: 'Pickup before ${listing.expiresAt.hour}:${listing.expiresAt.minute.toString().padLeft(2, '0')}',
      status: ReservationStatus.reserved,
      qrCodeData: 'EXTRABITE:$resId:CODE_$randomCode',
      pickupPasscode: randomCode,
    );

    // Add to reservations state
    state = [reservation, ...state];

    // Deduct available portions in foodProvider
    ref.read(foodProvider.notifier).decrementPortions(listing.id, portions);

    return reservation;
  }

  bool verifyAndCompletePickup(String qrOrPasscode) {
    for (int i = 0; i < state.length; i++) {
      final res = state[i];
      if (res.status == ReservationStatus.reserved) {
        if (res.qrCodeData == qrOrPasscode ||
            res.pickupPasscode == qrOrPasscode ||
            qrOrPasscode.contains(res.id) ||
            qrOrPasscode.contains(res.pickupPasscode)) {
          final updated = res.copyWith(status: ReservationStatus.pickedUp);
          final list = List<Reservation>.from(state);
          list[i] = updated;
          state = list;
          return true; // Pickup successfully verified!
        }
      }
    }
    return false; // Code/QR not found or already redeemed
  }

  void cancelReservation(String id) {
    state = state.map((res) {
      if (res.id == id) {
        return res.copyWith(status: ReservationStatus.cancelled);
      }
      return res;
    }).toList();
  }
}

final reservationProvider =
    StateNotifierProvider<ReservationNotifier, List<Reservation>>((ref) {
  return ReservationNotifier(ref);
});
