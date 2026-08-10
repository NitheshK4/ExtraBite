import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final pgId = user?.pgId ?? 'pg_01';
    final summary = ref.watch(ownerAnalyticsProvider(pgId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan QR Pass',
            onPressed: () => context.push('/qr-scanner'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text('Scan QR Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/qr-scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Greeting
            Text(
              'Hello, ${user?.fullName ?? 'PG Host'} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Sri Sai Executive PG & Mess • Koramangala',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Pay At Pickup Model Reminder
            const PayAtPickupBadge(showDescription: true),

            const SizedBox(height: 20),

            // Quick Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildMetricCard(
                  title: 'Active Listings',
                  value: '${summary.activeListingsCount}',
                  subtitle: '${summary.availablePortionsCount} portions left',
                  icon: Icons.restaurant_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push('/owner-listings'),
                ),
                _buildMetricCard(
                  title: 'Pending Pickups',
                  value: '${summary.pendingReservationsCount}',
                  subtitle: 'Awaiting customer arrival',
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange.shade800,
                  onTap: () => context.push('/owner-queue'),
                ),
                _buildMetricCard(
                  title: 'Revenue Collected',
                  value: '₹${summary.estimatedRevenueCollected.round()}',
                  subtitle: 'Collected at pickup',
                  icon: Icons.payments_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.push('/owner-analytics'),
                ),
                _buildMetricCard(
                  title: 'Food Rescued',
                  value: '${summary.mealsRescuedCount}',
                  subtitle: '${summary.foodWasteAvoidedKg.toStringAsFixed(1)} kg waste saved',
                  icon: Icons.eco_rounded,
                  color: Colors.teal.shade700,
                  onTap: () => context.push('/owner-analytics'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Action Buttons
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Meal Listing'),
                    onPressed: () => context.push('/create-listing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.dialpad_rounded),
                    label: const Text('Enter Code'),
                    onPressed: () => context.push('/manual-code-verify'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Low Stock & Expiry Alerts
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dinner Pickup Closes in 1h 45m',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You have 5 portions remaining for South Indian Thali. Keep your QR scanner ready for arriving students.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
