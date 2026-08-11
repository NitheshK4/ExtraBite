import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_listing.dart';
import 'location_provider.dart';

class FoodState {
  final List<FoodListing> listings;
  final String searchQuery;
  final String selectedCategory;

  FoodState({
    required this.listings,
    required this.searchQuery,
    required this.selectedCategory,
  });

  FoodState copyWith({
    List<FoodListing>? listings,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return FoodState(
      listings: listings ?? this.listings,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class FoodNotifier extends StateNotifier<FoodState> {
  FoodNotifier() : super(FoodState(listings: const [], searchQuery: '', selectedCategory: 'All'));

  void addListing(FoodListing listing) {
    state = state.copyWith(
      listings: [listing, ...state.listings],
    );
  }

  void removeListing(String id) {
    state = state.copyWith(
      listings: state.listings.where((item) => item.id != id).toList(),
    );
  }

  void decrementPortions(String id, int count) {
    state = state.copyWith(
      listings: state.listings.map((item) {
        if (item.id == id) {
          final newPortions = (item.availablePortions - count).clamp(0, 9999);
          return item.copyWith(availablePortions: newPortions);
        }
        return item;
      }).toList(),
    );
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void clearAll() {
    state = state.copyWith(listings: const []);
  }
}

final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  return FoodNotifier();
});

/// GPS-filtered and distance-sorted surplus food provider
final filteredFoodProvider = Provider<List<FoodListing>>((ref) {
  final foodState = ref.watch(foodProvider);
  final locationState = ref.watch(locationProvider);

  final userLat = locationState.latitude;
  final userLng = locationState.longitude;
  final maxRadiusMeters = locationState.radiusMeters;

  // 1. Filter out unverified, expired, or 0-portion listings
  var list = foodState.listings.where((item) {
    return item.verificationStatus == 'verified' &&
        !item.isExpired &&
        item.availablePortions > 0;
  }).map((item) {
    // 2. Calculate real-time Haversine distance from customer GPS coordinates
    final distanceMeters = FoodListing.calculateHaversineDistanceMeters(
      userLat,
      userLng,
      item.latitude,
      item.longitude,
    );
    final distanceKm = distanceMeters / 1000.0;

    return item.copyWith(
      distanceMeters: distanceMeters,
      distanceKm: distanceKm,
    );
  }).where((item) {
    // 3. Strictly filter listings within selected GPS radius (e.g. 2000m)
    return item.distanceMeters <= maxRadiusMeters;
  }).toList();

  // 4. Apply Category Filter
  if (foodState.selectedCategory != 'All') {
    if (foodState.selectedCategory == 'Vegetarian') {
      list = list.where((item) => item.isVegetarian).toList();
    } else if (foodState.selectedCategory == 'Non-Vegetarian') {
      list = list.where((item) => !item.isVegetarian).toList();
    } else if (foodState.selectedCategory == 'Under ₹30') {
      list = list.where((item) => item.sellingPrice < 30.0).toList();
    } else {
      list = list.where((item) => item.category.toLowerCase() == foodState.selectedCategory.toLowerCase()).toList();
    }
  }

  // 5. Apply Search Query Filter
  if (foodState.searchQuery.isNotEmpty) {
    final query = foodState.searchQuery.toLowerCase();
    list = list.where((item) =>
      item.foodName.toLowerCase().contains(query) ||
      item.propertyName.toLowerCase().contains(query) ||
      item.locationAddress.toLowerCase().contains(query) ||
      item.category.toLowerCase().contains(query)
    ).toList();
  }

  // 6. Sort strictly by actual distance ascending (nearest first)
  list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

  return list;
});

final foodDetailProvider = Provider.family<FoodListing?, String>((ref, id) {
  final state = ref.watch(foodProvider);
  try {
    return state.listings.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});

