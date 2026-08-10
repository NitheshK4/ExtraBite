import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/listing_repository.dart';
import '../listings/widgets/listing_card.dart';
import '../../shared/widgets/empty_state_view.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(listingProvider.notifier).getFavoriteListings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Meals & PGs'),
      ),
      body: favorites.isEmpty
          ? EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'No saved favorites yet',
              subtitle: 'Tap the heart icon on any meal listing to save it for quick re-ordering.',
              actionLabel: 'Discover Meals',
              onAction: () => context.go('/discover'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return ListingCard(
                  listing: item,
                  onTap: () => context.push('/listing/${item.id}'),
                );
              },
            ),
    );
  }
}
