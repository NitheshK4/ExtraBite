import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:extrabite_mobile/core/repositories/food_repository.dart';
import 'package:extrabite_mobile/core/repositories/reservation_repository.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/providers/reservation_provider.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';
import 'package:extrabite_mobile/core/location/location_state.dart';
import 'mocks.dart';

class TestFoodRepository extends FoodRepository {
  final List<FoodListing> mockListings;
  final Map<String, dynamic>? mockPg;
  bool createListingCalled = false;
  bool updatePortionsCalled = false;
  bool removeListingCalled = false;

  TestFoodRepository({required this.mockListings, this.mockPg}) : super.fakeForTest();

  @override
  Future<List<FoodListing>> fetchListings() async => mockListings;

  @override
  Future<Map<String, dynamic>?> fetchOwnerPg(String ownerId) async => mockPg;

  @override
  Future<FoodListing> createListing(Map<String, dynamic> rowData, Map<String, dynamic> pgRow) async {
    createListingCalled = true;
    return FoodListing.fromSupabase(
      {
        ...rowData,
        'id': 'new-listing-uuid',
      },
      pgRow,
    );
  }

  @override
  Future<void> updatePortions(String listingId, int portions) async {
    updatePortionsCalled = true;
  }

  @override
  Future<void> removeListing(String listingId) async {
    removeListingCalled = true;
  }
}

class TestReservationRepository extends ReservationRepository {
  final List<Map<String, dynamic>> mockReservationsData;
  bool reserveFoodCalled = false;
  bool updateStatusCalled = false;

  TestReservationRepository({required this.mockReservationsData}) : super.fakeForTest();

