import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:extrabite_mobile/core/location/location_service.dart';
import 'package:extrabite_mobile/core/location/location_state.dart';
import 'package:extrabite_mobile/core/repositories/fake_auth_repository.dart';
import 'package:extrabite_mobile/providers/auth_provider.dart';
import 'package:extrabite_mobile/providers/location_provider.dart';
import 'package:extrabite_mobile/core/repositories/food_repository.dart';
import 'package:extrabite_mobile/providers/food_provider.dart';
import 'package:extrabite_mobile/models/food_listing.dart';
import 'package:extrabite_mobile/core/repositories/pg_profile_repository.dart';
import 'package:extrabite_mobile/core/repositories/reservation_repository.dart';
import 'package:extrabite_mobile/providers/reservation_provider.dart';

/// A [FoodRepository] that never touches Supabase.
/// Uses the private [FoodRepository._fake()] constructor to avoid
/// instantiating a real SupabaseClient (which would start a GoTrue
/// auto-refresh timer, leaving pending timers after tests finish).
class FakeFoodRepository extends FoodRepository {
  FakeFoodRepository() : super.fakeForTest();

  @override
  Future<List<FoodListing>> fetchListings() async => [];

  @override
  Future<Map<String, dynamic>?> fetchOwnerPg(String ownerId) async => null;

  @override
  Future<String?> uploadFoodImage(
    Uint8List bytes,
    String ownerId,
    String extension, {
    String? listingId,
  }) async =>
      null;

  @override
  Future<FoodListing> createListing(
      Map<String, dynamic> rowData, Map<String, dynamic> pgRow) async {
    throw UnimplementedError('createListing not needed in tests');
  }

  @override
  Future<FoodListing> updateListing(
    String listingId,
    Map<String, dynamic> rowData,
    Map<String, dynamic> pgRow,
  ) async {
    throw UnimplementedError('updateListing not needed in tests');
  }
}

class FakeReservationRepository extends ReservationRepository {
  int _counter = 0;
  FakeReservationRepository() : super.fakeForTest();

  @override
  Future<Map<String, dynamic>> reserveFood(
      {required String listingId, required int quantity}) async {
    final price = (listingId == 'item_100') ? 30.0 : 25.0;
    _counter++;
    return {
      'id': 'res-fake-uuid-$_counter',
      'readable_id': 'EB-${10000 + _counter}',
      'listing_id': listingId,
      'portions_count': quantity,
      'total_amount': price * quantity,
      'status': 'confirmed',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCustomerReservations(
          String customerId) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> fetchOwnerReservations() async => [];

  int cancelReservationCallCount = 0;
  bool shouldFailCancellation = false;

  @override
  Future<Map<String, dynamic>> cancelReservation(String reservationId,
      {String? reason}) async {
    if (shouldFailCancellation) {
      throw Exception('Database transaction aborted');
    }
    cancelReservationCallCount++;
    return {
      'id': reservationId,
      'readable_id': reservationId,
      'status': 'cancelled',
      'cancellation_reason': reason ?? 'Cancelled by customer',
    };
  }

  @override
  Future<Map<String, dynamic>> updateReservationStatus(
      String reservationId, String newStatus) async {
    return {
      'id': reservationId,
      'readable_id': reservationId,
      'status': newStatus,
    };
  }
}

// ---------------------------------------------------------------------------
// Location mocks (unchanged)
// ---------------------------------------------------------------------------

class MockLocationService implements LocationService {
  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.whileInUse;
  Position? mockPosition;
  Object? mockError;
  Completer<Position>? positionCompleter;
  int getCurrentPositionCallCount = 0;
  int checkPermissionCallCount = 0;
  int requestPermissionCallCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (mockError != null) throw mockError!;
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCallCount++;
    if (mockError != null) throw mockError!;
    return permissionStatus;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCallCount++;
    if (mockError != null) throw mockError!;
    return permissionStatus;
  }

  @override
  Future<Position> getCurrentPosition() async {
    getCurrentPositionCallCount++;
    if (mockError != null) throw mockError!;
    if (positionCompleter != null) return positionCompleter!.future;
    if (mockPosition != null) return mockPosition!;
    return Position(
      longitude: 80.5005,
      latitude: 16.4971,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

class FakeLocationNotifier extends LocationNotifier {
  FakeLocationNotifier(super.locationService, [super.initialState]);

  @override
  Future<void> determinePosition({
    bool forceRefresh = false,
    Duration freshnessLimit = const Duration(minutes: 15),
  }) async {
    // No-op to prevent asynchronous permission check overrides in UI widget tests
  }
}

// ---------------------------------------------------------------------------
// Auth mocks
// ---------------------------------------------------------------------------

/// Returns a [ProviderContainer] with location, auth, and food repo overridden.
ProviderContainer createMockLocationContainer() {
  final mockService = MockLocationService();
  return ProviderContainer(
    overrides: [
      locationProvider.overrideWith((ref) {
        return FakeLocationNotifier(
          mockService,
          const LocationState.available(16.4971, 80.5005),
        );
      }),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
      pgProfileRepositoryProvider
          .overrideWithValue(PgProfileRepository.fakeForTest()),
      reservationRepositoryProvider
          .overrideWithValue(FakeReservationRepository()),
    ],
  );
}

/// Returns the standard list of [Override]s for widget tests.
List<Override> fakeLocationAndAuthOverrides() {
  return [
    locationProvider.overrideWith((ref) {
      return FakeLocationNotifier(
        MockLocationService(),
        const LocationState.available(16.4971, 80.5005),
      );
    }),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    foodRepositoryProvider.overrideWithValue(FakeFoodRepository()),
    pgProfileRepositoryProvider
        .overrideWithValue(PgProfileRepository.fakeForTest()),
    reservationRepositoryProvider
        .overrideWithValue(FakeReservationRepository()),
  ];
}
