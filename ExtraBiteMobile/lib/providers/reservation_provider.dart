import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../models/food_listing.dart';
import '../models/order_type.dart';

class ReservationNotifier extends StateNotifier<List<Reservation>> {
  ReservationNotifier() : super(_initialSeedReservations());

  static List<Reservation> _initialSeedReservations() {
    final now = DateTime.now();
    return [
      Reservation(
        id: 'EB84920',
        foodListingId: 'fl_seed_1',
        foodName: 'Special South Indian Thali',
        propertyName: 'Sri Sai PG',
        quantity: 2,
        amountToCollect: 60.0,
        pickupStarts: now.subtract(const Duration(minutes: 30)),
        pickupEnds: now.add(const Duration(hours: 2)),
        reservedAt: now.subtract(const Duration(minutes: 35)),
        status: ReservationStatus.reserved,
        orderType: OrderType.dineIn,
      ),
      Reservation(
        id: 'EB92831',
        foodListingId: 'fl_seed_2',
        foodName: 'Paneer Butter Masala + Roti',
        propertyName: 'Lakshmi Hostel',
        quantity: 1,
        amountToCollect: 45.0,
        pickupStarts: now.subtract(const Duration(minutes: 15)),
        pickupEnds: now.add(const Duration(hours: 1)),
        reservedAt: now.subtract(const Duration(minutes: 20)),
        status: ReservationStatus.reserved,
        orderType: OrderType.takeAway,
      ),
      Reservation(
        id: 'EB10482',
        foodListingId: 'fl_seed_3',
        foodName: 'Chicken Biryani Parcel',
        propertyName: 'Vijaya PG',
        quantity: 1,
        amountToCollect: 75.0,
        pickupStarts: now.subtract(const Duration(hours: 24)),
        pickupEnds: now.subtract(const Duration(hours: 22)),
        reservedAt: now.subtract(const Duration(hours: 25)),
        status: ReservationStatus.completed,
        orderType: null, // Legacy order without orderType field to test backward compatibility
      ),
    ];
  }

  Reservation createReservation({
    required FoodListing listing,
    required int quantity,
    required OrderType orderType,
    String paymentMethod = 'Online Platform (UPI / Card)',
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
      orderType: orderType,
      paymentStatus: 'paid',
      paymentMethod: paymentMethod,
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
          orderType: res.orderType,
          paymentStatus: res.paymentStatus,
          paymentMethod: res.paymentMethod,
        );
      }
      return res;
    }).toList();
  }

  void completeReservation(String id) {
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
          status: ReservationStatus.completed,
          orderType: res.orderType,
          paymentStatus: res.paymentStatus,
          paymentMethod: res.paymentMethod,
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

