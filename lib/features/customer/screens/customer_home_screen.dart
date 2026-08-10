import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/food_provider.dart';
import '../widgets/location_header.dart';
import '../widgets/category_chip.dart';
import '../widgets/food_card.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodState = ref.watch(foodProvider);
    final filteredFood = ref.watch(filteredFoodProvider);
    
    final categories = [
      'All',
      'Breakfast',
      'Lunch',
      'Dinner',
      'Vegetarian',
      'Non-Vegetarian',
      'Under ₹30'
    ];

    // Separate home sections from filteredFood
    final endingSoonList = filteredFood
        .where((item) => !item.isExpired && item.pickupEnds.difference(DateTime.now()).inMinutes <= 90)
        .toList();
        
    final popularList = filteredFood
        .where((item) => !item.isExpired && item.availablePortions > 5)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding & Location Header
            const LocationHeader(),
            
            // Mock Search Bar (Tapping navigates to Search Tab)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () => context.go('/customer/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Search meals, PGs or messes...',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Categories Horizontal List
            SizedBox(
              height: 56,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = foodState.selectedCategory == cat;
                  return CategoryChip(
                    label: cat,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(foodProvider.notifier).updateCategory(cat);
                    },
                  );
                },
              ),
            ),
            
            // Feed Listings
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh state triggers if needed
                },
                child: filteredFood.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (foodState.selectedCategory == 'All') ...[
                            // Section: Ending Soon
                            if (endingSoonList.isNotEmpty) ...[
                              _buildSectionHeader('Ending Soon ⚡'),
                              const SizedBox(height: 8),
                              ...endingSoonList.take(2).map((food) => FoodCard(
                                    food: food,
                                    onTap: () => context.push('/customer/food/${food.id}'),
                                  )),
                              const SizedBox(height: 16),
                            ],

                            // Section: Popular Today
                            if (popularList.isNotEmpty) ...[
                              _buildSectionHeader('Popular Today 🔥'),
                              const SizedBox(height: 8),
                              ...popularList.take(2).map((food) => FoodCard(
                                    food: food,
                                    onTap: () => context.push('/customer/food/${food.id}'),
                                  )),
                              const SizedBox(height: 16),
                            ],
                            
                            // Section: Nearby Food
                            _buildSectionHeader('Nearby Food Marketplace 📍'),
                            const SizedBox(height: 8),
                          ],
                          
                          // General list of items
                          ...filteredFood.map((food) => FoodCard(
                                food: food,
                                onTap: () => context.push('/customer/food/${food.id}'),
                              )),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No meals found nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing your category filter or search query.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