  @override
  Future<Map<String, dynamic>> reserveFood({
    required String listingId,
    required int quantity,
  }) async {
    reserveFoodCalled = true;
    if (quantity > 10) {
      throw Exception('Insufficient portions');
    }
    return {
      'id': 'res-uuid',
      'readable_id': 'EB-99999',
      'listing_id': listingId,
      'portions_count': quantity,
      'total_amount': 50.0 * quantity,
      'status': 'confirmed',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCustomerReservations(String customerId) async {
    return mockReservationsData;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOwnerReservations() async {
    return mockReservationsData;
  }

  @override
  Future<Map<String, dynamic>> updateReservationStatus(String reservationId, String newStatus) async {
    updateStatusCalled = true;
    return {
      'id': reservationId,
      'readable_id': reservationId.startsWith('EB-') ? reservationId : 'EB-99999',
      'status': newStatus,
    };
  }
}

void main() {
  group('Food Marketplace - Phase 2 Tests', () {
    late FoodListing approvedListing;
    late FoodListing unapprovedListing;
    late FoodListing expiredListing;

    setUp(() {
      approvedListing = FoodListing(
        id: 'list-1',
        propertyName: 'Sri Sai Mess',
        foodName: 'Rice Sambar',
        description: 'Fresh lunch surplus',
        category: 'Lunch',
        originalPrice: 60.0,
        sellingPrice: 30.0,
        totalPortions: 10,
        availablePortions: 5,
        pickupStarts: DateTime.now().subtract(const Duration(minutes: 10)),
        pickupEnds: DateTime.now().add(const Duration(hours: 1)),
        preparedTime: DateTime.now(),
        verificationStatus: 'verified',
        status: 'active',
        isVegetarian: true,
        ingredients: const [],
        allergens: const [],
        imageUrl: '',
        propertyId: 'pg-1',
        latitude: 16.4971,
        longitude: 80.5005,
        distanceKm: 0.0,
      );

      unapprovedListing = FoodListing(
        id: 'list-2',
        propertyName: 'Unapproved PG Mess',
        foodName: 'Roti Curry',
        description: 'Fresh dinner surplus',
        category: 'Dinner',
        originalPrice: 80.0,
        sellingPrice: 40.0,
        totalPortions: 10,
        availablePortions: 8,
        pickupStarts: DateTime.now().subtract(const Duration(minutes: 10)),
        pickupEnds: DateTime.now().add(const Duration(hours: 1)),
        preparedTime: DateTime.now(),
        verificationStatus: 'pending',
        status: 'active',
        isVegetarian: true,
        ingredients: const [],
        allergens: const [],
        imageUrl: '',
        propertyId: 'pg-2',
        latitude: 16.4971,
        longitude: 80.5005,
        distanceKm: 0.0,
      );

      expiredListing = FoodListing(
        id: 'list-3',
        propertyName: 'Sri Sai Mess',
        foodName: 'Breakfast Dosa',
        description: 'Fresh breakfast surplus',
        category: 'Breakfast',
        originalPrice: 40.0,
        sellingPrice: 20.0,
        totalPortions: 10,
        availablePortions: 5,
        pickupStarts: DateTime.now().subtract(const Duration(hours: 2)),
        pickupEnds: DateTime.now().subtract(const Duration(minutes: 30)),
        preparedTime: DateTime.now(),
        verificationStatus: 'verified',
        status: 'active',
        isVegetarian: true,
        ingredients: const [],
        allergens: const [],
        imageUrl: '',
        propertyId: 'pg-1',
        latitude: 16.4971,
        longitude: 80.5005,
        distanceKm: 0.0,
      );
    });

    test('1. Approved owner can fetch/create food listing', () async {
      final foodRepo = TestFoodRepository(mockListings: [], mockPg: {'id': 'pg-1', 'is_approved': true, 'is_active': true});
      final container = ProviderContainer(overrides: [
        foodRepositoryProvider.overrideWithValue(foodRepo),
      ]);

      final pg = await container.read(foodRepositoryProvider).fetchOwnerPg('owner-1');
      expect(pg!['is_approved'], isTrue);

      final listing = await container.read(foodRepositoryProvider).createListing({'title': 'Sambar Rice'}, {'pg_name': 'Sri Sai Mess'});
      expect(listing.foodName, 'Sambar Rice');
      expect(foodRepo.createListingCalled, isTrue);
    });

    test('2. Customer sees only approved, active, unexpired food listing with portions > 0', () {
      final foodRepo = TestFoodRepository(mockListings: [approvedListing, unapprovedListing, expiredListing]);
      final container = ProviderContainer(overrides: [
        foodRepositoryProvider.overrideWithValue(foodRepo),
        locationProvider.overrideWith((ref) => FakeLocationNotifier(
          MockLocationService(),
          const LocationState.available(16.4971, 80.5005),
        )),
      ]);

      // Seed notifier listings
      container.read(foodProvider.notifier).state = FoodState(
        listings: [approvedListing, unapprovedListing, expiredListing],
        selectedCategory: 'All',
        searchQuery: '',
      );

      final filtered = container.read(filteredFoodProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'list-1');
    });

    test('3. Reservation triggers reserve_food RPC and fails on over-limit', () async {
      final resRepo = TestReservationRepository(mockReservationsData: []);
      final container = ProviderContainer(overrides: [
        reservationRepositoryProvider.overrideWithValue(resRepo),
      ]);

      final res = await container.read(reservationProvider.notifier).createReservation(
        listing: approvedListing,
        quantity: 2,
      );
      expect(res.quantity, 2);
      expect(resRepo.reserveFoodCalled, isTrue);

      expect(
        () => container.read(reservationProvider.notifier).createReservation(listing: approvedListing, quantity: 15),
        throwsException,
      );
    });

    test('4. Status update propagates to database', () async {
      final resRepo = TestReservationRepository(mockReservationsData: []);
      final container = ProviderContainer(overrides: [
        reservationRepositoryProvider.overrideWithValue(resRepo),
      ]);

      await container.read(reservationProvider.notifier).updateStatus('EB-12345', 'ready_for_pickup');
      expect(resRepo.updateStatusCalled, isTrue);
    });
  });
}
