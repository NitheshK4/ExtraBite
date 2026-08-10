import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/food_listing_model.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../core/constants/app_colors.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late DietaryType? _selectedDietary;
  late double _maxPrice;
  late bool _onlyAvailableNow;
  late List<String> _excludedAllergens;
  late String _sortBy;

  final List<String> _availableAllergens = ['Dairy', 'Gluten', 'Nuts', 'Soy', 'Egg', 'Fish', 'Peanuts'];

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(listingFilterProvider);
    _selectedDietary = currentFilters.dietaryType;
    _maxPrice = currentFilters.maxPrice ?? 250.0;
    _onlyAvailableNow = currentFilters.onlyAvailableNow;
    _excludedAllergens = List.from(currentFilters.excludedAllergens);
    _sortBy = currentFilters.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDietary = null;
                        _maxPrice = 250.0;
                        _onlyAvailableNow = false;
                        _excludedAllergens.clear();
                        _sortBy = 'nearest';
                      });
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Sort By
              const Text(
                'Sort By',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSortChip('Nearest First', 'nearest'),
                  _buildSortChip('Lowest Price', 'lowestPrice'),
                  _buildSortChip('Earliest Pickup', 'earliestPickup'),
                  _buildSortChip('Highest Rated', 'highestRated'),
                  _buildSortChip('Newest Added', 'newest'),
                ],
              ),

              const SizedBox(height: 16),

              // Dietary Preference
              const Text(
                'Dietary Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Types'),
                    selected: _selectedDietary == null,
                    onSelected: (selected) {
                      setState(() => _selectedDietary = null);
                    },
                  ),
                  ...DietaryType.values.map(
                    (type) => ChoiceChip(
                      label: Text(type.displayName),
                      selected: _selectedDietary == type,
                      onSelected: (selected) {
                        setState(() => _selectedDietary = selected ? type : null);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Max Price Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Max Price (Pay at pickup)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${_maxPrice.round()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxPrice,
                min: 30.0,
                max: 300.0,
                divisions: 27,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _maxPrice = val);
                },
              ),

              const SizedBox(height: 12),

              // Availability Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Available right now only',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Exclude sold out and upcoming meals',
                  style: TextStyle(fontSize: 12),
                ),
                value: _onlyAvailableNow,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _onlyAvailableNow = val);
                },
              ),

              const SizedBox(height: 12),

              // Allergen Exclusions
              const Text(
                'Exclude Allergens',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAllergens.map((allergen) {
                  final isExcluded = _excludedAllergens.contains(allergen);
                  return FilterChip(
                    label: Text(allergen),
                    selected: isExcluded,
                    selectedColor: Colors.red.shade100,
                    checkmarkColor: Colors.red.shade800,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _excludedAllergens.add(allergen);
                        } else {
                          _excludedAllergens.remove(allergen);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Apply Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(listingFilterProvider.notifier).state = ref
                        .read(listingFilterProvider)
                        .copyWith(
                          dietaryType: _selectedDietary,
                          maxPrice: _maxPrice,
                          onlyAvailableNow: _onlyAvailableNow,
                          excludedAllergens: _excludedAllergens,
                          sortBy: _sortBy,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortBy = value);
        }
      },
    );
  }
}
