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
  FoodNotifier() : super(FoodState(listings: _getInitialMockData(), searchQuery: '', selectedCategory: 'All'));

  static List<FoodListing> _getInitialMockData() {
    final now = DateTime.now();
    return [
      FoodListing(
        id: '1',
        foodName: 'Veg Meals',
        description: 'Nutritious South Indian thali featuring rice, sambar, rasam, two vegetable curries, curd, and papad.',
        propertyId: 'p1',
        propertyName: 'Sri Sai Deluxe PG',
        distanceKm: 0.8,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 80.0,
        sellingPrice: 40.0,
        availablePortions: 8,
        preparedTime: now.subtract(const Duration(hours: 1)),
        pickupStarts: now.subtract(const Duration(minutes: 30)),
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: ['Rice', 'Lentils', 'Mixed Vegetables', 'Curd', 'Coconut'],
        allergens: ['Mustard', 'Dairy'],
        verificationStatus: 'verified',
      ),
      FoodListing(
        id: '2',
        foodName: 'Chicken Rice',
        description: 'Aromatic basmati rice cooked with succulent chicken pieces and traditional spices, served with raita.',
        propertyId: 'p2',
        propertyName: 'Royal Men\'s Hostel',
        distanceKm: 1.2,
        category: 'Dinner',
        isVegetarian: false,
        originalPrice: 120.0,
        sellingPrice: 60.0,
        availablePortions: 4,
        preparedTime: now.subtract(const Duration(hours: 2)),
        pickupStarts: now.subtract(const Duration(hours: 1)),
        pickupEnds: now.add(const Duration(hours: 1, minutes: 30)),
        ingredients: ['Basmati Rice', 'Chicken', 'Yogurt', 'Onions', 'Spices'],
        allergens: ['Dairy'],
        verificationStatus: 'verified',
      ),
      FoodListing(
        id: '3',
        foodName: 'Idli & Vada Combo',
        description: 'Fluffy steamed rice cakes (3 pcs) paired with a crispy lentil donut (1 pc), served with fresh coconut chutney and hot sambar.',
        propertyId: 'p3',
        propertyName: 'Green Gardens PG',
        distanceKm: 0.5,
        category: 'Breakfast',
        isVegetarian: true,
        originalPrice: 50.0,
        sellingPrice: 25.0,
        availablePortions: 12,
        preparedTime: now.subtract(const Duration(minutes: 45)),
        pickupStarts: now.subtract(const Duration(minutes: 15)),
        pickupEnds: now.add(const Duration(hours: 1)),
        ingredients: ['Rice', 'Urad Dal', 'Coconut', 'Tamarind', 'Spices'],
        allergens: ['Mustard'],
        verificationStatus: 'verified',
      ),
      FoodListing(
        id: '4',
        foodName: 'Paneer Rice',
        description: 'Fragrant fried rice tossed with golden paneer cubes, spring onions, capsicum, and light soy sauce.',
        propertyId: 'p4',
        propertyName: 'Stanza Living Delhi PG',
        distanceKm: 2.3,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 100.0,
        sellingPrice: 50.0,
        availablePortions: 6,
        preparedTime: now.subtract(const Duration(hours: 1, minutes: 30)),
        pickupStarts: now.subtract(const Duration(hours: 1)),
        pickupEnds: now.add(const Duration(hours: 2, minutes: 30)),
        ingredients: ['Rice', 'Paneer', 'Capsicum', 'Spring Onion', 'Soy Sauce'],
        allergens: ['Dairy', 'Soy', 'Gluten'],
        verificationStatus: 'verified',
      ),
      FoodListing(
        id: '5',
        foodName: 'Chapati Curry',
        description: 'Soft whole-wheat chapatis (3 pcs) served with a flavorful mixed vegetable korma curry.',
        propertyId: 'p1',
        propertyName: 'Sri Sai Deluxe PG',
        distanceKm: 0.8,
        category: 'Dinner',
        isVegetarian: true,
        originalPrice: 60.0,
        sellingPrice: 30.0,
        availablePortions: 15,
        preparedTime: now.subtract(const Duration(minutes: 30)),
        pickupStarts: now.add(const Duration(minutes: 30)),
        pickupEnds: now.add(const Duration(hours: 3)),
        ingredients: ['Wheat Flour', 'Potatoes', 'Carrots', 'Beans', 'Coconut Milk'],
        allergens: ['Gluten'],
        verificationStatus: 'verified',
      ),
      FoodListing(
        id: '6',
        foodName: 'Lemon Rice',
        description: 'Tangy and refreshing rice dish tempered with mustard seeds, curry leaves, peanuts, and fresh lemon juice.',
        propertyId: 'p5',
        propertyName: 'Modern Mess & PG',
        distanceKm: 1.5,
        category: 'Lunch',
        isVegetarian: true,
        originalPrice: 40.0,
        sellingPrice: 20.0,
        availablePortions: 5,
        preparedTime: now.subtract(const Duration(hours: 3)),
        pickupStarts: now.subtract(const Duration(hours: 2)),
        pickupEnds: now.add(const Duration(minutes: 30)), // Ending Soon
        ingredients: ['Rice', 'Lemon Juice', 'Peanuts', 'Curry Leaves', 'Turmeric'],
        allergens: ['Peanuts', 'Mustard'],
        verificationStatus: 'verified',
      ),
      FoodListing(
        id: '7',
        foodName: 'Veg Biryani',
        description: 'Rich, layered vegetable biryani cooked in dum style with saffron, fried onions, and mixed veggies, served with raita.',
        propertyId: 'p6',
        propertyName: 'Aura Executive PG',
        distanceKm: 3.1,
        category: 'Dinner',
        isVegetarian: true,
        originalPrice: 110.0,
        sellingPrice: 55.0,
        availablePortions: 7,
        preparedTime: now.subtract(const Duration(hours: 4)),
        pickupStarts: now.subtract(const Duration(hours: 3, minutes: 30)),
        pickupEnds: now.subtract(const Duration(minutes: 10)), // Expired
        ingredients: ['Basmati Rice', 'Carrots', 'Green Peas', 'Yogurt', 'Spices'],
        allergens: ['Dairy'],
        verificationStatus: 'verified',
      ),
      FoodListing(
        id: '8',
        foodName: 'Egg Rice',
        description: 'Stir-fried rice cooked with scrambled eggs, onions, bell peppers, and touch of pepper and spice.',
        propertyId: 'p2',
        propertyName: 'Royal Men\'s Hostel',
        distanceKm: 1.2,
        category: 'Dinner',
        isVegetarian: false,
        originalPrice: 70.0,
        sellingPrice: 35.0,
        availablePortions: 9,
        preparedTime: now.subtract(const Duration(hours: 1)),
        pickupStarts: now.subtract(const Duration(minutes: 15)),
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: ['Rice', 'Eggs', 'Onion', 'Bell Pepper', 'Spices'],
        allergens: ['Egg'],
        verificationStatus: 'verified',
      ),
      // Unverified listing (Should be filtered out)
      FoodListing(
        id: '9',
        foodName: 'Unverified Biryani',
        description: 'Should not appear in customer feed.',
        propertyId: 'p9',
        propertyName: 'Unverified Hostel',
        distanceKm: 1.0,
        category: 'Lunch',
        isVegetarian: false,
        originalPrice: 100.0,
        sellingPrice: 50.0,
        availablePortions: 5,
        preparedTime: now,
        pickupStarts: now,
        pickupEnds: now.add(const Duration(hours: 2)),
        ingredients: ['Rice'],
        allergens: [],
        verificationStatus: 'unverified',
      ),
    ];
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateCategory(String category) {
    state = state.copyWith(selectedCategory: category);
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
