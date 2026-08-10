import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/listing_repository.dart';
import '../../services/location_service.dart';
import '../listings/widgets/listing_card.dart';
import '../../shared/widgets/empty_state_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<String> _popularSearches = [
    'Thali',
    'Biryani',
    'Koramangala',
    'Indiranagar',
    'Dinner',
    'Pure Veg',
    'HSR Layout',
    'Breakfast',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allListings = ref.watch(listingProvider);
    final locationNotifier = ref.read(locationProvider.notifier);

    final searchResults = _query.isEmpty
        ? <dynamic>[]
        : allListings.where((l) {
            final q = _query.toLowerCase();
            return l.title.toLowerCase().contains(q) ||
                l.pgName.toLowerCase().contains(q) ||
                l.neighborhood.toLowerCase().contains(q) ||
                l.category.toLowerCase().contains(q) ||
                l.dietaryType.displayName.toLowerCase().contains(q);
          }).toList()
      ..sort((a, b) {
        final distA = locationNotifier.distanceToListing(a);
        final distB = locationNotifier.distanceToListing(b);
        return distA.compareTo(distB);
      });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search dish, PG name, or locality...',
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() => _query = val.trim());
          },
        ),
      ),
      body: _query.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Popular Searches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularSearches.map((term) {
                      return ActionChip(
                        label: Text(term),
                        avatar: const Icon(Icons.search_rounded, size: 16),
                        onPressed: () {
                          _searchController.text = term;
                          setState(() => _query = term);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recently Viewed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final recents = ref.watch(listingProvider.notifier).getRecentlyViewedListings();
                      if (recents.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No recently viewed listings yet.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      return Column(
                        children: recents.map((item) {
                          return ListingCard(
                            listing: item,
                            onTap: () => context.push('/listing/${item.id}'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            )
          : searchResults.isEmpty
              ? EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No matches found',
                  subtitle: 'Try searching for generic terms like "Thali", "PG", or "Dinner".',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final item = searchResults[index];
                    return ListingCard(
                      listing: item,
                      onTap: () {
                        ref.read(listingProvider.notifier).markAsViewed(item.id);
                        context.push('/listing/${item.id}');
                      },
                    );
                  },
                ),
    );
  }
}
