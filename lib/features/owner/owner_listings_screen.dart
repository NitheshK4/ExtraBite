import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/food_listing_model.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/status_badge.dart';

class OwnerListingsScreen extends ConsumerWidget {
  const OwnerListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final pgId = user?.pgId ?? 'pg_01';
    final listings = ref.watch(listingProvider.notifier).getListingsForPg(pgId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Food Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'New Listing',
            onPressed: () => context.push('/create-listing'),
          ),
        ],
      ),
      body: listings.isEmpty
          ? EmptyStateView(
              icon: Icons.restaurant_menu_rounded,
              title: 'No listings created yet',
              subtitle: 'Post your surplus meals before your lunch or dinner batch is ready.',
              actionLabel: 'Post Surplus Meal',
              onAction: () => context.push('/create-listing'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final item = listings[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            StatusBadge.fromListingStatus(item.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.category} • ₹${item.discountedPrice.round()} (Original ₹${item.originalPrice.round()})',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Portions: ${item.availablePortions} available / ${item.totalPortions} total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: item.availablePortions == 0 ? Colors.red : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pickup: ${DateTimeUtils.formatPickupWindow(item.pickupStartTime, item.pickupEndTime)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary),
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Action Buttons: Pause/Resume, Sold Out, Duplicate, Edit, Delete
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              TextButton.icon(
                                icon: Icon(
                                  item.status == ListingStatus.active
                                      ? Icons.pause_circle_outline_rounded
                                      : Icons.play_circle_outline_rounded,
                                  size: 16,
                                ),
                                label: Text(item.status == ListingStatus.active ? 'Pause' : 'Resume'),
                                onPressed: () {
                                  ref.read(listingProvider.notifier).toggleListingPause(item.id);
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.do_not_disturb_on_outlined, size: 16),
                                label: const Text('Sold Out'),
                                onPressed: item.availablePortions > 0
                                    ? () {
                                        ref.read(listingProvider.notifier).markSoldOut(item.id);
                                      }
                                    : null,
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Duplicate'),
                                onPressed: () {
                                  ref.read(listingProvider.notifier).duplicateListing(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Listing duplicated successfully.')),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                label: const Text('Remove', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  ref.read(listingProvider.notifier).removeListing(item.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
