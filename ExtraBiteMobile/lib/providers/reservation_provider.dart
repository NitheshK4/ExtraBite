import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../models/food_listing.dart';

class ReservationNotifier extends StateNotifier<List<Reservation>> {
  // Starts with clean empty reservations for real-time order flows
  ReservationNotifier() : super(const []);

  Reservation createReservation({
    required FoodListing listing,
    required int quantity,
  }) {
    final now = DateTime.now();
    final randomId = 'EB${10000 + Random().nextInt(90000)}';
    
    final newReservation = Reservation(
      id: randomId,
      foodListingId: listing.id,
      foodName: listing.foodName,
      propertyName: listing.propertyName,
      quantity: quantity,
      amountToCollect: listing.sellingPrice * quantity,
      pickupStarts: listing.pickupStarts,
      pickupEnds: listing.pickupEnds,
      reservedAt: now,
      status: ReservationStatus.reserved,
    );

    state = [newReservation, ...state];
    return newReservation;
  }

  void cancelReservation(String id) {
    state = state.map((res) {
      if (res.id == id) {
        return Reservation(
          id: res.id,
          foodListingId: res.foodListingId,
          foodName: res.foodName,
          propertyName: res.propertyName,
          quantity: res.quantity,
          amountToCollect: res.amountToCollect,
          pickupStarts: res.pickupStarts,
          pickupEnds: res.pickupEnds,
          reservedAt: res.reservedAt,
          status: ReservationStatus.cancelled,
        );
      }
      return res;
    }).toList();
  }
}

final reservationProvider = StateNotifierProvider<ReservationNotifier, List<Reservation>>((ref) {
  return ReservationNotifier();
});

final activeReservationsProvider = Provider<List<Reservation>>((ref) {
  final list = ref.watch(reservationProvider);
  return list.where((item) => item.status == ReservationStatus.reserved).toList();
});

final pastReservationsProvider = Provider<List<Reservation>>((ref) {
  final list = ref.watch(reservationProvider);
  return list.where((item) => item.status != ReservationStatus.reserved).toList();
});
