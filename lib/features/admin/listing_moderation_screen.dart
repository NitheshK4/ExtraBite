import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/listing_repository.dart';
import '../../models/food_listing_model.dart';
import '../../shared/widgets/status_badge.dart';

class ListingModerationScreen extends ConsumerWidget {
  const ListingModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(listingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Moderation'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final item = listings[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      StatusBadge.fromListingStatus(item.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${item.pgName} • ${item.neighborhood}'),
                  Text('Price: ₹${item.discountedPrice.round()} (Portions: ${item.availablePortions}/${item.totalPortions})'),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          item.isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber.shade800,
                        ),
                        label: Text(item.isFeatured ? 'Featured' : 'Feature Deal'),
                        onPressed: () {
                          ref.read(listingProvider.notifier).toggleFeatureListing(item.id);
                        },
                      ),
                      if (item.status != ListingStatus.removed)
                        TextButton.icon(
                          icon: const Icon(Icons.block_rounded, size: 16, color: Colors.red),
                          label: const Text('Remove', style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            ref.read(listingProvider.notifier).removeListing(item.id);
                          },
                        ),
                    ],
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
