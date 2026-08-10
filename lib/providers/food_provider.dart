import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_listing.dart';
import 'location_provider.dart';

class FoodState {
  final List<FoodListing> allListings;
  final String searchQuery;
  final String selectedCategory; // All, Breakfast, Lunch, Dinner, Snacks
  final bool? isVegFilter; // null = all, true = veg, false = non-veg

  FoodState({
    required this.allListings,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.isVegFilter,
  });

  FoodState copyWith({
    List<FoodListing>? allListings,
    String? searchQuery,
    String? selectedCategory,
    bool? isVegFilter,
  }) {
    return FoodState(
      allListings: allListings ?? this.allListings,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isVegFilter: isVegFilter,
    );
  }
}

class FoodNotifier extends StateNotifier<FoodState> {
  FoodNotifier() : super(FoodState(allListings: _getInitialListings()));

  static List<FoodListing> _getInitialListings() {
    final now = DateTime.now();
    return [
      FoodListing(
        id: 'food_001',
        title: 'Paneer Butter Masala & Rotis',
        pgName: 'Sunrise Executive Boys PG',
        description:
            'Freshly cooked North Indian dinner combo. Includes 4 butter rotis, paneer gravy, and jeera rice. Clean kitchen guaranteed.',
        availablePortions: 8,
        totalPortions: 15,
        originalPrice: 120.0,
        pickupPrice: 45.0, // Pay at pickup
        isVeg: true,
        category: 'Dinner',
        latitude: 12.9370, // ~0.4 km away
        longitude: 77.6260,
        address: '#42, 4th Cross, Koramangala 5th Block',
        createdAt: now.subtract(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(hours: 2, minutes: 15)),
        imageUrl:
            'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600&auto=format&fit=crop',
      ),
      FoodListing(
        id: 'food_002',
        title: 'South Indian Meal Thali',
        pgName: 'Sri Lakshmi Luxury Ladies Hostel',
        description:
            'Authentic South Indian lunch package: Sambar rice, rasam, curd rice, papad, and poriyal. Packed hot in eco containers.',
        availablePortions: 5,
        totalPortions: 10,
        originalPrice: 100.0,
        pickupPrice: 35.0,
        isVeg: true,
        category: 'Lunch',
        latitude: 12.9310, // ~0.8 km away
        longitude: 77.6210,
        address: '#118, 8th Main, Koramangala 6th Block',
        createdAt: now.subtract(const Duration(minutes: 45)),
        expiresAt: now.add(const Duration(hours: 1, minutes: 45)),
        imageUrl:
            'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600&auto=format&fit=crop',
      ),
      FoodListing(
        id: 'food_003',
        title: 'Chicken Biryani & Raita',
        pgName: 'Greenwood Co-Living Hostel',
        description:
            'Flavorful Hyderabadi chicken biryani cooked for dinner mess. Generous portion with onion raita and boiled egg.',
        availablePortions: 4,
        totalPortions: 8,
        originalPrice: 160.0,
        pickupPrice: 60.0,
        isVeg: false,
        category: 'Dinner',
        latitude: 12.9420, // ~1.4 km away
        longitude: 77.6310,
        address: '#89, 1st Main, Sony World Signal, Koramangala',
        createdAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.add(const Duration(hours: 3)),
        imageUrl:
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop',
      ),
      FoodListing(
        id: 'food_004',
        title: 'Idli Vada & Chutney Box',
        pgName: 'Comfort Stay PG',
        description:
            'Hot breakfast combo: 3 steamed idlis, 1 crispy vada, coconut chutney & sambar. Prepared fresh this morning.',
        availablePortions: 12,
        totalPortions: 20,
        originalPrice: 80.0,
        pickupPrice: 25.0,
        isVeg: true,
        category: 'Breakfast',
        latitude: 12.9280, // ~1.8 km away
        longitude: 77.6180,
        address: '#204, BTM 1st Stage near Gangothri',
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(minutes: 40)),
        imageUrl:
            'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&auto=format&fit=crop',
      ),
      FoodListing(
        id: 'food_005',
        title: 'Samosa & Masala Tea Combo',
        pgName: 'Metro View Co-Living',
        description:
            'Crispy potato samosas (2 pcs) with mint chutney and hot cardamom tea flask.',
        availablePortions: 6,
        totalPortions: 12,
        originalPrice: 60.0,
        pickupPrice: 20.0,
        isVeg: true,
        category: 'Snacks',
        latitude: 12.9550, // ~3.5 km away (outside 2km default radius)
        longitude: 77.6400,
        address: '#55, Indiranagar 100ft Road',
        createdAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.add(const Duration(hours: 2)),
        imageUrl:
            'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&auto=format&fit=crop',
      ),
    ];
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setDietaryFilter(bool? isVeg) {
    state = state.copyWith(isVegFilter: isVeg);
  }

  void addListing(FoodListing newListing) {
    state = state.copyWith(
      allListings: [newListing, ...state.allListings],
    );
  }

  void decrementPortions(String listingId, int count) {
    final updated = state.allListings.map((item) {
      if (item.id == listingId) {
        final remaining = item.availablePortions - count;
        return item.copyWith(
          availablePortions: remaining < 0 ? 0 : remaining,
          isAvailable: remaining > 0,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(allListings: updated);
  }
}

final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  return FoodNotifier();
});

// Provider that calculates distance and filters listings within current radius
final filteredListingsProvider = Provider<List<FoodListing>>((ref) {
  final foodState = ref.watch(foodProvider);
  final locationState = ref.watch(locationProvider);
  final locationNotifier = ref.read(locationProvider.notifier);

  return foodState.allListings.where((listing) {
    // 1. GPS Distance Filter within radiusKm (Default 2.0 km)
    final distance = locationNotifier.calculateDistance(
      listing.latitude,
      listing.longitude,
    );
    if (distance > locationState.radiusKm) {
      return false;
    }

    // 2. Search Query filter
    if (foodState.searchQuery.isNotEmpty) {
      final q = foodState.searchQuery.toLowerCase();
      final matchTitle = listing.title.toLowerCase().contains(q);
      final matchPg = listing.pgName.toLowerCase().contains(q);
      if (!matchTitle && !matchPg) return false;
    }

    // 3. Category Filter
    if (foodState.selectedCategory != 'All' &&
        listing.category != foodState.selectedCategory) {
      return false;
    }

    // 4. Dietary Filter
    if (foodState.isVegFilter != null &&
        listing.isVeg != foodState.isVegFilter) {
      return false;
    }

    // 5. Availability & Expiry
    if (!listing.isAvailable || listing.availablePortions <= 0) {
      return false;
    }

    return true;
  }).toList();
});
