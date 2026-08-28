import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/admin_food_listing.dart';
import '../../../providers/admin_provider.dart';

class FoodListingsTab extends ConsumerStatefulWidget {
  const FoodListingsTab({super.key});

  @override
  ConsumerState<FoodListingsTab> createState() => _FoodListingsTabState();
}

class _FoodListingsTabState extends ConsumerState<FoodListingsTab> {
  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadFoodListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showListingDetailModal(AdminFoodListing listing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                listing.title,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.imageUrl != null && listing.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        listing.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      ),
                    ),
                  )
                else
                  _buildPlaceholder(),
                const SizedBox(height: 16),
                _buildDetailRow('Listing ID', listing.id, isMonospace: true),
                _buildDetailRow('PG Mess Facility', listing.pgName),
                _buildDetailRow('Host / Owner', listing.ownerName),
                _buildDetailRow('Category', listing.category),
                _buildDetailRow('Dietary Type', listing.dietaryType.toUpperCase()),
                _buildDetailRow(
                  'Pricing',
                  '₹${listing.discountedPrice.toStringAsFixed(0)} (Original: ₹${listing.originalPrice.toStringAsFixed(0)})',
                ),
                _buildDetailRow('Portions', '${listing.availablePortions} available / ${listing.totalPortions} total'),
                _buildDetailRow(
                  'Pickup Window',
                  '${DateFormat('hh:mm a').format(listing.pickupStartTime)} - ${DateFormat('hh:mm a').format(listing.pickupEndTime)}',
                ),
                if (listing.description != null && listing.description!.isNotEmpty)
                  _buildDetailRow('Description', listing.description!),
                _buildDetailRow(
                  'Current Status',
                  listing.status.toUpperCase(),
                  statusColor: listing.status == 'active' ? AppColors.primary : AppColors.error,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.restaurant, size: 40, color: AppColors.onSurfaceVariant),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMonospace
                  ? GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor ?? AppColors.onSurface,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor ?? AppColors.onSurface,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleListingStatus(AdminFoodListing listing) async {
    final willRemove = listing.status != 'removed';
    final newStatus = willRemove ? 'removed' : 'active';
    final actionText = willRemove ? 'Remove from Marketplace' : 'Restore Listing';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionText?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to change status of "${listing.title}" to "$newStatus"?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willRemove ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(willRemove ? 'Remove' : 'Restore'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(adminProvider.notifier).updateListingStatus(listing.id, newStatus);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing "${listing.title}" status updated to $newStatus.'),
            backgroundColor: willRemove ? AppColors.error : AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final allListings = adminState.foodListings;

    // Filter
    final filteredListings = allListings.where((f) {
      if (_selectedStatusFilter == 'ACTIVE' && f.status != 'active') return false;
      if (_selectedStatusFilter == 'SOLD_OUT' && f.status != 'sold_out') return false;
      if (_selectedStatusFilter == 'EXPIRED' && f.status != 'expired') return false;
      if (_selectedStatusFilter == 'REMOVED' && f.status != 'removed') return false;

      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.toLowerCase().trim();
        final title = f.title.toLowerCase();
        final pg = f.pgName.toLowerCase();
        final owner = f.ownerName.toLowerCase();
        final cat = f.category.toLowerCase();
        return title.contains(q) || pg.contains(q) || owner.contains(q) || cat.contains(q);
      }
      return true;
    }).toList();

    final totalCount = allListings.length;
    final activeCount = allListings.where((f) => f.status == 'active').length;
    final soldOutCount = allListings.where((f) => f.status == 'sold_out').length;
    final removedCount = allListings.where((f) => f.status == 'removed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header & KPIs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Food Listings Operations',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time surplus food listings, pricing moderation, and inventory management.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => ref.read(adminProvider.notifier).loadFoodListings(),
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Refresh Listings',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Stats Row
              Row(
                children: [
                  _buildStatPill('Total Meals', '$totalCount', AppColors.primary),
                  const SizedBox(width: 12),
                  _buildStatPill('Active Listings', '$activeCount', AppColors.success),
                  const SizedBox(width: 12),
                  _buildStatPill('Sold Out', '$soldOutCount', AppColors.secondary),
                  const SizedBox(width: 12),
                  _buildStatPill('Removed', '$removedCount', AppColors.error),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Filter & Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by meal title, PG name, category, or host...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterButton('ALL', 'All Meals'),
                        _buildFilterButton('ACTIVE', 'Active'),
                        _buildFilterButton('SOLD_OUT', 'Sold Out'),
                        _buildFilterButton('EXPIRED', 'Expired'),
                        _buildFilterButton('REMOVED', 'Removed'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Listings Data Table
              if (adminState.isLoading && allListings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filteredListings.isEmpty)
                _buildEmptyState()
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.surfaceContainerHigh),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        horizontalMargin: 20,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('MEAL & CATEGORY')),
                          DataColumn(label: Text('PG HOST / FACILITY')),
                          DataColumn(label: Text('DIET')),
                          DataColumn(label: Text('PRICE')),
                          DataColumn(label: Text('PORTIONS')),
                          DataColumn(label: Text('PICKUP TIME')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filteredListings.map((listing) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppColors.primaryContainer,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                listing.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 20, color: AppColors.primary),
                                              )
                                            : const Icon(Icons.restaurant, size: 20, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          listing.title,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          listing.category,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      listing.pgName,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      listing.ownerName,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(_buildDietaryBadge(listing.dietaryType)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₹${listing.discountedPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      '₹${listing.originalPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${listing.availablePortions} / ${listing.totalPortions}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: listing.availablePortions > 0 ? AppColors.onSurface : AppColors.error,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${DateFormat('hh:mm a').format(listing.pickupStartTime)} - ${DateFormat('hh:mm a').format(listing.pickupEndTime)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              DataCell(_buildStatusBadge(listing.status)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                                      tooltip: 'View Meal Details',
                                      onPressed: () => _showListingDetailModal(listing),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        listing.status == 'removed' ? Icons.restore : Icons.delete_outline,
                                        size: 18,
                                        color: listing.status == 'removed' ? AppColors.primary : AppColors.error,
                                      ),
                                      tooltip: listing.status == 'removed' ? 'Restore Listing' : 'Remove Listing',
                                      onPressed: () => _toggleListingStatus(listing),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDietaryBadge(String dietaryType) {
    final isVeg = dietaryType.toLowerCase() == 'vegetarian' || dietaryType.toLowerCase() == 'vegan';
    final color = isVeg ? AppColors.primary : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isVeg ? 'VEG' : 'NON-VEG',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status.toLowerCase()) {
      'active' => AppColors.primary,
      'sold_out' => AppColors.secondary,
      'expired' => AppColors.onSurfaceVariant,
      'removed' => AppColors.error,
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.restaurant_outlined, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No food listings found matching current filter.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
