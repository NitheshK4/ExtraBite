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
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(foodProvider.notifier).loadListings();
              ref.read(reservationProvider.notifier).loadOwnerReservations();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            tooltip: 'Log Out',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddMeal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Post Surplus Food',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(foodProvider.notifier).loadListings();
          await ref.read(reservationProvider.notifier).loadOwnerReservations();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'O',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.propertyName ?? 'Mess / PG Partner',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
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

            // Quick Pickup Verification Action Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify Customer Pickup',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter 6-character token or scan QR code',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => PickupVerificationModal(
                          ownerPropertyName: user.propertyName ?? user.name,
                        ),
                      );
                    },
                    child: Text(
                      'Verify',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Listings Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Active Food Listings (${ownerListings.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _navigateToAddMeal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Meal'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (ownerListings.isEmpty) ...[
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.fastfood_outlined, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No surplus food listed today',
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

            // Recent Customer Reservations Section Header
            Text(
              'Recent Customer Reservations (${ownerReservations.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            if (ownerReservations.isEmpty) ...[
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Center(
                    child: Text(
                      'No customer reservations received yet.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Column(
                children: ownerReservations.map((res) => _buildReservationCard(context, ref, res)).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Footer / Logout
            Center(
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
                  color: item.status == 'active' ? AppColors.primaryLight : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: item.status == 'active' ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${item.sellingPrice.toStringAsFixed(0)} (Original ₹${item.originalPrice.toStringAsFixed(0)}) · ${item.availablePortions} portions left',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category: ${item.category}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                tooltip: 'Remove Listing',
                onPressed: () async {
                  await ref.read(foodProvider.notifier).removeListing(item.id);
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meal listing removed.')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, WidgetRef ref, Reservation res) {
    final isReserved = res.status == ReservationStatus.reserved;
    final isCompleted = res.status == ReservationStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${res.id}',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textLight),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primaryLight
                      : isReserved
                          ? AppColors.secondaryLight
                          : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  res.status.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isCompleted
                        ? AppColors.primary
                        : isReserved
                            ? AppColors.secondary
                            : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            res.foodName,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            '${res.quantity} portion(s) · ₹${res.amountToCollect.toStringAsFixed(0)} to collect',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (isReserved) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      ref.read(reservationProvider.notifier).updateStatus(res.id, 'picked_up');
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Collected'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error),
                  tooltip: 'Cancel Order',
                  onPressed: () {
                    ref.read(reservationProvider.notifier).cancelReservation(res.id);
                  },
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
