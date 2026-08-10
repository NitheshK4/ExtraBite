import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reservation.dart';
import '../../providers/food_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/user_provider.dart';
import 'add_listing_screen.dart';
import 'qr_scanner_screen.dart';

class PgDashboardScreen extends ConsumerWidget {
  const PgDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodState = ref.watch(foodProvider);
    final userState = ref.watch(userProvider);
    final reservations = ref.watch(reservationProvider);

    final pgListings = foodState.allListings
        .where((listing) => listing.pgName == userState.pgName)
        .toList();

    final completedPickups =
        reservations.where((res) => res.status == ReservationStatus.pickedUp).length;
    final totalEarnings = reservations
        .where((res) => res.status == ReservationStatus.pickedUp)
        .fold<double>(0.0, (sum, res) => sum + res.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: Text('${userState.pgName} Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFE8F5E9),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Active Listings',
                          '${pgListings.length}',
                          Icons.restaurant_menu,
                          Colors.green[800]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Pickups Completed',
                          '$completedPickups',
                          Icons.verified_user,
                          Colors.blue[800]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Total Collected at Pickup',
                    '₹${totalEarnings.toStringAsFixed(0)}',
                    Icons.payments,
                    Colors.orange[800]!,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),

            // Quick Actions Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddListingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Post Surplus Meal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QrScannerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Listings Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Your Listed Extra Food',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            if (pgListings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.fastfood_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No extra meals posted yet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Post Surplus Meal" to list leftover mess food.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pgListings.length,
                itemBuilder: (context, index) {
                  final food = pgListings[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          food.isVeg ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        food.isVeg ? Icons.eco : Icons.restaurant,
                        color: food.isVeg ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(food.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${food.availablePortions} portions left • ₹${food.pickupPrice.toStringAsFixed(0)} at pickup'),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color,
      {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isFullWidth ? 28 : 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isFullWidth ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
