import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/food_listing.dart';
import '../../../models/reservation.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/food_provider.dart';
import '../../../providers/reservation_provider.dart';
import '../../common/widgets/metric_stat_card.dart';
import '../widgets/pickup_verification_modal.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(foodProvider.notifier).loadListings();
        ref.read(reservationProvider.notifier).loadOwnerReservations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final foodState = ref.watch(foodProvider);
    final allReservations = ref.watch(reservationProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final ownerPropName = (user.propertyName ?? user.name).toLowerCase();
    final ownerListings = foodState.listings.where(
      (listing) => listing.propertyName.toLowerCase() == ownerPropName || listing.propertyId == user.id,
    ).toList();

    final ownerReservations = allReservations.where(
      (r) => r.propertyName.toLowerCase() == ownerPropName || ownerListings.any((l) => l.id == r.foodListingId),
    ).toList();

    final pendingPickups = ownerReservations.where(
      (r) => r.status == ReservationStatus.reserved,
    ).length;

    final completedPickups = ownerReservations.where(
      (r) => r.status == ReservationStatus.completed,
    ).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 10.0, bottom: 10.0),
          child: Image.asset(
            'assets/branding/extrabite_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.storefront,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
        ),
        title: Text(
          user.propertyName ?? 'Owner Dashboard',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            tooltip: 'Scan Student QR',
            onPressed: () => PickupVerificationModal.show(context, user.propertyName ?? user.name),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner Profile Card
            Container(
              padding: const EdgeInsets.all(16.0),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.initials,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                'Verified Host',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.propertyName ?? 'PG / Hostel Manager',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: GoogleFonts.inter(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Metrics Summary Grid (4 Operational KPIs)
            Row(
              children: [
                Expanded(
                  child: MetricStatCard(
                    title: 'Active Meals',
                    value: '${ownerListings.length}',
                    icon: Icons.restaurant_menu_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricStatCard(
                    title: 'Portions Left',
                    value: '${ownerListings.fold<int>(0, (sum, item) => sum + item.availablePortions)}',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricStatCard(
                    title: 'Incoming Orders',
                    value: '$pendingPickups',
                    icon: Icons.notifications_active_outlined,
                    color: AppColors.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricStatCard(
                    title: 'Pickups Done',
                    value: '$completedPickups',
                    icon: Icons.task_alt_outlined,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Listing Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Food Listings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _navigateToAddMeal(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Add Meal',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (ownerListings.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No surplus meals listed yet.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Click "+ Add Meal" above to post fresh surplus food for nearby students and residents.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToAddMeal(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add First Meal'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Column(
                children: ownerListings.map((item) => _buildListingCard(context, item)).toList(),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              'Incoming Reservations',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (ownerReservations.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No reservations received yet.',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Column(
                children: ownerReservations.map((res) => _buildReservationCard(context, res)).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.outline),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  'Log Out Owner Session',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, FoodListing item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: item.isVegetarian ? AppColors.dietaryVeg : AppColors.dietaryNonVeg,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: item.isVegetarian ? AppColors.dietaryVeg : AppColors.dietaryNonVeg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.foodName,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  item.category,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.locationAddress} (${item.distanceKm.toStringAsFixed(1)} km)',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '₹${item.sellingPrice.toInt()}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹${item.originalPrice.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textLight,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.primary),
                    tooltip: 'Decrease portion',
                    onPressed: item.availablePortions > 0
                        ? () {
                            ref.read(foodProvider.notifier).decrementPortions(item.id, 1);
                          }
                        : null,
                  ),
                  Text(
                    '${item.availablePortions} left',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                    tooltip: 'Increase portion',
                    onPressed: () {
                      ref.read(foodProvider.notifier).decrementPortions(item.id, -1);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    tooltip: 'Delete listing',
                    onPressed: () {
                      ref.read(foodProvider.notifier).removeListing(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed "${item.foodName}".')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation res) {
    final statusColor = res.status == ReservationStatus.completed
        ? AppColors.primary
        : res.status == ReservationStatus.cancelled
            ? AppColors.error
            : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${res.id}',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, color: AppColors.textLight, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  res.status.name.toUpperCase(),
                  style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            res.foodName,
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Portions: ${res.quantity} | Amount: ₹${res.amountToCollect.toStringAsFixed(0)}',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (res.status == ReservationStatus.reserved) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      ref.read(reservationProvider.notifier).updateStatus(res.id, 'ready_for_pickup');
                    },
                    child: Text('Mark Ready', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      ref.read(reservationProvider.notifier).updateStatus(res.id, 'picked_up');
                    },
                    child: Text('Complete', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.outline),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  onPressed: () {
                    ref.read(reservationProvider.notifier).updateStatus(res.id, 'rejected');
                  },
                  child: Text('Reject', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToAddMeal(BuildContext context) {
    context.push('/owner/add-meal');
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to log out? All cached owner session data will be cleared.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
