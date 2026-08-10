import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reservation_model.dart';
import '../../models/food_listing_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/qr_codec.dart';
import '../demo/seed_data.dart';
import 'listing_repository.dart';

class ReservationNotifier extends StateNotifier<List<ReservationModel>> {
  final Ref _ref;

  ReservationNotifier(this._ref) : super(SeedData.generateReservations());

  List<ReservationModel> getCustomerActiveReservations(String customerId) {
    return state
        .where((r) => r.customerId == customerId && r.status.isActive && !r.isExpired)
        .toList();
  }

  List<ReservationModel> getCustomerReservationHistory(String customerId) {
    return state
        .where((r) => r.customerId == customerId && (!r.status.isActive || r.isExpired))
        .toList();
  }

  List<ReservationModel> getOwnerReservationsQueue(String pgId) {
    return state.where((r) => r.pgId == pgId && r.status.isActive).toList();
  }

  List<ReservationModel> getOwnerCompletedPickups(String pgId) {
    return state.where((r) => r.pgId == pgId && r.status == ReservationStatus.pickedUp).toList();
  }

  ReservationModel? getReservationById(String id) {
    try {
      return state.firstWhere((r) => r.id == id || r.readableId == id);
    } catch (_) {
      return null;
    }
  }

  /// Creates a new reservation and decrements listing inventory
  ReservationModel? createReservation({
    required FoodListingModel listing,
    required UserModel customer,
    required int portionsCount,
  }) {
    // 1. Validate remaining portions in listing repository
    final success = _ref
        .read(listingProvider.notifier)
        .decrementPortions(listing.id, portionsCount);

    if (!success) return null; // Overselling prevented

    final now = DateTime.now();
    final randomDigits = (10000 + Random().nextInt(90000)).toString();
    final readableId = 'EB-$randomDigits';
    final pickupToken = 'TOK-${1000 + Random().nextInt(9000)}';

    // Generate signed QR payload
    final qrPayload = QrCodec.encode(
      reservationId: readableId,
      pickupToken: pickupToken,
      pgId: listing.pgId,
      portions: portionsCount,
      expiresAt: listing.pickupEndTime,
    );

    final reservation = ReservationModel(
      id: 'res_${now.millisecondsSinceEpoch}',
      readableId: readableId,
      listingId: listing.id,
      listingTitle: listing.title,
      pgId: listing.pgId,
      pgName: listing.pgName,
      customerId: customer.id,
      customerName: customer.fullName,
      customerPhone: customer.phoneNumber ?? '',
      portionsCount: portionsCount,
      unitPrice: listing.discountedPrice,
      totalAmount: listing.discountedPrice * portionsCount,
      paymentMethod: AppConstants.paymentMethodLabel,
      status: ReservationStatus.confirmed,
      pickupToken: pickupToken,
      qrPayload: qrPayload,
      pickupStartTime: listing.pickupStartTime,
      pickupDeadline: listing.pickupEndTime,
      pickupInstructions: listing.pickupInstructions,
      pgAddress: listing.address,
      pgLatitude: listing.latitude,
      pgLongitude: listing.longitude,
      createdAt: now,
    );

    state = [reservation, ...state];
    return reservation;
  }

  /// Cancels a reservation and restores portions back to the listing
  bool cancelReservation(String reservationId, {String reason = 'Customer cancelled'}) {
    final index = state.indexWhere((r) => r.id == reservationId || r.readableId == reservationId);
    if (index == -1) return false;

    final current = state[index];
    if (!current.canCancel) return false;

    // Restore portions
    _ref
        .read(listingProvider.notifier)
        .restorePortions(current.listingId, current.portionsCount);

    final updated = current.copyWith(
      status: ReservationStatus.cancelled,
      cancellationReason: reason,
    );

    final list = [...state];
    list[index] = updated;
    state = list;
    return true;
  }

  /// Completes pickup verification (via QR scan or manual code confirmation)
  bool completePickup(String reservationId) {
    final index = state.indexWhere((r) => r.id == reservationId || r.readableId == reservationId);
    if (index == -1) return false;

    final current = state[index];
    if (current.status == ReservationStatus.pickedUp || current.status == ReservationStatus.cancelled) {
      return false;
    }

    final updated = current.copyWith(
      status: ReservationStatus.pickedUp,
      pickedUpAt: DateTime.now(),
    );

    final list = [...state];
    list[index] = updated;
    state = list;
    return true;
  }

  void markReadyForPickup(String reservationId) {
    final index = state.indexWhere((r) => r.id == reservationId || r.readableId == reservationId);
    if (index != -1) {
      final list = [...state];
      list[index] = list[index].copyWith(status: ReservationStatus.readyForPickup);
      state = list;
    }
  }
}

final reservationProvider =
    StateNotifierProvider<ReservationNotifier, List<ReservationModel>>((ref) {
  return ReservationNotifier(ref);
});
