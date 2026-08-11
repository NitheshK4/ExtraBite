import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_listing.dart';

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
  // Starts with clean, real-time empty listings. Real listings are created dynamically by PG/Hostel Owners.
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
          return FoodListing(
            id: item.id,
            foodName: item.foodName,
            description: item.description,
            propertyId: item.propertyId,
            propertyName: item.propertyName,
            locationAddress: item.locationAddress,
            distanceKm: item.distanceKm,
            category: item.category,
            isVegetarian: item.isVegetarian,
            originalPrice: item.originalPrice,
            sellingPrice: item.sellingPrice,
            availablePortions: newPortions,
            preparedTime: item.preparedTime,
            pickupStarts: item.pickupStarts,
            pickupEnds: item.pickupEnds,
            ingredients: item.ingredients,
            allergens: item.allergens,
            verificationStatus: item.verificationStatus,
          );
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

final filteredFoodProvider = Provider<List<FoodListing>>((ref) {
  final state = ref.watch(foodProvider);
  
  // Filter out unverified properties
  var list = state.listings.where((item) => item.verificationStatus == 'verified').toList();
  
  // Apply Category Filter
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
  
  // Apply Search Query Filter
  if (state.searchQuery.isNotEmpty) {
    final query = state.searchQuery.toLowerCase();
    list = list.where((item) =>
      item.foodName.toLowerCase().contains(query) ||
      item.propertyName.toLowerCase().contains(query) ||
      item.category.toLowerCase().contains(query)
    ).toList();
  }
  
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
