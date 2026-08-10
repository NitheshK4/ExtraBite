import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/permissions/permission_service.dart';
import '../../services/location_service.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../listings/widgets/listing_card.dart';
import 'widgets/filter_bottom_sheet.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);
    final allListings = ref.watch(listingProvider);
    final filters = ref.watch(listingFilterProvider);

    // 1. Filter listings by radius
    var filteredListings = locationNotifier.filterByRadius(allListings);

    // 2. Filter by search query
    if (filters.searchQuery.isNotEmpty) {
      final q = filters.searchQuery.toLowerCase();
      filteredListings = filteredListings.where((l) {
        return l.title.toLowerCase().contains(q) ||
            l.pgName.toLowerCase().contains(q) ||
            l.neighborhood.toLowerCase().contains(q) ||
            l.category.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Filter by dietary type
    if (filters.dietaryType != null) {
      filteredListings = filteredListings
          .where((l) => l.dietaryType == filters.dietaryType)
          .toList();
    }

    // 4. Filter by max price
    if (filters.maxPrice != null) {
      filteredListings = filteredListings
          .where((l) => l.discountedPrice <= filters.maxPrice!)
          .toList();
    }

    // 5. Filter by availability
    if (filters.onlyAvailableNow) {
      filteredListings = filteredListings.where((l) => l.isAvailable).toList();
    }

    // 6. Filter excluded allergens
    if (filters.excludedAllergens.isNotEmpty) {
      filteredListings = filteredListings.where((l) {
        return !l.allergens.any((a) => filters.excludedAllergens.contains(a));
      }).toList();
    }

    // 7. Sort listings
    switch (filters.sortBy) {
      case 'lowestPrice':
        filteredListings.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case 'earliestPickup':
        filteredListings.sort((a, b) => a.pickupEndTime.compareTo(b.pickupEndTime));
        break;
      case 'highestRated':
        filteredListings.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        filteredListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'nearest':
      default:
        filteredListings.sort((a, b) {
          final distA = locationNotifier.distanceToListing(a);
          final distB = locationNotifier.distanceToListing(b);
          return distA.compareTo(distB);
        });
        break;
    }

    final featuredListings = allListings.where((l) => l.isFeatured && l.isAvailable).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  locationState.isLiveGps ? 'Current Location' : 'Nearby PGs',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Text(
              locationState.humanReadableAddress,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Map View',
            onPressed: () => context.push('/map'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filters',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const FilterBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await locationNotifier.checkAndFetchCurrentLocation();
        },
        child: CustomScrollView(
          slivers: [
            // Search Bar & GPS Status Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // Search box
                    GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: Colors.grey.shade600),
                            const SizedBox(width: 10),
                            Text(
                              'Search dish, PG name, or locality...',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!locationState.hasPermission) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final granted = await PermissionService.requestLocationPermission(context);
                          if (granted) {
                            locationNotifier.checkAndFetchCurrentLocation();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Enable GPS for exact live distance calculations',
                                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Radius Filter Chips (1km, 2km [default], 5km, 10km)
                    Row(
                      children: [
                        const Text(
                          'Radius:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: AppConstants.radiusOptionsKm.map((radius) {
                                final isSelected = locationState.selectedRadiusKm == radius;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: ChoiceChip(
                                    label: Text('${radius.toInt()} km${radius == 2.0 ? ' (Default)' : ''}'),
                                    selected: isSelected,
                                    selectedColor: AppColors.primary.withOpacity(0.2),
                                    onSelected: (selected) {
                                      if (selected) {
                                        locationNotifier.updateRadius(radius);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Featured Carousel (if any)
            if (featuredListings.isNotEmpty && filters.searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text(
                        'Featured Surplus Deals',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 350,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: featuredListings.length,
                    itemBuilder: (context, index) {
                      final item = featuredListings[index];
                      return SizedBox(
                        width: 300,
                        child: ListingCard(
                          listing: item,
                          onTap: () {
                            ref.read(listingProvider.notifier).markAsViewed(item.id);
                            context.push('/listing/${item.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meals Within ${locationState.selectedRadiusKm.toInt()} km (${filteredListings.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (filteredListings.isNotEmpty)
                      const Text(
                        'Pay at pickup only',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Listings List or Empty State
            if (filteredListings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.no_food_rounded,
                  title: 'No meals within ${locationState.selectedRadiusKm.toInt()} km',
                  subtitle: 'Try expanding your distance radius to 5 km or 10 km, or check back during the next lunch/dinner pickup window.',
                  actionLabel: 'Expand to 5 km',
                  onAction: () {
                    locationNotifier.updateRadius(5.0);
                  },
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredListings[index];
                    return ListingCard(
                      listing: item,
                      onTap: () {
                        ref.read(listingProvider.notifier).markAsViewed(item.id);
                        context.push('/listing/${item.id}');
                      },
                    );
                  },
                  childCount: filteredListings.length,
                ),
              ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}
