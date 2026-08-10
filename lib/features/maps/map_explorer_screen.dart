import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/food_listing_model.dart';
import '../../services/location_service.dart';
import '../../data/repositories/listing_repository.dart';
import 'widgets/map_listing_preview.dart';

class MapExplorerScreen extends ConsumerStatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  ConsumerState<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends ConsumerState<MapExplorerScreen> {
  GoogleMapController? _mapController;
  FoodListingModel? _selectedListing;
  bool _useFallbackSimulatedMap = false;

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);
    final allListings = ref.watch(listingProvider);
    final nearbyListings = locationNotifier.filterByRadius(allListings);

    final markers = nearbyListings.map((listing) {
      return Marker(
        markerId: MarkerId(listing.id),
        position: LatLng(listing.latitude, listing.longitude),
        infoWindow: InfoWindow(
          title: listing.title,
          snippet: '₹${listing.discountedPrice.round()} • ${listing.pgName}',
        ),
        onTap: () {
          setState(() => _selectedListing = listing);
        },
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Nearby Surplus'),
        actions: [
          IconButton(
            icon: Icon(_useFallbackSimulatedMap ? Icons.map_rounded : Icons.view_quilt_rounded),
            tooltip: _useFallbackSimulatedMap ? 'Switch to Google Maps' : 'Switch to Grid Map',
            onPressed: () {
              setState(() => _useFallbackSimulatedMap = !_useFallbackSimulatedMap);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Native Google Map or Elegant Interactive Map Grid
          _useFallbackSimulatedMap
              ? _buildSimulatedInteractiveMap(nearbyListings, locationState)
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(locationState.latitude, locationState.longitude),
                    zoom: 14.0,
                  ),
                  markers: markers,
                  myLocationEnabled: locationState.hasPermission,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (_) {
                    setState(() => _selectedListing = null);
                  },
                ),

          // Top Radius Chips Bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Radius:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                              label: Text('${radius.toInt()} km'),
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
            ),
          ),

          // Floating Recenter Button
          Positioned(
            bottom: _selectedListing != null ? 180 : 30,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.my_location_rounded),
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(locationState.latitude, locationState.longitude),
                  ),
                );
              },
            ),
          ),

          // Selected Listing Preview Card
          if (_selectedListing != null)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: MapListingPreview(listing: _selectedListing!),
            ),
        ],
      ),
    );
  }

  Widget _buildSimulatedInteractiveMap(
    List<FoodListingModel> listings,
    LocationState locationState,
  ) {
    return Container(
      color: const Color(0xFFE8ECEF),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.place_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'Interactive Nearby PGs (${listings.length} within ${locationState.selectedRadiusKm.toInt()} km)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: listings.map((item) {
                  final isSelected = _selectedListing?.id == item.id;
                  return ActionChip(
                    avatar: Icon(
                      Icons.restaurant_rounded,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 16,
                    ),
                    label: Text('${item.title} (₹${item.discountedPrice.round()})'),
                    backgroundColor: isSelected ? AppColors.primary : Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: () {
                      setState(() => _selectedListing = item);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
