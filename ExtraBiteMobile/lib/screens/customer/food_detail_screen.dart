import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/food_listing.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/distance_badge.dart';
import '../../widgets/qr_code_dialog.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodListing food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _selectedPortions = 1;

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final userState = ref.watch(userProvider);
    final locationNotifier = ref.read(locationProvider.notifier);
    final distanceKm = locationNotifier.calculateDistance(
      food.latitude,
      food.longitude,
    );

    final totalPrice = food.pickupPrice * _selectedPortions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: food.imageUrl,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 240,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: DistanceBadge(distanceKm: distanceKm),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${food.availablePortions} portions left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Category Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: food.isVeg ? Colors.green[50] : Colors.red[50],
                          border: Border.all(
                              color: food.isVeg ? Colors.green : Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          food.isVeg ? 'VEG' : 'NON-VEG',
                          style: TextStyle(
                            color: food.isVeg ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // PG Host Info
                  Row(
                    children: [
                      const Icon(Icons.home_work, size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Text(
                        food.pgName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Special Pickup Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '₹${food.pickupPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${food.originalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Pay at Pickup',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'About this meal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    food.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Address Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                food.address,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Portion Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Portions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _selectedPortions > 1
                                ? () => setState(() => _selectedPortions--)
                                : null,
                          ),
                          Text(
                            '$_selectedPortions',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _selectedPortions < food.availablePortions
                                ? () => setState(() => _selectedPortions++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // STRICT REQUIREMENT NOTICE: Pay at Pickup only
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFE65100)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pay at Pickup Policy: No advance online payments. Pay the PG owner in cash or directly upon receiving your meal.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Create reservation
                        final reservation = ref
                            .read(reservationProvider.notifier)
                            .createReservation(
                              listing: food,
                              customerName: userState.userName,
                              customerPhone: userState.userPhone,
                              portions: _selectedPortions,
                            );

                        // Show confirmation dialog with QR code
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              QrCodeDialog(reservation: reservation),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'Reserve Meal • Pay ₹${totalPrice.toStringAsFixed(0)} at Pickup',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
