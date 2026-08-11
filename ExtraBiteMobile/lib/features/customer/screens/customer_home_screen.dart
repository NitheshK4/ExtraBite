import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/food_provider.dart';
import '../../../providers/location_provider.dart';
import '../widgets/location_header.dart';
import '../widgets/category_chip.dart';
import '../widgets/food_card.dart';
import '../widgets/customer_map_view.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    // Proactively fetch GPS location on screen launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locState = ref.read(locationProvider);
      if (locState.status == LocationStatus.initial) {
        ref.read(locationProvider.notifier).requestAndFetchGPSLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final foodState = ref.watch(foodProvider);
    final filteredFood = ref.watch(filteredFoodProvider);
    final locationState = ref.watch(locationProvider);

    final categories = [
      'All',
      'Breakfast',
      'Lunch',
      'Dinner',
      'Vegetarian',
      'Non-Vegetarian',
      'Under ₹30'
    ];

    final isPermissionDenied = locationState.status == LocationStatus.denied ||
        locationState.status == LocationStatus.deniedForever ||
        locationState.status == LocationStatus.serviceDisabled;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding & GPS Location Header
            const LocationHeader(),

            // GPS Permission Explanation Banner (Shown if permission is denied / disabled)
            if (isPermissionDenied) ...[
              _buildPermissionBanner(locationState),
            ],

            // Search Bar & Map/List Toggle Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/customer/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Search meals, PGs or messes...',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Map / List Toggle Button
                  Container(
                    decoration: BoxDecoration(
                      color: _isMapView ? AppColors.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isMapView ? AppColors.primary : Colors.grey.shade200,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isMapView ? Icons.list_alt : Icons.map_outlined,
                        color: _isMapView ? Colors.white : AppColors.textPrimary,
                        size: 22,
                      ),
                      tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map View',
                      onPressed: () {
                        setState(() => _isMapView = !_isMapView);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Quick Radius Selector Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.radar, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Radius:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  ...[1000.0, 2000.0, 5000.0, 10000.0].map((radiusM) {
                    final isSelected = locationState.radiusMeters == radiusM;
                    final label = '${(radiusM / 1000).toInt()} km';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(locationProvider.notifier).setRadius(radiusM);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Categories Horizontal List (in list view)
            if (!_isMapView) ...[
              SizedBox(
                height: 52,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            ],

            // Content Area: Map View or List View
            Expanded(
              child: _isMapView
                  ? CustomerMapView(listings: filteredFood)
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(locationProvider.notifier).requestAndFetchGPSLocation();
                      },
                      child: filteredFood.isEmpty
                          ? _buildEmptyState(locationState)
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                // Nearby Food Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Meals Within ${locationState.radiusKm.toStringAsFixed(0)} km 📍',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${filteredFood.length} available',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // General list of nearest-first items
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

  Widget _buildPermissionBanner(LocationState locationState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_disabled, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enable GPS location to discover surplus meals within 2 km of your current hostel.',
              style: TextStyle(fontSize: 12, color: Colors.brown.shade800, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              ref.read(locationProvider.notifier).requestAndFetchGPSLocation();
            },
            child: const Text('Enable GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LocationState loc) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/branding/extrabite_logo.png',
                height: 72,
                width: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No surplus meals within ${loc.radiusKm.toStringAsFixed(0)} km',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No verified hostels or messes near "${loc.localityLabel}" have posted surplus food right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (loc.radiusMeters < 10000.0) ...[
              ElevatedButton.icon(
                onPressed: () {
                  final nextRadius = loc.radiusMeters == 1000.0
                      ? 2000.0
                      : loc.radiusMeters == 2000.0
                          ? 5000.0
                          : 10000.0;
                  ref.read(locationProvider.notifier).setRadius(nextRadius);
                },
                icon: const Icon(Icons.radar, size: 16),
                label: Text('Expand Search to ${(loc.radiusMeters < 2000.0 ? 2 : loc.radiusMeters < 5000.0 ? 5 : 10)} km'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () {
                ref.read(locationProvider.notifier).requestAndFetchGPSLocation();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh GPS Location'),
            ),
          ],
        ),
      ),
    );
  }
}

