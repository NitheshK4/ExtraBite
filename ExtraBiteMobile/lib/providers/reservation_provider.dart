import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../models/food_listing.dart';

class ReservationNotifier extends StateNotifier<List<Reservation>> {
  ReservationNotifier() : super(_getInitialMockReservations());

  static List<Reservation> _getInitialMockReservations() {
    final now = DateTime.now();
    return [
      Reservation(
        id: 'EB10293',
        foodListingId: '4',
        foodName: 'Paneer Rice',
        propertyName: 'Stanza Living Delhi PG',
        quantity: 2,
        amountToCollect: 100.0,
        pickupStarts: now.subtract(const Duration(hours: 1)),
        pickupEnds: now.add(const Duration(hours: 2, minutes: 30)),
        reservedAt: now.subtract(const Duration(minutes: 45)),
        status: ReservationStatus.reserved,
      ),
      Reservation(
        id: 'EB09821',
        foodListingId: '1',
        foodName: 'Veg Meals',
        propertyName: 'Sri Sai Deluxe PG',
        quantity: 1,
        amountToCollect: 40.0,
        pickupStarts: now.subtract(const Duration(days: 1, hours: 2)),
        pickupEnds: now.subtract(const Duration(days: 1)),
        reservedAt: now.subtract(const Duration(days: 1, hours: 2, minutes: 15)),
        status: ReservationStatus.completed,
      ),
      Reservation(
        id: 'EB09124',
        foodListingId: '3',
        foodName: 'Idli & Vada Combo',
        propertyName: 'Green Gardens PG',
        quantity: 3,
        amountToCollect: 75.0,
        pickupStarts: now.subtract(const Duration(days: 3, hours: 4)),
        pickupEnds: now.subtract(const Duration(days: 3, hours: 2)),
        reservedAt: now.subtract(const Duration(days: 3, hours: 4, minutes: 10)),
        status: ReservationStatus.cancelled,
      ),
    ];
  }

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
