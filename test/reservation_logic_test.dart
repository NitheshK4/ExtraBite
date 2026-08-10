import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:extrabite_mobile/data/repositories/listing_repository.dart';
import 'package:extrabite_mobile/data/repositories/reservation_repository.dart';
import 'package:extrabite_mobile/models/user_model.dart';
import 'package:extrabite_mobile/models/reservation_model.dart';
import 'package:extrabite_mobile/core/constants/app_constants.dart';

void main() {
  group('Reservation & Stock Logic Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Reservation creation validates quantity and decrements portions', () {
      final listingNotifier = container.read(listingProvider.notifier);
      final reservationNotifier = container.read(reservationProvider.notifier);

      final listing = container.read(listingProvider).firstWhere((l) => l.availablePortions >= 3);
      final initialPortions = listing.availablePortions;

      const customer = UserModel(
        id: 'cust_test_1',
        email: 'test@extrabite.app',
        fullName: 'Test Customer',
        role: UserRole.customer,
      );

      final reservation = reservationNotifier.createReservation(
        listing: listing,
        customer: customer,
        portionsCount: 2,
      );

      expect(reservation, isNotNull);
      expect(reservation!.paymentMethod, AppConstants.paymentMethodLabel);
      expect(reservation.status, ReservationStatus.confirmed);

      final updatedListing = listingNotifier.getListingById(listing.id);
      expect(updatedListing!.availablePortions, initialPortions - 2);
    });

    test('Oversell prevention: rejects reservation when requested quantity exceeds stock', () {
      final reservationNotifier = container.read(reservationProvider.notifier);
      final listing = container.read(listingProvider).firstWhere((l) => l.availablePortions > 0);

      const customer = UserModel(
        id: 'cust_test_2',
        email: 'test2@extrabite.app',
        fullName: 'Test Customer 2',
        role: UserRole.customer,
      );

      // Attempt reserving more than available
      final excessiveQty = listing.availablePortions + 5;
      final reservation = reservationNotifier.createReservation(
        listing: listing,
        customer: customer,
        portionsCount: excessiveQty,
      );

      expect(reservation, isNull);
    });

    test('Cancellation restores available stock back to the listing', () {
      final listingNotifier = container.read(listingProvider.notifier);
      final reservationNotifier = container.read(reservationProvider.notifier);

      final listing = container.read(listingProvider).firstWhere((l) => l.availablePortions >= 2);
      final originalStock = listing.availablePortions;

      const customer = UserModel(
        id: 'cust_test_3',
        email: 'test3@extrabite.app',
        fullName: 'Test Customer 3',
        role: UserRole.customer,
      );

      final res = reservationNotifier.createReservation(
        listing: listing,
        customer: customer,
        portionsCount: 2,
      );

      expect(res, isNotNull);
      expect(listingNotifier.getListingById(listing.id)!.availablePortions, originalStock - 2);

      // Cancel reservation
      final cancelSuccess = reservationNotifier.cancelReservation(res!.id);
      expect(cancelSuccess, true);

      // Verify stock restored
      final restoredListing = listingNotifier.getListingById(listing.id);
      expect(restoredListing!.availablePortions, originalStock);
    });
  });
}
