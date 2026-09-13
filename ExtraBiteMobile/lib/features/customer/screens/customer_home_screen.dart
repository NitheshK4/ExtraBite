import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Branding & Location Header
            const LocationHeader(),

            // 2. Body based on Location State
            Expanded(
              child: _buildBody(
                locationState,
                foodState,
                categories,
                filteredFood,
                endingSoonList,
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
          subtitle: 'ExtraBite requires location access to discover surplus food listings near your campus.',
          actionText: 'Enable Location',
          onAction: () => ref.read(locationProvider.notifier).determinePosition(),
        );

      case LocationStateStatus.permissionPermanentlyDenied:
        return _buildStatusView(
          icon: Icons.block_outlined,
          iconColor: AppColors.error,
          title: 'Location permission permanently denied',
          subtitle: 'Please enable location permissions for ExtraBite in your device system settings to discover nearby food.',
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
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          title: 'Unable to determine location',
          subtitle: locationState.errorMessage ?? 'Something went wrong while retrieving your location.',
          actionText: 'Retry',
          onAction: () => ref.read(locationProvider.notifier).determinePosition(),
        );

      case LocationStateStatus.available:
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(foodProvider.notifier).loadListings();
            await ref.read(locationProvider.notifier).determinePosition();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Search Bar & Filter Button Section
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/customer/search'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Search meals, PGs or messes...',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => context.go('/customer/search'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: const Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Distance Radius Filter Pills
                    Row(
                      children: [
                        Text(
                          'Distance: ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRadiusPill(1.0, '1.0 km', selectedRadius),
                        const SizedBox(width: 6),
                        _buildRadiusPill(2.0, '2.0 km', selectedRadius),
                        const SizedBox(width: 6),
                        _buildRadiusPill(5.0, '5.0 km', selectedRadius),
                        const SizedBox(width: 6),
                        _buildRadiusPill(10.0, '10.0 km', selectedRadius),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Carousel
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = foodState.selectedCategory == cat;
                          Color? dot;
                          if (cat == 'Vegetarian') dot = AppColors.vegColor;
                          if (cat == 'Non-Vegetarian') dot = AppColors.nonVegColor;

                          return CategoryChip(
                            label: cat,
                            isSelected: isSelected,
                            dotColor: dot,
                            onTap: () {
                              ref.read(foodProvider.notifier).updateCategory(cat);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Listings content or True Empty State
              if (filteredFood.isEmpty)
                _buildEmptyState()
              else ...[
                // Ending Soon Carousel (Only on 'All' category and if endingSoonList has items)
                if (foodState.selectedCategory == 'All' && endingSoonList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              'Ending Soon',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => context.go('/customer/search'),
                          child: Text(
                            'View All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 264,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      scrollDirection: Axis.horizontal,
                      itemCount: endingSoonList.length,
                      itemBuilder: (context, index) {
                        final food = endingSoonList[index];
                        return FoodCard(
                          food: food,
                          isCompact: true,
                          onTap: () => context.push('/customer/food/${food.id}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nearby Fresh Surplus Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Nearby Fresh Surplus',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: filteredFood.map((food) => FoodCard(
                          food: food,
                          isCompact: false,
                          onTap: () => context.push('/customer/food/${food.id}'),
                        )).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildRadiusPill(double radius, String label, double selectedRadius) {
    final isSelected = (selectedRadius - radius).abs() < 0.1;
    return GestureDetector(
      onTap: () {
        ref.read(radiusProvider.notifier).state = radius;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No surplus meals nearby yet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'PGs and messes post extra portions after meal service times (Lunch: 1:30–3 PM, Dinner: 9–11 PM). Try expanding your radius or check back soon!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(foodProvider.notifier).loadListings();
                ref.read(locationProvider.notifier).determinePosition();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Feed'),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProgress) ...[
              const CircularProgressIndicator(color: AppColors.primary),
            ] else ...[
              Icon(icon, size: 52, color: iconColor),
            ],
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
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
