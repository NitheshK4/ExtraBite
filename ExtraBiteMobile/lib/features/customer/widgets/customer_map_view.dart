import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/food_listing.dart';
import '../../../providers/location_provider.dart';

class CustomerMapView extends ConsumerStatefulWidget {
  final List<FoodListing> listings;

  const CustomerMapView({
    super.key,
    required this.listings,
  });

  @override
  ConsumerState<CustomerMapView> createState() => _CustomerMapViewState();
}

class _CustomerMapViewState extends ConsumerState<CustomerMapView> {
  GoogleMapController? _mapController;
  bool _mapRenderFailed = false;

  @override
  void didUpdateWidget(CustomerMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapController != null) {
      final loc = ref.read(locationProvider);
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.latitude, loc.longitude)),
      );
    }
  }

  void _onMarkerTapped(FoodListing food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ListingPreviewBottomSheet(food: food),
    );
  }

  Set<Marker> _buildMarkers(LocationState loc) {
    final markers = <Marker>{};

    // 1. Blue marker for Customer GPS Location
    markers.add(
      Marker(
        markerId: const MarkerId('user_current_location'),
        position: LatLng(loc.latitude, loc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: 'You Are Here',
          snippet: loc.localityLabel,
        ),
      ),
    );

    // 2. Green markers for each nearby PG / Food Listing inside radius
    for (final food in widget.listings) {
      markers.add(
        Marker(
          markerId: MarkerId('listing_${food.id}'),
          position: LatLng(food.latitude, food.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            food.isVegetarian ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: food.foodName,
            snippet: '${food.propertyName} • ₹${food.sellingPrice.toInt()} (${food.formattedDistance})',
          ),
          onTap: () => _onMarkerTapped(food),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles(LocationState loc) {
    return {
      Circle(
        circleId: const CircleId('discovery_radius_circle'),
        center: LatLng(loc.latitude, loc.longitude),
        radius: loc.radiusMeters, // Dynamic radius in meters (e.g. 2000)
        fillColor: AppColors.primary.withOpacity(0.12),
        strokeColor: AppColors.primary,
        strokeWidth: 2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final centerLatLng = LatLng(locationState.latitude, locationState.longitude);

    if (_mapRenderFailed) {
      return _buildSpatialRadarFallback(locationState);
    }

    return Stack(
      children: [
        // Native Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: centerLatLng,
            zoom: locationState.radiusMeters <= 2000 ? 14.5 : 13.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          markers: _buildMarkers(locationState),
          circles: _buildCircles(locationState),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onCameraMove: null,
        ),

        // Top Radius & Count Floating Badge
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radar, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.listings.length} surplus meals nearby',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Within ${locationState.radiusKm.toStringAsFixed(0)} km radius • Tap green pins to preview',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Recenter Button
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: () {
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(locationState.latitude, locationState.longitude),
                    14.5,
                  ),
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  /// Spatial Radar Fallback (renders if map fails or offline)
  Widget _buildSpatialRadarFallback(LocationState loc) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.5),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                ),
                child: const Center(
                  child: Icon(Icons.location_on, color: AppColors.primary, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'GPS Radar Discovery (${loc.radiusKm.toStringAsFixed(0)} km)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.listings.length} surplus meals detected near ${loc.localityLabel}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ListingPreviewBottomSheet extends StatelessWidget {
  final FoodListing food;

  const _ListingPreviewBottomSheet({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header with veg icon and category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: food.isVegetarian ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 10,
                      color: food.isVegetarian ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    food.foodName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  food.category,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // PG Name & Distance
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                food.propertyName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  '📍 ${food.formattedDistance}',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            food.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Price and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹${food.sellingPrice.toInt()}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${food.originalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${food.availablePortions} portions left • Pay at pickup',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View & Reserve'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/customer/food/${food.id}');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
