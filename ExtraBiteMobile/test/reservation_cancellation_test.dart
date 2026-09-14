import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:extrabite_mobile/core/location/location_state.dart';
import 'package:extrabite_mobile/core/repositories/fake_auth_repository.dart';
import 'package:extrabite_mobile/core/repositories/pg_profile_repository.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/models/reservation.dart';
import 'package:extrabite_mobile/providers/auth_provider.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';
import 'package:extrabite_mobile/providers/reservation_provider.dart';

import 'mocks.dart';

FoodListing createTestListing({
  String id = 'food_1',
  String name = 'Paneer Butter Masala',
  int availablePortions = 5,
  int totalPortions = 5,
  String status = 'active',
}) {
  final now = DateTime.now();
  return FoodListing(
    id: id,
    foodName: name,
    description: 'Fresh meal',
    propertyId: 'pg_1',
    propertyName: 'Comfort PG',
    distanceKm: 0.5,
    category: 'Lunch',
    isVegetarian: true,
    originalPrice: 80.0,
    sellingPrice: 40.0,
    availablePortions: availablePortions,
    preparedTime: now.subtract(const Duration(hours: 1)),
    pickupStarts: now.subtract(const Duration(minutes: 30)),
    pickupEnds: now.add(const Duration(hours: 2)),
    ingredients: const ['Paneer', 'Butter', 'Spices'],
    allergens: const ['Dairy'],
    verificationStatus: 'verified',
    latitude: 16.4971,
    longitude: 80.5005,
    status: status,
  );
}

