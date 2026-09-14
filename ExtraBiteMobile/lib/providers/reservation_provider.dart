import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/reservation.dart';
import '../models/food_listing.dart';
import '../models/order_type.dart';
import '../core/repositories/reservation_repository.dart';
import 'food_provider.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  try {
    return ReservationRepository(supabase.Supabase.instance.client);
  } catch (_) {
    return ReservationRepository.fakeForTest();
  }
});

class ReservationNotifier extends StateNotifier<List<Reservation>> {
  final ReservationRepository _repository;
  final Ref? _ref;
  final Set<String> _cancellingIds = {};

  ReservationNotifier(this._repository, [this._ref]) : super(const []);

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
    if (newStatus == 'cancelled') {
      await cancelReservation(id);
      return;
    }

    final row = await _repository.updateReservationStatus(id, newStatus);
    final statusStr = row['status'] as String? ?? 'confirmed';
    ReservationStatus status;
    if (statusStr == 'confirmed' ||
        statusStr == 'ready_for_pickup' ||
        statusStr == 'draft') {
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

  /// Cancels an active reservation atomically.
  /// Deduplicates concurrent cancellation requests, updates the database,
  /// restores portions to the related food listing, and updates local state.
  Future<void> cancelReservation(String id, {String? reason}) async {
    // Prevent duplicate concurrent cancellation calls for the same reservation ID
    if (_cancellingIds.contains(id)) return;
    _cancellingIds.add(id);

    try {
      // Find the existing reservation to identify foodListingId and portion quantity
      final reservation = state.cast<Reservation?>().firstWhere(
            (r) => r?.id == id,
            orElse: () => null,
          );

      // If already cancelled, do not restore inventory again (idempotent)
      if (reservation != null &&
          reservation.status == ReservationStatus.cancelled) {
        return;
      }

      // Call database RPC to atomically cancel and restore inventory
      final row = await _repository.cancelReservation(id, reason: reason);

      // Update local reservation state
      state = state.map((res) {
        if (res.id == row['readable_id'] ||
            res.id == row['id'] ||
            res.id == id) {
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

      // Restore available portions locally and trigger listings refresh
      if (reservation != null && _ref != null) {
        _ref.read(foodProvider.notifier).restorePortions(
              reservation.foodListingId,
              reservation.quantity,
            );
        // Load fresh listings from backend only in real Supabase mode
        if (!_repository.isFakeForTest) {
          _ref.read(foodProvider.notifier).loadListings();
        }
      }
    } finally {
      _cancellingIds.remove(id);
    }
  }
}

final reservationProvider =
    StateNotifierProvider<ReservationNotifier, List<Reservation>>((ref) {
  final repo = ref.read(reservationRepositoryProvider);
  return ReservationNotifier(repo, ref);
});

final activeReservationsProvider = Provider<List<Reservation>>((ref) {
  final list = ref.watch(reservationProvider);
  return list
      .where((item) => item.status == ReservationStatus.reserved)
      .toList();
});

final pastReservationsProvider = Provider<List<Reservation>>((ref) {
  final list = ref.watch(reservationProvider);
  return list
      .where((item) => item.status != ReservationStatus.reserved)
      .toList();
});
