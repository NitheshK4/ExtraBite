import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/food_provider.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final foodState = ref.watch(foodProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ownerListings = foodState.listings.where(
      (listing) => listing.propertyName.toLowerCase() == (user.propertyName ?? '').toLowerCase(),
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(user.propertyName ?? 'Owner Dashboard'),
        actions: [
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
            // Owner Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.propertyName ?? 'PG / Hostel Manager',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
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
            ),
            const SizedBox(height: 20),

            // Metrics Summary
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Listings',
                    value: '${ownerListings.length}',
                    icon: Icons.fastfood_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pending Pickups',
                    value: '2',
                    icon: Icons.qr_code_scanner,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Listing Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Food Listings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add surplus listing flow ready.')),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Meal'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (ownerListings.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textLight),
                        const SizedBox(height: 8),
                        const Text(
                          'No surplus meals listed yet.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Click "Add Meal" above to post leftover meals for students.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ownerListings.length,
                itemBuilder: (context, index) {
                  final item = ownerListings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Portions: ${item.availablePortions} • ₹${item.sellingPrice.toInt()}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.verificationStatus,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),

            // Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out Owner Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out? All cached owner session data will be cleared.'),
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