void main() {
  group('Reservation Cancellation & Inventory Restoration Tests', () {
    late FakeReservationRepository fakeResRepo;
    late ProviderContainer container;

    setUp(() {
      fakeResRepo = FakeReservationRepository();
      container = ProviderContainer(
        overrides: [
          locationProvider.overrideWith((ref) => FakeLocationNotifier(
                MockLocationService(),
                const LocationState.available(16.4971, 80.5005),
              )),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
          pgProfileRepositoryProvider
              .overrideWithValue(PgProfileRepository.fakeForTest()),
          reservationRepositoryProvider.overrideWithValue(fakeResRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'TEST 1 — SINGLE QUANTITY CANCELLATION: 5 -> reserve 1 -> 4 -> cancel -> 5',
        () async {
      final foodNotifier = container.read(foodProvider.notifier);
      final resNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

      // Initial food quantity: 5
      final listing = createTestListing(id: 'listing_1', availablePortions: 5);
      foodNotifier.addListing(listing);

      // Customer reserves 1
      final res = await resNotifier.createReservation(
        listing: listing,
        quantity: 1,
      );
      foodNotifier.decrementPortions(listing.id, 1);

      // Expected available quantity: 4
      var currentFood = container.read(foodDetailProvider('listing_1'));
      expect(currentFood?.availablePortions, equals(4));
      expect(res.status, equals(ReservationStatus.reserved));

      // Customer cancels reservation
      await resNotifier.cancelReservation(res.id);

      // Expected available quantity after cancellation: 5
      currentFood = container.read(foodDetailProvider('listing_1'));
      expect(currentFood?.availablePortions, equals(5));

      // Reservation status must be cancelled
      final cancelledRes = container
          .read(pastReservationsProvider)
          .firstWhere((r) => r.id == res.id);
      expect(cancelledRes.status, equals(ReservationStatus.cancelled));
      expect(fakeResRepo.cancelReservationCallCount, equals(1));
    });

    test(
        'TEST 2 — MULTIPLE QUANTITY CANCELLATION: 10 -> reserve 3 -> 7 -> cancel -> 10',
        () async {
      final foodNotifier = container.read(foodProvider.notifier);
      final resNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

      // Initial food quantity: 10
      final listing = createTestListing(
        id: 'listing_multi',
        availablePortions: 10,
        totalPortions: 10,
      );
      foodNotifier.addListing(listing);

      // Customer reserves 3
      final res = await resNotifier.createReservation(
        listing: listing,
        quantity: 3,
      );
      foodNotifier.decrementPortions(listing.id, 3);

      // Expected available quantity: 7
      var currentFood = container.read(foodDetailProvider('listing_multi'));
      expect(currentFood?.availablePortions, equals(7));

      // Customer cancels reservation
      await resNotifier.cancelReservation(res.id);

      // Expected available quantity: 10
      currentFood = container.read(foodDetailProvider('listing_multi'));
      expect(currentFood?.availablePortions, equals(10));
    });

    test(
        'TEST 3 — IDEMPOTENT CANCELLATION: repeated cancellation does not increase stock',
        () async {
      final foodNotifier = container.read(foodProvider.notifier);
      final resNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

      // Initial food quantity: 5
      final listing =
          createTestListing(id: 'listing_idem', availablePortions: 5);
      foodNotifier.addListing(listing);

      // Reserve 1 -> available 4
      final res = await resNotifier.createReservation(
        listing: listing,
        quantity: 1,
      );
      foodNotifier.decrementPortions(listing.id, 1);
      expect(
          container.read(foodDetailProvider('listing_idem'))?.availablePortions,
          equals(4));

      // Cancel once -> available 5
      await resNotifier.cancelReservation(res.id);
      expect(
          container.read(foodDetailProvider('listing_idem'))?.availablePortions,
          equals(5));

      // Cancel again (e.g. repeated button click or screen refresh)
      await resNotifier.cancelReservation(res.id);

      // Must remain 5, NOT increase to 6!
      expect(
          container.read(foodDetailProvider('listing_idem'))?.availablePortions,
          equals(5));
    });

    test('TEST 4 — TWO RESERVATIONS: independent stock restoration', () async {
      final foodNotifier = container.read(foodProvider.notifier);
      final resNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

      // Initial food quantity: 5
      final listing =
          createTestListing(id: 'listing_shared', availablePortions: 5);
      foodNotifier.addListing(listing);

      // Customer A reserves 1 (available becomes 4)
      final resA = await resNotifier.createReservation(
        listing: listing,
        quantity: 1,
      );
      foodNotifier.decrementPortions(listing.id, 1);

      // Customer B reserves 2 (available becomes 2)
      final resB = await resNotifier.createReservation(
        listing: listing,
        quantity: 2,
      );
      foodNotifier.decrementPortions(listing.id, 2);

      expect(
          container
              .read(foodDetailProvider('listing_shared'))
              ?.availablePortions,
          equals(2));

      // Customer A cancels -> available becomes 3 (2 + 1)
      await resNotifier.cancelReservation(resA.id);
      expect(
          container
              .read(foodDetailProvider('listing_shared'))
              ?.availablePortions,
          equals(3));

      // Customer B cancels -> available becomes 5 (3 + 2)
      await resNotifier.cancelReservation(resB.id);
      expect(
          container
              .read(foodDetailProvider('listing_shared'))
              ?.availablePortions,
          equals(5));
    });

    test(
        'TEST 5 — FAILED CANCELLATION: database error keeps state intact and throws',
        () async {
      final foodNotifier = container.read(foodProvider.notifier);
      final resNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

      final listing =
          createTestListing(id: 'listing_fail', availablePortions: 5);
      foodNotifier.addListing(listing);

      final res = await resNotifier.createReservation(
        listing: listing,
        quantity: 1,
      );
      foodNotifier.decrementPortions(listing.id, 1);
      expect(
          container.read(foodDetailProvider('listing_fail'))?.availablePortions,
          equals(4));

      // Configure mock repository to fail
      fakeResRepo.shouldFailCancellation = true;

      // Calling cancelReservation should throw an exception
      expect(
        () => resNotifier.cancelReservation(res.id),
        throwsA(isA<Exception>()),
      );

      // Reservation must remain in active state
      final activeList = container.read(activeReservationsProvider);
      expect(activeList.any((r) => r.id == res.id), isTrue);

      // Food quantity must NOT have been restored on failure
      expect(
          container.read(foodDetailProvider('listing_fail'))?.availablePortions,
          equals(4));
    });

    test(
        'TEST 6 — SOLD OUT TO ACTIVE RECOVERY: 2 -> reserve 2 (sold_out) -> cancel -> active (2)',
        () async {
      final foodNotifier = container.read(foodProvider.notifier);
      final resNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

      // Initial food quantity: 2
      final listing = createTestListing(
        id: 'listing_soldout',
        availablePortions: 2,
        totalPortions: 2,
        status: 'active',
      );
      foodNotifier.addListing(listing);

      // Reserve 2 -> portions becomes 0, status becomes sold_out
      final res = await resNotifier.createReservation(
        listing: listing,
        quantity: 2,
      );
      foodNotifier.decrementPortions(listing.id, 2);

      var food = container.read(foodDetailProvider('listing_soldout'));
      expect(food?.availablePortions, equals(0));
      expect(food?.status, equals('sold_out'));

      // Cancel reservation -> portions restored to 2 and status reactivated to active
      await resNotifier.cancelReservation(res.id);

      food = container.read(foodDetailProvider('listing_soldout'));
      expect(food?.availablePortions, equals(2));
      expect(food?.status, equals('active'));
    });

    test('TEST 7 — CONCURRENT CANCELLATION DEDUPLICATION', () async {
      final foodNotifier = container.read(foodProvider.notifier);
      final resNotifier = container.read(reservationProvider.notifier);
      foodNotifier.clearAll();

      final listing =
          createTestListing(id: 'listing_concurrent', availablePortions: 5);
      foodNotifier.addListing(listing);

      final res = await resNotifier.createReservation(
        listing: listing,
        quantity: 1,
      );
      foodNotifier.decrementPortions(listing.id, 1);
      expect(
          container
              .read(foodDetailProvider('listing_concurrent'))
              ?.availablePortions,
          equals(4));

      // Trigger two cancellations concurrently for the exact same reservation
      await Future.wait([
        resNotifier.cancelReservation(res.id),
        resNotifier.cancelReservation(res.id),
      ]);

      // Only one RPC call was made due to in-flight deduplication
      expect(fakeResRepo.cancelReservationCallCount, equals(1));

      // Available quantity must be 5, never 6
      expect(
          container
              .read(foodDetailProvider('listing_concurrent'))
              ?.availablePortions,
          equals(5));
    });
  });
}
