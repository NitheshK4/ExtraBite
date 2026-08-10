import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_listing_model.dart';
import '../demo/seed_data.dart';

class ListingFilterOptions {
  final String searchQuery;
  final String? selectedCategory;
  final DietaryType? dietaryType;
  final double? maxPrice;
  final bool onlyAvailableNow;
  final List<String> excludedAllergens;
  final String sortBy; // 'nearest', 'lowestPrice', 'earliestPickup', 'highestRated', 'newest'

  const ListingFilterOptions({
    this.searchQuery = '',
    this.selectedCategory,
    this.dietaryType,
    this.maxPrice,
    this.onlyAvailableNow = false,
    this.excludedAllergens = const [],
    this.sortBy = 'nearest',
  });

  ListingFilterOptions copyWith({
    String? searchQuery,
    String? selectedCategory,
    DietaryType? dietaryType,
    double? maxPrice,
    bool? onlyAvailableNow,
    List<String>? excludedAllergens,
    String? sortBy,
  }) {
    return ListingFilterOptions(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      dietaryType: dietaryType ?? this.dietaryType,
      maxPrice: maxPrice ?? this.maxPrice,
      onlyAvailableNow: onlyAvailableNow ?? this.onlyAvailableNow,
      excludedAllergens: excludedAllergens ?? this.excludedAllergens,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class ListingNotifier extends StateNotifier<List<FoodListingModel>> {
  final Set<String> _favoriteIds = {'list_01', 'list_03'};
  final List<String> _recentlyViewedIds = [];

  ListingNotifier() : super(SeedData.generateFoodListings());

  Set<String> get favoriteIds => _favoriteIds;
  List<String> get recentlyViewedIds => _recentlyViewedIds;

  bool isFavorite(String listingId) => _favoriteIds.contains(listingId);

  void toggleFavorite(String listingId) {
    if (_favoriteIds.contains(listingId)) {
      _favoriteIds.remove(listingId);
    } else {
      _favoriteIds.add(listingId);
    }
    // Trigger notify
    state = [...state];
  }

  void markAsViewed(String listingId) {
    _recentlyViewedIds.remove(listingId);
    _recentlyViewedIds.insert(0, listingId);
    if (_recentlyViewedIds.length > 10) {
      _recentlyViewedIds.removeLast();
    }
  }

  FoodListingModel? getListingById(String id) {
    try {
      return state.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  List<FoodListingModel> getListingsForPg(String pgId) {
    return state.where((item) => item.pgId == pgId && item.status != ListingStatus.removed).toList();
  }

  List<FoodListingModel> getFavoriteListings() {
    return state.where((item) => _favoriteIds.contains(item.id)).toList();
  }

  List<FoodListingModel> getRecentlyViewedListings() {
    return _recentlyViewedIds
        .map((id) => getListingById(id))
        .whereType<FoodListingModel>()
        .toList();
  }

  /// Decrements available portions when a reservation is placed.
  /// Prevents overselling by checking current available count.
  bool decrementPortions(String listingId, int quantity) {
    final index = state.indexWhere((l) => l.id == listingId);
    if (index == -1) return false;

    final current = state[index];
    if (current.availablePortions < quantity) {
      return false; // Oversell prevented
    }

    final newAvailable = current.availablePortions - quantity;
    final updated = current.copyWith(
      availablePortions: newAvailable,
      status: newAvailable == 0 ? ListingStatus.soldOut : current.status,
    );

    final newList = [...state];
    newList[index] = updated;
    state = newList;
    return true;
  }

  /// Restores portions when a reservation is cancelled
  void restorePortions(String listingId, int quantity) {
    final index = state.indexWhere((l) => l.id == listingId);
    if (index == -1) return;

    final current = state[index];
    final newAvailable = current.availablePortions + quantity;
    final updated = current.copyWith(
      availablePortions: newAvailable,
      status: current.status == ListingStatus.soldOut ? ListingStatus.active : current.status,
    );

    final newList = [...state];
    newList[index] = updated;
    state = newList;
  }

  // PG Owner actions
  void addListing(FoodListingModel newListing) {
    state = [newListing, ...state];
  }

  void updateListing(FoodListingModel updated) {
    final index = state.indexWhere((l) => l.id == updated.id);
    if (index != -1) {
      final list = [...state];
      list[index] = updated;
      state = list;
    }
  }

  void toggleListingPause(String id) {
    final index = state.indexWhere((l) => l.id == id);
    if (index != -1) {
      final current = state[index];
      final newStatus = current.status == ListingStatus.active
          ? ListingStatus.paused
          : ListingStatus.active;
      final list = [...state];
      list[index] = current.copyWith(status: newStatus);
      state = list;
    }
  }

  void markSoldOut(String id) {
    final index = state.indexWhere((l) => l.id == id);
    if (index != -1) {
      final current = state[index];
      final list = [...state];
      list[index] = current.copyWith(
        availablePortions: 0,
        status: ListingStatus.soldOut,
      );
      state = list;
    }
  }

  void duplicateListing(String id) {
    final original = getListingById(id);
    if (original != null) {
      final now = DateTime.now();
      final duplicate = original.copyWith(
        id: 'list_${now.millisecondsSinceEpoch}',
        title: '${original.title} (Copy)',
        pickupStartTime: now,
        pickupEndTime: now.add(const Duration(hours: 2)),
        status: ListingStatus.active,
        availablePortions: original.totalPortions,
        createdAt: now,
      );
      addListing(duplicate);
    }
  }

  void removeListing(String id) {
    final index = state.indexWhere((l) => l.id == id);
    if (index != -1) {
      final current = state[index];
      final list = [...state];
      list[index] = current.copyWith(status: ListingStatus.removed);
      state = list;
    }
  }

  // Admin actions
  void toggleFeatureListing(String id) {
    final index = state.indexWhere((l) => l.id == id);
    if (index != -1) {
      final current = state[index];
      final list = [...state];
      list[index] = current.copyWith(isFeatured: !current.isFeatured);
      state = list;
    }
  }
}

final listingProvider =
    StateNotifierProvider<ListingNotifier, List<FoodListingModel>>((ref) {
  return ListingNotifier();
});

final listingFilterProvider = StateProvider<ListingFilterOptions>((ref) {
  return const ListingFilterOptions();
});
