import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/food_listing.dart';
import '../../../providers/food_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../core/location/location_state.dart';
import '../widgets/location_header.dart';
import '../widgets/category_chip.dart';
import '../widgets/food_card.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch user location on home startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).determinePosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final foodState = ref.watch(foodProvider);
    final locationState = ref.watch(locationProvider);
    final filteredFood = ref.watch(filteredFoodProvider);
    final selectedRadius = ref.watch(radiusProvider);

    final categories = [
      'All',
      'Breakfast',
      'Lunch',
      'Dinner',
      'Vegetarian',
      'Non-Vegetarian',
      'Under ₹30'
    ];

    // Filter home lists
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
            
            // Render body based on location state
            Expanded(
              child: _buildBody(
                locationState,
                foodState,
                categories,
                filteredFood,
                endingSoonList,
                popularList,
                selectedRadius,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    LocationState locationState,
    FoodState foodState,
    List<String> categories,
    List<FoodListing> filteredFood,
    List<FoodListing> endingSoonList,
    List<FoodListing> popularList,
    double selectedRadius,
  ) {
    switch (locationState.status) {
      case LocationStateStatus.initial:
      case LocationStateStatus.loading:
        return _buildStatusView(
          icon: Icons.my_location,
          iconColor: AppColors.primary,
          title: 'Detecting your location...',
          subtitle: 'Please wait while we determine your coordinates to find nearby hostels & messes.',
          isProgress: true,
        );

      case LocationStateStatus.permissionDenied:
        return _buildStatusView(
          icon: Icons.location_off_outlined,
          iconColor: AppColors.secondary,
          title: 'Location permission required',
          subtitle: 'SavourE requires foreground location access to show surplus food available near you.',
          actionText: 'Enable Location',
          onAction: () => ref.read(locationProvider.notifier).determinePosition(),
        );

      case LocationStateStatus.permissionPermanentlyDenied:
        return _buildStatusView(
          icon: Icons.block_outlined,
          iconColor: AppColors.error,
          title: 'Location permission permanently denied',
          subtitle: 'Please enable location permissions for SavourE in your device system settings to discover nearby food.',
          actionText: 'Retry',
          onAction: () => ref.read(locationProvider.notifier).determinePosition(),
        );

      case LocationStateStatus.serviceDisabled:
        return _buildStatusView(
          icon: Icons.gps_off_outlined,
          iconColor: AppColors.secondary,
          title: 'Location services are turned off',
          subtitle: 'Please turn on GPS/location services on your device to fetch nearby surplus listings.',
          actionText: 'Enable Location',
          onAction: () => ref.read(locationProvider.notifier).determinePosition(),
        );

      case LocationStateStatus.error:
        return _buildStatusView(
          icon: Icons.error_outline_sharp,
          iconColor: AppColors.error,
          title: 'Unable to determine location',
          subtitle: locationState.errorMessage ?? 'Something went wrong while retrieving your location.',
          actionText: 'Retry',
          onAction: () => ref.read(locationProvider.notifier).determinePosition(),
        );

      case LocationStateStatus.available:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  ref.read(foodProvider.notifier).refreshListings();
                  await ref.read(locationProvider.notifier).determinePosition();
                },

                child: filteredFood.isEmpty
                    ? _buildEmptyState(selectedRadius)
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
        );
    }
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

  Widget _buildEmptyState(double radius) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/branding/extrabite_logo.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals within ${radius.toInt()} km',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your category filter or increasing your search radius.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isProgress = false,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProgress) ...[
              const CircularProgressIndicator(color: AppColors.primary),
            ] else ...[
              Icon(icon, size: 64, color: iconColor),
            ],
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
