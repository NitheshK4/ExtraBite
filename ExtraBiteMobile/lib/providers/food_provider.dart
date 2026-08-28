import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/food_listing.dart';
import '../core/location/location_state.dart';
import '../core/utils/haversine.dart';
import '../core/repositories/food_repository.dart';
import 'location_provider.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(supabase.Supabase.instance.client);
});

class FoodState {
  final List<FoodListing> listings;
  final String searchQuery;
  final String selectedCategory;
  final bool isLoading;

  FoodState({
    required this.listings,
    required this.searchQuery,
    required this.selectedCategory,
    this.isLoading = false,
  });

  FoodState copyWith({
    List<FoodListing>? listings,
    String? searchQuery,
    String? selectedCategory,
    bool? isLoading,
  }) {
    return FoodState(
      listings: listings ?? this.listings,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FoodNotifier extends StateNotifier<FoodState> {
  final FoodRepository _repository;
  supabase.RealtimeChannel? _realtimeChannel;

  FoodNotifier(this._repository)
      : super(FoodState(
          listings: _repository.isFakeForTest ? FoodRepository.getTestMockData() : const [],
          searchQuery: '',
          selectedCategory: 'All',
        )) {
    if (!_repository.isFakeForTest) {
      loadListings();
      _initRealtimeSubscription();
    }
  }

  void _initRealtimeSubscription() {
    _realtimeChannel = _repository.subscribeToListingsChanges(() {
      loadListings();
    });
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadListings() async {
    state = state.copyWith(isLoading: true);
    final supabaseListings = await _repository.fetchListings();
    state = state.copyWith(
      listings: supabaseListings,
      isLoading: false,
    );
  }

  void addListing(FoodListing listing) {
    state = state.copyWith(
      listings: [listing, ...state.listings],
    );
  }

  Future<void> removeListing(String id) async {
    state = state.copyWith(
      listings: state.listings.where((item) => item.id != id).toList(),
    );
    await _repository.removeListing(id);
  }

  Future<void> decrementPortions(String id, int count) async {
    int updatedPortions = 0;
    state = state.copyWith(
      listings: state.listings.map((item) {
        if (item.id == id) {
          final newPortions = (item.availablePortions - count).clamp(0, 9999);
          updatedPortions = newPortions;
          return item.copyWith(availablePortions: newPortions);
        }
        return item;
      }).toList(),
    );
    await _repository.updatePortions(id, updatedPortions);
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
  final repo = ref.read(foodRepositoryProvider);
  return FoodNotifier(repo);
});

final filteredFoodProvider = Provider<List<FoodListing>>((ref) {
  final state = ref.watch(foodProvider);
  final locationState = ref.watch(locationProvider);
  final selectedRadius = ref.watch(radiusProvider);

  // 1. Filter out unverified, inactive, sold out, or expired listings
  var list = state.listings.where((item) {
    return item.verificationStatus == 'verified' &&
        item.status == 'active' &&
        item.availablePortions > 0 &&
        !item.isExpired;
  }).toList();

  // 2. Filter by distance (if location is available)
  if (locationState.status == LocationStateStatus.available) {
    final lat = locationState.latitude!;
    final lon = locationState.longitude!;

    list = list
        .map((item) {
          final distance = Haversine.calculateDistance(lat, lon, item.latitude, item.longitude);
          return item.copyWith(distanceKm: distance);
        })
        .where((item) => item.distanceKm <= selectedRadius)
        .toList();
  } else {
    // Return empty list if location details are not verified/available
    return [];
  }

  // 3. Apply Category Filter
  if (state.selectedCategory != 'All') {
    if (state.selectedCategory == 'Vegetarian') {
      list = list.where((item) => item.isVegetarian).toList();
    } else if (state.selectedCategory == 'Non-Vegetarian') {
      list = list.where((item) => !item.isVegetarian).toList();
    } else if (state.selectedCategory == 'Under ₹30') {
      list = list.where((item) => item.sellingPrice < 30.0).toList();
    } else {
      list = list.where((item) => item.category.toLowerCase() == state.selectedCategory.toLowerCase()).toList();
    }
  }

  // 4. Apply Search Query Filter
  if (state.searchQuery.isNotEmpty) {
    final query = state.searchQuery.toLowerCase();
    list = list.where((item) =>
      item.foodName.toLowerCase().contains(query) ||
      item.propertyName.toLowerCase().contains(query) ||
      item.category.toLowerCase().contains(query)
    ).toList();
  }

  // Optional: Sort by distance
  list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

  return list;
});

final foodDetailProvider = Provider.family<FoodListing?, String>((ref, id) {
  final state = ref.watch(foodProvider);
  final locationState = ref.watch(locationProvider);
  try {
    final item = state.listings.firstWhere((item) => item.id == id);
    if (locationState.status == LocationStateStatus.available) {
      final distance = Haversine.calculateDistance(
        locationState.latitude!,
        locationState.longitude!,
        item.latitude,
        item.longitude,
      );
      return item.copyWith(distanceKm: distance);
    }
    return item;
  } catch (_) {
    return null;
  }
});
