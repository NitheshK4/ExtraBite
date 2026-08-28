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

          // Sticky Bottom Reservation Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyReservationBar(context, food),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(FoodListing food) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight,
                  AppColors.secondaryLight.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                ? Image.network(
                    food.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildHeroPlaceholder(food.isVegetarian),
                  )
                : _buildHeroPlaceholder(food.isVegetarian),
          ),
        ),

        // Gradient top overlay for button contrast
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Floating App Bar actions
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassmorphicButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
              Row(
                children: [
                  _buildGlassmorphicButton(
                    icon: Icons.share_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meal link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphicButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _buildHeroPlaceholder(bool isVeg) {
    return Center(
      child: Icon(
        isVeg ? Icons.eco : Icons.kebab_dining,
        size: 80,
        color: isVeg ? AppColors.vegColor.withOpacity(0.6) : AppColors.nonVegColor.withOpacity(0.6),
      ),
    );
  }

  Widget _buildDietaryTag(bool isVeg) {
    final color = isVeg ? AppColors.vegColor : AppColors.nonVegColor;
    final bg = isVeg ? AppColors.vegBg : AppColors.nonVegBg;
    final label = isVeg ? 'Vegetarian' : 'Non-Vegetarian';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(FoodListing food, double savingsPerPortion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${food.sellingPrice.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
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
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (food.discountPercentage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${food.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          if (savingsPerPortion > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.secondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'You save ₹${savingsPerPortion.toStringAsFixed(0)} per portion',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgencyCard(FoodListing food, String pickupWindowStr, int remainingMinutes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Pickup Window',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  remainingMinutes > 0 ? '${remainingMinutes}m left' : 'Ending',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pickupWindowStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${food.availablePortions} portions remaining in kitchen inventory',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
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
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.storefront, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.propertyName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.verified, color: AppColors.tertiary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${food.distanceKm.toStringAsFixed(1)} km from your location',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
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
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  food.locationAddress,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyReservationBar(BuildContext context, FoodListing food) {
    final available = food.availablePortions;
    final isSoldOut = available <= 0;
    final isExpired = food.isExpired;

    int displayPortions = _portionsToReserve;
    if (isSoldOut) {
      displayPortions = 0;
    } else if (displayPortions > available) {
      displayPortions = available;
    }

    final totalPrice = food.sellingPrice * displayPortions;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.outline, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity Selection Stepper Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: !isSoldOut && !isExpired && _portionsToReserve > 1
                            ? () => setState(() => _portionsToReserve--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '$displayPortions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: !isSoldOut && !isExpired && _portionsToReserve < available
                            ? () => setState(() => _portionsToReserve++)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Primary Reserve Button (52px high)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isExpired || isSoldOut || _isLoading
                    ? null
                    : () => _triggerReservation(food),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isExpired
                                ? 'Pickup Expired'
                                : (isSoldOut
                                    ? 'Sold Out'
                                    : 'Reserve $displayPortions Portion(s) • ₹${totalPrice.toStringAsFixed(0)}'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Pay at Pickup (Cash / UPI)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerReservation(FoodListing food) async {
    final available = food.availablePortions;
    if (available <= 0) return;

    int portions = _portionsToReserve;
    if (portions > available) {
      portions = available;
    }
    if (portions <= 0) return;

    setState(() => _isLoading = true);

    try {
      final reservation = await ref.read(reservationProvider.notifier).createReservation(
        listing: food,
        quantity: portions,
      );

      ref.read(foodProvider.notifier).decrementPortions(food.id, portions);

      if (!mounted) return;

      // Show Confirmation Modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Reservation Confirmed',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
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
                Navigator.pop(context);
                context.go('/customer/reservations');
              },
              child: const Text('All Reservations'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                context.push('/customer/pass/${reservation.id}');
              },
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: const Text('View Digital Pass & QR'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
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
