import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/food_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/food_card.dart';
import '../../widgets/distance_badge.dart';
import '../../models/user_role.dart';
import 'food_detail_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _isMapView = false;

  @override
  Widget build(BuildContext context) {
    final filteredListings = ref.watch(filteredListingsProvider);
    final locationState = ref.watch(locationStateProvider);
    final locationNotifier = ref.read(locationProvider.notifier);
    final foodState = ref.watch(foodProvider);
    final foodNotifier = ref.read(foodProvider.notifier);
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationState.currentArea,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              'Showing food within ${locationState.radiusKm.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        actions: [
          // View Switcher (Map vs List)
          IconButton(
            icon: Icon(_isMapView ? Icons.view_list : Icons.map),
            tooltip: _isMapView ? 'Switch to List' : 'Switch to Map',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          // Role Badge Chip
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<UserRole>(
              initialValue: userState.currentRole,
              child: Chip(
                avatar: const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                label: Text(
                  userState.currentRole.displayName,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: Colors.white.withOpacity(0.2),
                visualDensity: VisualDensity.compact,
              ),
              onSelected: (role) {
                ref.read(userProvider.notifier).switchRole(role);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: UserRole.customer,
                  child: Text('Customer Role'),
                ),
                const PopupMenuItem(
                  value: UserRole.pgOwner,
                  child: Text('PG Owner Role'),
                ),
                const PopupMenuItem(
                  value: UserRole.admin,
                  child: Text('Admin Role'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: foodNotifier.updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Search food item or PG name...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Radius Filter Selector Bar (2 km is default)
                Row(
                  children: [
                    const Text(
                      'Radius:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [1.0, 2.0, 5.0, 10.0].map((radius) {
                            final isSelected = locationState.radiusKm == radius;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('${radius.toInt()} km'),
                                selected: isSelected,
                                selectedColor: Colors.orangeAccent,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                                visualDensity: VisualDensity.compact,
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

          // Category Chips Bar (All, Breakfast, Lunch, Dinner, Snacks)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildCategoryChip('All', foodState.selectedCategory == 'All'),
                _buildCategoryChip('Breakfast', foodState.selectedCategory == 'Breakfast'),
                _buildCategoryChip('Lunch', foodState.selectedCategory == 'Lunch'),
                _buildCategoryChip('Dinner', foodState.selectedCategory == 'Dinner'),
                _buildCategoryChip('Snacks', foodState.selectedCategory == 'Snacks'),
                const SizedBox(width: 8),
                const VerticalDivider(width: 1),
                const SizedBox(width: 8),
                // Dietary filter chips
                FilterChip(
                  label: const Text('Veg Only'),
                  selected: foodState.isVegFilter == true,
                  onSelected: (selected) {
                    foodNotifier.setDietaryFilter(selected ? true : null);
                  },
                  visualDensity: VisualDensity.compact,
                  avatar: const CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 4,
                  ),
                ),
              ],
            ),
          ),

          // Main Listing Content (List or Map)
          Expanded(
            child: _isMapView
                ? _buildMapView(filteredListings, locationNotifier)
                : _buildListView(filteredListings, locationNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF2E7D32),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        visualDensity: VisualDensity.compact,
        onSelected: (selected) {
          if (selected) {
            ref.read(foodProvider.notifier).setCategory(label);
          }
        },
      ),
    );
  }

  Widget _buildListView(List filteredListings, LocationNotifier locationNotifier) {
    if (filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No surplus meals found nearby',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try increasing your radius slider above.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredListings.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final food = filteredListings[index];
        final distanceKm = locationNotifier.calculateDistance(
          food.latitude,
          food.longitude,
        );

        return FoodCard(
          food: food,
          distanceKm: distanceKm,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FoodDetailScreen(food: food),
              ),
            );
          },
          onReserveTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FoodDetailScreen(food: food),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView(List filteredListings, LocationNotifier locationNotifier) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                const Icon(Icons.map, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${filteredListings.length} PG surplus meals on map inside radius',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredListings.length,
              itemBuilder: (context, index) {
                final food = filteredListings[index];
                final distanceKm = locationNotifier.calculateDistance(
                  food.latitude,
                  food.longitude,
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(food.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${food.pgName} • Pay ₹${food.pickupPrice.toStringAsFixed(0)} at pickup'),
                  trailing: DistanceBadge(distanceKm: distanceKm, isCompact: true),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodDetailScreen(food: food),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Helper getter provider to avoid collision
final locationStateProvider = Provider((ref) => ref.watch(locationProvider));
