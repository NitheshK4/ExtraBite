import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Command'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch Demo Role',
            onPressed: () {
              ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
              context.go('/discover');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Marketplace Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Live monitoring of PGs, listings, and pickups',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Top Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildStatCard('Active Listings', '${summary.activeListings}', Icons.restaurant_rounded, AppColors.primary),
                _buildStatCard('Total Reservations', '${summary.totalReservations}', Icons.receipt_long_rounded, Colors.indigo),
                _buildStatCard('Total Meals Rescued', '${summary.totalMealsRescued}', Icons.eco_rounded, AppColors.secondary),
                _buildStatCard('Pending Reports', '${summary.pendingReportsCount}', Icons.report_problem_rounded, Colors.red),
              ],
            ),

            const SizedBox(height: 24),

            // Operational Queues Navigation Cards
            const Text(
              'Operational Queues',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.how_to_reg_rounded, color: AppColors.primary),
                ),
                title: const Text('Pending PG Approvals', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('1 PG application awaiting FSSAI document review'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push('/admin-approvals'),
              ),
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.checklist_rounded, color: AppColors.secondary),
                ),
                title: const Text('Listing Moderation', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Manage & feature active surplus food listings'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push('/admin-moderation'),
              ),
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.report_gmailerrorred_rounded, color: Colors.red),
                ),
                title: const Text('User Reports & Evidence', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${summary.pendingReportsCount} unresolved customer inquiries'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push('/admin-reports'),
              ),
            ),

            const SizedBox(height: 24),

            // Demo Role Quick-Switch
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Switch View', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Switch back to Customer or PG Owner', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
                      context.go('/discover');
                    },
                    child: const Text('Customer App'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
