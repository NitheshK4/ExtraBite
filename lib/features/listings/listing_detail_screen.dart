import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/listing_repository.dart';
import '../../services/location_service.dart';
import '../../shared/widgets/dietary_chip.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';
import '../../shared/widgets/portion_selector.dart';
import '../../shared/widgets/custom_button.dart';
import '../reports/report_issue_dialog.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _selectedPortions = 1;

  @override
  Widget build(BuildContext context) {
    final listing = ref.watch(listingProvider.notifier).getListingById(widget.listingId);
    final locationNotifier = ref.read(locationProvider.notifier);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meal Not Found')),
        body: const Center(child: Text('This listing is no longer available.')),
      );
    }

    final distanceLabel = locationNotifier.formattedDistanceToListing(listing);
    final isFav = ref.watch(listingProvider.notifier).isFavorite(listing.id);
    final totalPayable = listing.discountedPrice * _selectedPortions;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar with Back and Favorite buttons
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'listing_img_${listing.id}',
                child: CachedNetworkImage(
                  imageUrl: listing.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.orange.shade50,
                    child: const Icon(Icons.restaurant_rounded, size: 64, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                radius: 20,
                child: IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red : Colors.black87,
                  ),
                  onPressed: () {
                    ref.read(listingProvider.notifier).toggleFavorite(listing.id);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.85),
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.flag_outlined, color: Colors.black87),
                  tooltip: 'Report Issue',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ReportIssueDialog(
                        listingId: listing.id,
                        listingTitle: listing.title,
                        pgId: listing.pgId,
                        pgName: listing.pgName,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PG Name & Location Pin
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          listing.pgName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 12, color: Colors.black87),
                            const SizedBox(width: 4),
                            Text(
                              distanceLabel,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title & Category
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Dietary and Allergen Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DietaryChip(dietaryType: listing.dietaryType),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          listing.category,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                        ),
                      ),
                      ...listing.allergens.map(
                        (a) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'Allergen: $a',
                            style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Price Breakdown & Savings
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ExtraBite Price (Per portion)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${listing.discountedPrice.round()}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${listing.originalPrice.round()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${listing.savingsPercentage}% SAVINGS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              'Save ₹${(listing.originalPrice - listing.discountedPrice).round()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Strict Pay at Pickup Banner
                  const PayAtPickupBadge(showDescription: true),

                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'About This Meal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pickup Window & Instructions Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Pickup Window',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              DateTimeUtils.getRemainingTimeLabel(listing.pickupEndTime),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateTimeUtils.formatPickupWindow(listing.pickupStartTime, listing.pickupEndTime),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Colors.black87),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                listing.pickupInstructions.isNotEmpty
                                    ? listing.pickupInstructions
                                    : 'Collect directly at PG dining counter. Show your QR pickup pass.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Address & Map Preview Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup Location',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '${listing.address}, ${listing.neighborhood}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('Map'),
                          onPressed: () => context.push('/map'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Food Safety & Hygiene Note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ExtraBite Food Safety Standard: All meals are prepared fresh in commercial PG kitchens and must be consumed within 3 hours of collection.',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Spacing for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Bar with Portion Selector and Reserve Action
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Portion Selector
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quantity', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  PortionSelector(
                    count: _selectedPortions,
                    maxCount: listing.availablePortions > 0 ? listing.availablePortions : 1,
                    onChanged: (val) {
                      setState(() => _selectedPortions = val);
                    },
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Reserve Button
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomButton(
                      label: listing.isSoldOut
                          ? 'Sold Out'
                          : 'Reserve — Pay ₹${totalPayable.round()} at pickup',
                      onPressed: listing.isSoldOut
                          ? null
                          : () {
                              context.push(
                                '/reserve/${listing.id}?qty=$_selectedPortions',
                              );
                            },
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'No prepayment • Pay upon collection',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
