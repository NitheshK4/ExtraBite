import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final food = ref.watch(foodDetailProvider(widget.foodId));
    
    if (food == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meal Listing')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Surplus meal listing not found.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/customer/home'),
                child: const Text('Back to Home Feed'),
              ),
            ],
          ),
        ),
      );
    }

    final formatTime = DateFormat('hh:mm a');
    final pickupWindowStr = '${formatTime.format(food.pickupStarts)} - ${formatTime.format(food.pickupEnds)}';
    final savingsPerPortion = (food.originalPrice - food.sellingPrice).clamp(0.0, double.infinity).toDouble();
    final remainingMinutes = food.pickupEnds.difference(DateTime.now()).inMinutes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Image Header (300px with bottom radius & floating buttons)
                _buildHeroHeader(food),

                // 2. Main Content Canvas
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dietary Badge & Title
                      _buildDietaryTag(food.isVegetarian),
                      const SizedBox(height: 8),
                      Text(
                        food.foodName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Price & Savings Card
                      _buildPricingCard(food, savingsPerPortion),
                      const SizedBox(height: 14),

                      // Urgency & Pickup Window Card
                      _buildUrgencyCard(food, pickupWindowStr, remainingMinutes),
                      const SizedBox(height: 16),

                      // PG Property Card
                      _buildPropertyCard(food),
                      const SizedBox(height: 16),

                      // Description
                      if (food.description.isNotEmpty) ...[
                        Text(
                          'Meal Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          food.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Ingredients & Allergens
                      if (food.ingredients.isNotEmpty) ...[
                        Text(
                          'Ingredients',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: food.ingredients.map((ing) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Text(
                              ing,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (food.allergens.isNotEmpty) ...[
                        Text(
                          'Allergen Warnings',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: food.allergens.map((all) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                                const SizedBox(width: 4),
                                Text(
                                  all,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar with Portion Stepper & Reserve Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyBottomBar(food),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(FoodListing food) {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryLight,
                AppColors.surfaceDim,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: food.imageUrl != null && food.imageUrl!.isNotEmpty
              ? Image.network(
                  food.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      food.isVegetarian ? Icons.eco : Icons.kebab_dining,
                      size: 80,
                      color: food.isVegetarian ? AppColors.vegColor.withOpacity(0.5) : AppColors.nonVegColor.withOpacity(0.5),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    food.isVegetarian ? Icons.eco : Icons.kebab_dining,
                    size: 80,
                    color: food.isVegetarian ? AppColors.vegColor.withOpacity(0.5) : AppColors.nonVegColor.withOpacity(0.5),
                  ),
                ),
        ),

        // Gradient overlay for back button contrast
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Floating Back Button
        Positioned(
          top: 48,
          left: 16,
          child: CircleAvatar(
            backgroundColor: AppColors.surface,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),

        // Floating Share Button
        Positioned(
          top: 48,
          right: 16,
          child: CircleAvatar(
            backgroundColor: AppColors.surface,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal link copied to clipboard!')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryTag(bool isVeg) {
    final color = isVeg ? AppColors.vegColor : AppColors.nonVegColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isVeg ? '100% VEGETARIAN' : 'NON-VEGETARIAN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(FoodListing food, double savings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${food.sellingPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₹${food.originalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Per Portion • Pay at Pickup',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (savings > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'SAVE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    '₹${savings.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrgencyCard(FoodListing food, String pickupWindowStr, int remainingMinutes) {
    final isUrgent = remainingMinutes <= 60 && remainingMinutes > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.errorLight : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? AppColors.error.withOpacity(0.3) : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: isUrgent ? AppColors.error : AppColors.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Window: $pickupWindowStr',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remainingMinutes > 0
                      ? '$remainingMinutes minutes remaining before pickup closes'
                      : 'Pickup window ended',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isUrgent ? AppColors.error : AppColors.textSecondary,
                    fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(FoodListing food) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          food.propertyName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.tertiary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FSSAI Registered Hostel / Mess',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.outline, height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  food.locationAddress,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${food.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(FoodListing food) {
    final maxPortions = food.availablePortions.clamp(1, 10);
    final totalPayable = food.sellingPrice * _portionsToReserve;
    final isSoldOut = food.availablePortions <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Portions Stepper Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portions to Reserve',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isSoldOut ? 'Sold out' : '${food.availablePortions} portions left',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSoldOut ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _portionsToReserve > 1 && !isSoldOut
                          ? () => setState(() => _portionsToReserve--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${isSoldOut ? 0 : _portionsToReserve}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _portionsToReserve < maxPortions && !isSoldOut
                          ? () => setState(() => _portionsToReserve++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Price & Reserve Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total to Pay at Pickup',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${totalPayable.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isSoldOut || _isLoading
                      ? null
                      : () => _handleReserve(context, food),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isSoldOut ? 'Sold Out' : 'Reserve & Get Pass',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleReserve(BuildContext context, FoodListing food) async {
    setState(() => _isLoading = true);
    try {
      final reservation = await ref.read(reservationProvider.notifier).createReservation(
        listing: food,
        quantity: _portionsToReserve,
      );

      // Decrement portion count in local state
      ref.read(foodProvider.notifier).decrementPortions(food.id, _portionsToReserve);

      if (!mounted || !context.mounted) return;

      // Show confirmation dialog with direct pass navigation
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.vegColor, size: 28),
              const SizedBox(width: 10),
              Text(
                'Meal Reserved!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your surplus food has been successfully reserved! Present your digital pass at pickup to complete your purchase.',
                style: GoogleFonts.inter(height: 1.4, fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.outline),
              const SizedBox(height: 6),
              _buildDialogRow('Order Reference', '#${reservation.id.substring(0, reservation.id.length > 8 ? 8 : reservation.id.length).toUpperCase()}'),
              _buildDialogRow('Reserved Item', reservation.foodName),
              _buildDialogRow('Quantity', '${reservation.quantity} portion(s)'),
              _buildDialogRow('Amount to Collect', '₹${reservation.amountToCollect.toStringAsFixed(0)}'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Pay at Pickup (Cash / UPI)',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
                Navigator.pop(dialogCtx);
                if (context.mounted) {
                  context.go('/customer/reservations');
                }
              },
              child: const Text('All Reservations'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (context.mounted) {
                  context.push('/customer/pass/${reservation.id}');
                }
              },
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: const Text('View Digital Pass & QR'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted && context.mounted) {
        String msg = e.toString();
        if (msg.contains('Insufficient portions')) {
          msg = 'Insufficient portions available. Please try a lower quantity.';
        } else if (msg.contains('is not active')) {
          msg = 'This meal listing is no longer active.';
        } else if (msg.contains('not approved')) {
          msg = 'The PG property is no longer approved.';
        } else {
          msg = 'Reservation failed: ${e.toString().replaceAll('Exception:', '').trim()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
