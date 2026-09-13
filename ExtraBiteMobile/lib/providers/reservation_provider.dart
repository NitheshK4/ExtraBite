import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/reservation.dart';
import '../models/food_listing.dart';
import '../models/order_type.dart';
import '../core/repositories/reservation_repository.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  try {
    return ReservationRepository(supabase.Supabase.instance.client);
  } catch (_) {
    return ReservationRepository.fakeForTest();
  }
});

class ReservationNotifier extends StateNotifier<List<Reservation>> {
  final ReservationRepository _repository;

  ReservationNotifier(this._repository) : super(const []);

  Future<Reservation> createReservation({
    required FoodListing listing,
    required int quantity,
    OrderType orderType = OrderType.takeAway,
    String paymentMethod = 'Pay at Counter / Direct UPI',
  }) async {
    final response = await _repository.reserveFood(
      listingId: listing.id,
      quantity: quantity,
    );
    final newReservation = Reservation.fromSupabase(
      response,
      {
        'title': listing.foodName,
        'pickup_start_time': listing.pickupStarts.toIso8601String(),
        'pickup_end_time': listing.pickupEnds.toIso8601String(),
      },
      {
        'pg_name': listing.propertyName,
      },
    );
    state = [newReservation, ...state];
    return newReservation;
  }

  Future<void> loadCustomerReservations(String customerId) async {
    try {
      final data = await _repository.fetchCustomerReservations(customerId);
      final List<Reservation> list = [];
      for (final row in data) {
        final foodRow = row['food_listings'] as Map<String, dynamic>?;
        if (foodRow != null) {
          final pgRow = foodRow['pg_profiles'] as Map<String, dynamic>?;
          if (pgRow != null) {
            list.add(Reservation.fromSupabase(row, foodRow, pgRow));
          }
        }
      }
      state = list;
    } catch (_) {
      // Keep local state on error
    }
  }

  Future<void> loadOwnerReservations() async {
    try {
      final data = await _repository.fetchOwnerReservations();
      final List<Reservation> list = [];
      for (final row in data) {
        final foodRow = row['food_listings'] as Map<String, dynamic>?;
        if (foodRow != null) {
          final pgRow = foodRow['pg_profiles'] as Map<String, dynamic>?;
          if (pgRow != null) {
            list.add(Reservation.fromSupabase(row, foodRow, pgRow));
          }
        }
      }
      state = list;
    } catch (_) {
      // Keep local state on error
    }
  }

  Future<void> updateStatus(String id, String newStatus) async {
    try {
      final row = await _repository.updateReservationStatus(id, newStatus);
      final statusStr = row['status'] as String? ?? 'confirmed';
      ReservationStatus status;
      if (statusStr == 'confirmed' || statusStr == 'ready_for_pickup' || statusStr == 'draft') {
        status = ReservationStatus.reserved;
      } else if (statusStr == 'picked_up' || statusStr == 'completed') {
        status = ReservationStatus.completed;
      } else {
        status = ReservationStatus.cancelled;
      }

      state = state.map((res) {
        if (res.id == row['readable_id'] || res.id == row['id'] || res.id == id) {
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
            status: status,
            orderType: res.orderType,
            paymentStatus: res.paymentStatus,
            paymentMethod: res.paymentMethod,
          );
        }
        return res;
      }).toList();
    } catch (_) {
      if (newStatus == 'cancelled') {
        cancelLocalOnly(id);
      }
    }
  }

  void cancelLocalOnly(String id) {
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

  Future<void> cancelReservation(String id) async {
    await updateStatus(id, 'cancelled');
  }
}

final reservationProvider = StateNotifierProvider<ReservationNotifier, List<Reservation>>((ref) {
  final repo = ref.read(reservationRepositoryProvider);
  return ReservationNotifier(repo);
});

final activeReservationsProvider = Provider<List<Reservation>>((ref) {
  final list = ref.watch(reservationProvider);
  return list.where((item) => item.status == ReservationStatus.reserved).toList();
});

final pastReservationsProvider = Provider<List<Reservation>>((ref) {
  final list = ref.watch(reservationProvider);
  return list.where((item) => item.status != ReservationStatus.reserved).toList();
});
