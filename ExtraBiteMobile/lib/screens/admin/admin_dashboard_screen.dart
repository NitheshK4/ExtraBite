import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reservation.dart';
import '../../providers/food_provider.dart';
import '../../providers/reservation_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodState = ref.watch(foodProvider);
    final reservations = ref.watch(reservationProvider);

    final totalPortionsRescued = reservations
        .where((res) => res.status == ReservationStatus.pickedUp)
        .fold<int>(0, (sum, res) => sum + res.portions);

    final foodSavedKg = (totalPortionsRescued * 0.45).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations Overview'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Analytics Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildMetricTile(
                  'Food Saved',
                  '$foodSavedKg kg',
                  Icons.eco,
                  Colors.green[800]!,
                ),
                _buildMetricTile(
                  'Meals Rescued',
                  '$totalPortionsRescued',
                  Icons.volunteer_activism,
                  Colors.blue[800]!,
                ),
                _buildMetricTile(
                  'Active Listings',
                  '${foodState.allListings.length}',
                  Icons.restaurant,
                  Colors.orange[800]!,
                ),
                _buildMetricTile(
                  'Verified PGs',
                  '18 PGs',
                  Icons.verified,
                  Colors.purple[800]!,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Registered PG Hostels List
            const Text(
              'Partnered PGs & Hostels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildPgAuditTile(
              'Sunrise Executive Boys PG',
              'Koramangala 5th Block',
              '12 listings posted • Verified',
              true,
            ),
            _buildPgAuditTile(
              'Sri Lakshmi Luxury Ladies Hostel',
              'Koramangala 6th Block',
              '8 listings posted • Verified',
              true,
            ),
            _buildPgAuditTile(
              'Greenwood Co-Living Hostel',
              'Sony World Signal',
              '15 listings posted • Verified',
              true,
            ),
            _buildPgAuditTile(
              'Starlight Student PG',
              'BTM 2nd Stage',
              'Pending Verification',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPgAuditTile(
      String name, String location, String statusStr, bool isVerified) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isVerified ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            isVerified ? Icons.check : Icons.hourglass_top,
            color: isVerified ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$location • $statusStr'),
        trailing: Chip(
          label: Text(
            isVerified ? 'VERIFIED' : 'PENDING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isVerified ? Colors.green[800] : Colors.orange[800],
            ),
          ),
          backgroundColor: isVerified ? Colors.green[50] : Colors.orange[50],
        ),
      ),
    );
  }
}
