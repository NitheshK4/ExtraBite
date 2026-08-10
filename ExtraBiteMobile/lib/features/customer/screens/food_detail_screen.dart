import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/food_provider.dart';
import '../../../providers/reservation_provider.dart';
import '../../../models/food_listing.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final String foodId;

  const FoodDetailScreen({
    super.key,
    required this.foodId,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _portionsToReserve = 1;

  @override
  Widget build(BuildContext context) {
    final food = ref.watch(foodDetailProvider(widget.foodId));
    
    if (food == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Surplus food listing not found.')),
      );
    }

    final formatTime = DateFormat('hh:mm a');
    final pickupWindowStr = '${formatTime.format(food.pickupStarts)} - ${formatTime.format(food.pickupEnds)}';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(food.foodName),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image/Icon Banner Area
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Icon(
                        food.isVegetarian ? Icons.eco : Icons.kebab_dining,
                        size: 80,
                        color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Food Title + Veg tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.foodName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                          ),
                        ),
                        child: Text(
                          food.isVegetarian ? 'VEG' : 'NON-VEG',
                          style: TextStyle(
                            color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Property Details
                  Row(
                    children: [
                      const Icon(Icons.business, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        food.propertyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Distance & Preparation info
                  Row(
                    children: [
                      const Icon(Icons.navigation, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${food.distanceKm.toStringAsFixed(1)} km away'),
                      const SizedBox(width: 16),
                      const Icon(Icons.restaurant, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Prepared ${DateFormat('hh:mm a').format(food.preparedTime)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    food.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Ingredients & Allergens
                  if (food.ingredients.isNotEmpty) ...[
                    const Text(
                      'Ingredients',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: food.ingredients.map((ing) => Chip(
                        label: Text(ing),
                        backgroundColor: Colors.grey.shade50,
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (food.allergens.isNotEmpty) ...[
                    const Text(
                      'Allergen Warnings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: food.allergens.map((all) => Chip(
                        label: Text(all, style: const TextStyle(color: AppColors.error)),
                        backgroundColor: AppColors.error.withOpacity(0.05),
                        side: const BorderSide(color: AppColors.error, width: 0.5),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Pickup Window banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Surplus Food Pickup Window',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pickupWindowStr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Reservation Panel
          _buildReservationPanel(context, food),
        ],
      ),
    );
  }

  Widget _buildReservationPanel(BuildContext context, FoodListing food) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quantity selection row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Portions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _portionsToReserve > 1 
                        ? () => setState(() => _portionsToReserve--) 
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_portionsToReserve',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _portionsToReserve < food.availablePortions 
                        ? () => setState(() => _portionsToReserve++) 
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Price + CTA Row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Price', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '₹${(food.sellingPrice * _portionsToReserve).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: food.isExpired
                      ? null
                      : () {
                          _triggerReservation(context, food);
                        },
                  child: Text(food.isExpired ? 'Pickup Expired' : 'Reserve Meal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _triggerReservation(BuildContext context, FoodListing food) {
    // Call state notifier to add reservation mock state
    final reservation = ref.read(reservationProvider.notifier).createReservation(
      listing: food,
      quantity: _portionsToReserve,
    );

    // Show Confirmation modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Reservation Confirmed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your surplus food has been successfully reserved! Present this confirmation at the property to complete your purchase.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDialogRow('Order Reference', '#${reservation.id}'),
            _buildDialogRow('Reserved Item', reservation.foodName),
            _buildDialogRow('Quantity', '${reservation.quantity} portion(s)'),
            _buildDialogRow('Amount to Collect', '₹${reservation.amountToCollect.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    '💳 Pay at Pickup (Cash / UPI)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/customer/reservations'); // Navigate to active list
            },
            child: const Text('View Active Reservations'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
