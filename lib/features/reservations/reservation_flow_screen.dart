import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';
import '../../shared/widgets/custom_button.dart';

class ReservationFlowScreen extends ConsumerStatefulWidget {
  final String listingId;
  final int initialQuantity;

  const ReservationFlowScreen({
    super.key,
    required this.listingId,
    this.initialQuantity = 1,
  });

  @override
  ConsumerState<ReservationFlowScreen> createState() => _ReservationFlowScreenState();
}

class _ReservationFlowScreenState extends ConsumerState<ReservationFlowScreen> {
  late int _quantity;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final listing = ref.watch(listingProvider.notifier).getListingById(widget.listingId);
    final currentUser = ref.watch(authProvider).currentUser;

    if (listing == null || currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservation Error')),
        body: const Center(child: Text('Listing or session is invalid.')),
      );
    }

    final totalPayable = listing.discountedPrice * _quantity;
    final totalSavings = (listing.originalPrice - listing.discountedPrice) * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Reservation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.pgName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Quantity Selector in Review
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Portions',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            color: AppColors.primary,
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: _quantity < listing.availablePortions
                                ? () => setState(() => _quantity++)
                                : null,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pickup Window Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Pickup Schedule',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateTimeUtils.formatPickupWindow(listing.pickupStartTime, listing.pickupEndTime),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${listing.address}, ${listing.neighborhood}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancellation cutoff: Up to ${AppConstants.cancelCutoffMinutes} minutes before window closes.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Model Card (Invariant: Strictly Pay at Pickup)
            const PayAtPickupBadge(showDescription: true),

            const SizedBox(height: 20),

            // Bill Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Portion Price (₹${listing.discountedPrice.round()} x $_quantity)',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text('₹${totalPayable.round()}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Fee',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const Text(
                        'FREE (₹0)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount to Pay at Pickup',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${totalPayable.round()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You save ₹${totalSavings.round()} on this meal!',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            CustomButton(
              label: 'Confirm Reservation — Pay at pickup',
              isLoading: _isSubmitting,
              onPressed: () async {
                setState(() => _isSubmitting = true);

                final reservation = ref.read(reservationProvider.notifier).createReservation(
                      listing: listing,
                      customer: currentUser,
                      portionsCount: _quantity,
                    );

                setState(() => _isSubmitting = false);

                if (reservation != null) {
                  context.go('/reservation-success/${reservation.id}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not place reservation. Remaining portions may have changed.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
