import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/food_provider.dart';
import '../widgets/food_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  final List<String> _recentSearches = [
    'Biryani',
    'Veg Meals',
    'Sri Sai PG',
    'Breakfast'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate controller from existing state if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(foodProvider).searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(foodProvider.notifier).updateSearchQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(foodProvider.notifier).updateSearchQuery('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final foodState = ref.watch(foodProvider);
    final filteredFood = ref.watch(filteredFoodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Marketplace'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Container
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: foodState.searchQuery.isEmpty,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search meals, PGs or messes...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: _clearSearch,
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Recent Searches or Search results
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildRecentSearches()
                  : filteredFood.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredFood.length,
                          itemBuilder: (context, index) {
                            final food = filteredFood[index];
                            return FoodCard(
                              food: food,
                              onTap: () => context.push('/customer/food/${food.id}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((term) {
              return ActionChip(
                label: Text(term),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
                onPressed: () {
                  _searchController.text = term;
                  _onSearchChanged(term);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/branding/extrabite_logo.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No meals found nearby.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any active surplus food listings matching your query.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
