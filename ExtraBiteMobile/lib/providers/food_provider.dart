import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/food_listing.dart';
import '../core/location/location_state.dart';
import '../core/utils/haversine.dart';
import '../core/repositories/food_repository.dart';
import 'location_provider.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  try {
    return FoodRepository(supabase.Supabase.instance.client);
  } catch (_) {
    return FoodRepository.fakeForTest();
  }
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
    try {
      _realtimeChannel = supabase.Supabase.instance.client
          .channel('public:food_listings')
          .onPostgresChanges(
            event: supabase.PostgresChangeEvent.all,
            schema: 'public',
            table: 'food_listings',
            callback: (payload) {
              loadListings();
            },
          )
          .subscribe();
    } catch (_) {
      // Subscriptions might fail in testing environments without Supabase client
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadListings() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final fetchedListings = await _repository.fetchListings();
      state = state.copyWith(
        listings: fetchedListings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (_repository.isFakeForTest) {
        state = state.copyWith(listings: FoodRepository.getTestMockData());
      }
    }
  }

  void addListing(FoodListing listing) {
    state = state.copyWith(
      listings: [listing, ...state.listings],
    );
  }

  void refreshListings() {
    loadListings();
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
          final newStatus = newPortions == 0 ? 'sold_out' : item.status;
          return item.copyWith(
            availablePortions: newPortions,
            status: newStatus,
          );
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

  var rawList = state.listings;
  List<FoodListing> eligibleList = [];

  for (final item in rawList) {
    if (item.verificationStatus != 'verified') {
      continue;
    }
    if (item.status != 'active') {
      continue;
    }
    if (item.availablePortions <= 0) {
      continue;
    }
    if (item.isExpired) {
      continue;
    }
    eligibleList.add(item);
  }

  // Filter by distance if location is available
  if (locationState.status == LocationStateStatus.available) {
    final lat = locationState.latitude!;
    final lon = locationState.longitude!;

    var distanceFilteredList = <FoodListing>[];
    for (final item in eligibleList) {
      final distance = Haversine.calculateDistance(lat, lon, item.latitude, item.longitude);
      final itemWithDistance = item.copyWith(distanceKm: distance);
      if (distance <= selectedRadius) {
        distanceFilteredList.add(itemWithDistance);
      }
    }
    eligibleList = distanceFilteredList;
  } else {
    return [];
  }

  // Apply Category Filter
  if (state.selectedCategory != 'All') {
    if (state.selectedCategory == 'Vegetarian') {
      eligibleList = eligibleList.where((item) => item.isVegetarian).toList();
    } else if (state.selectedCategory == 'Non-Vegetarian') {
      eligibleList = eligibleList.where((item) => !item.isVegetarian).toList();
    } else if (state.selectedCategory == 'Under ₹30') {
      eligibleList = eligibleList.where((item) => item.sellingPrice < 30.0).toList();
    } else {
      eligibleList = eligibleList.where((item) => item.category.toLowerCase() == state.selectedCategory.toLowerCase()).toList();
    }
  }

  // Apply Search Query Filter
  if (state.searchQuery.isNotEmpty) {
    final query = state.searchQuery.toLowerCase();
    eligibleList = eligibleList.where((item) =>
      item.foodName.toLowerCase().contains(query) ||
      item.propertyName.toLowerCase().contains(query) ||
      item.category.toLowerCase().contains(query)
    ).toList();
  }

  // Sort by distance
  eligibleList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

  return eligibleList;
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
