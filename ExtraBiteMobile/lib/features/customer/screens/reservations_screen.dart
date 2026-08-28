import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/reservation.dart';
import '../../../providers/reservation_provider.dart';
import '../../../providers/auth_provider.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(reservationProvider.notifier).loadCustomerReservations(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeList = ref.watch(activeReservationsProvider);
    final pastList = ref.watch(pastReservationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'My Food Reservations',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'ACTIVE'),
              Tab(text: 'PAST HISTORY'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveTab(context, ref, activeList),
            _buildPastTab(context, pastList),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, WidgetRef ref, List<Reservation> activeList) {
    if (activeList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No active reservations',
        description: 'Reserved surplus meals will appear here. Find delicious surplus food nearby to start saving!',
      );
    }

    final formatTime = DateFormat('hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeList.length,
      itemBuilder: (context, index) {
        final res = activeList[index];
        final windowStr = '${formatTime.format(res.pickupStarts)} - ${formatTime.format(res.pickupEnds)}';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row: Order ID + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${res.id}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'Reserved',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Food details
                Text(
                  res.foodName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  res.propertyName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                
                // Key metrics row: Qty + Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          '${res.quantity} portion(s)',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Amount to Collect', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${res.amountToCollect.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Pickup Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup Time Window',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              windowStr,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Digital Pass & QR CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      context.push('/customer/pass/${res.id}');
                    },
                    icon: const Icon(Icons.qr_code_2, size: 20),
                    label: Text(
                      'Show Digital Pass & QR',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Cancel Button Action
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _showCancelDialog(context, ref, res.id);
                    },
                    child: Text(
                      'Cancel Reservation',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPastTab(BuildContext context, List<Reservation> pastList) {
    if (pastList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No past reservations',
        description: 'Your completed or cancelled reservations will show up here.',
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pastList.length,
      itemBuilder: (context, index) {
        final res = pastList[index];
        final isCompleted = res.status == ReservationStatus.completed;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    res.foodName,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Text(
                  '₹${res.amountToCollect.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isCompleted ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(res.propertyName, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  dateFormat.format(res.reservedAt),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? AppColors.primaryLight 
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                isCompleted ? 'Completed' : 'Cancelled',
                style: GoogleFonts.inter(
                  color: isCompleted ? AppColors.primary : AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Reservation?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to cancel this reservation? Surplus portions are limited and others might need them.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              ref.read(reservationProvider.notifier).cancelReservation(id);
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
