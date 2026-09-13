import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food_listing.dart';

class FoodRepository {
  final SupabaseClient? _client;

  FoodRepository(SupabaseClient client) : _client = client;

  /// Named constructor for use in tests – does not create a SupabaseClient.
  /// Do not use in production code.
  FoodRepository.fakeForTest() : _client = null;

  bool get isFakeForTest => _client == null;

  static List<FoodListing> getTestMockData() => _getTestMockData();

  /// Realtime channel subscription for instant live updates across customers & owners
  RealtimeChannel? subscribeToListingsChanges(void Function() onListingChanged) {
    if (_client == null) return null;
    try {
      final channel = _client.channel('public:food_listings_changes')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'food_listings',
          callback: (payload) {
            onListingChanged();
          },
        )
        ..subscribe();
      return channel;
    } catch (_) {
      return null;
    }
  }

  /// Fetch all active food listings with pg details
  Future<List<FoodListing>> fetchListings() async {
    if (_client == null) {
      return _getTestMockData();
    }
    try {
      final response = await _client
          .from('food_listings')
          .select('*, pg_profiles(*)')
          .neq('status', 'removed');

      final List<dynamic> data = response as List<dynamic>;
      final List<FoodListing> listings = [];

      for (final item in data) {
        final pgRow = item['pg_profiles'] as Map<String, dynamic>?;
        if (pgRow != null) {
          listings.add(FoodListing.fromSupabase(item as Map<String, dynamic>, pgRow));
        }
      }
      return listings;
    } catch (e) {
      // In production, an error or empty database yields an empty list
      return [];
    }
  }

  static List<FoodListing> _getTestMockData() {
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
        latitude: 16.4950,
        longitude: 80.5070,
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
        latitude: 16.4920,
        longitude: 80.5100,
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
        latitude: 16.4990,
        longitude: 80.4960,
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
        latitude: 16.4850,
        longitude: 80.4850,
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
        latitude: 16.4950,
        longitude: 80.5070,
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
        pickupEnds: now.add(const Duration(minutes: 30)),
        ingredients: ['Rice', 'Lemon Juice', 'Peanuts', 'Curry Leaves', 'Turmeric'],
        allergens: ['Peanuts', 'Mustard'],
        verificationStatus: 'verified',
        latitude: 16.5050,
        longitude: 80.5120,
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
        pickupEnds: now.subtract(const Duration(minutes: 10)),
        ingredients: ['Basmati Rice', 'Carrots', 'Green Peas', 'Yogurt', 'Spices'],
        allergens: ['Dairy'],
        verificationStatus: 'verified',
        latitude: 16.5200,
        longitude: 80.5200,
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
        latitude: 16.4920,
        longitude: 80.5100,
      ),
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
        latitude: 16.4900,
        longitude: 80.4950,
      ),
    ];
  }

  /// Fetch PG Profile associated with an owner ID
  Future<Map<String, dynamic>?> fetchOwnerPg(String ownerId) async {
    try {
      final response = await _client!
          .from('pg_profiles')
          .select()
          .eq('owner_id', ownerId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Upload compressed food image to 'food-images' storage bucket
  Future<String?> uploadFoodImage(Uint8List bytes, String pgId, String extension) async {
    try {
      final fileName = '$pgId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _client!.storage.from('food-images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
            ),
          );

      final String publicUrl = _client.storage.from('food-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  /// Create and insert a new food listing
  Future<FoodListing> createListing(Map<String, dynamic> rowData, Map<String, dynamic> pgRow) async {
    final response = await _client!
        .from('food_listings')
        .insert(rowData)
        .select()
        .single();
    
    return FoodListing.fromSupabase(response, pgRow);
  }

  /// Update available portions for a food listing in Supabase
  Future<void> updatePortions(String listingId, int portions) async {
    if (_client == null) return;
    await _client
        .from('food_listings')
        .update({'available_portions': portions})
        .eq('id', listingId);
  }

  /// Mark a food listing as removed in Supabase
  Future<void> removeListing(String listingId) async {
    if (_client == null) return;
    await _client
        .from('food_listings')
        .update({'status': 'removed'})
        .eq('id', listingId);
  }
}
