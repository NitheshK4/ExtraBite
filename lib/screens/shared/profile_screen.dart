import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_role.dart';
import '../../providers/user_provider.dart';
import '../../providers/location_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userState.userPhone,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          avatar: const Icon(Icons.badge,
                              size: 14, color: Colors.white),
                          label: Text(
                            userState.currentRole.displayName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Role Switcher Section
          const Text(
            'Switch Active Role',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: UserRole.values.map((role) {
                return RadioListTile<UserRole>(
                  title: Text(role.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_getRoleDescription(role)),
                  value: role,
                  groupValue: userState.currentRole,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (newRole) {
                    if (newRole != null) {
                      userNotifier.switchRole(newRole);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Location & Radius Settings
          const Text(
            'Location & Nearby Radius',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearby Search Radius',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${locationState.radiusKm.toStringAsFixed(1)} km (Default 2.0 km)',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: locationState.radiusKm,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    activeColor: const Color(0xFF2E7D32),
                    label: '${locationState.radiusKm.toStringAsFixed(1)} km',
                    onChanged: (val) {
                      locationNotifier.updateRadius(val);
                    },
                  ),
                  Text(
                    'Current GPS Location: ${locationState.currentArea}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Pay at Pickup Guarantee Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay-at-Pickup System',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No online checkout or hidden digital transaction fees. Pay directly to the PG owner when you verify your QR code.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Info Footer
          Center(
            child: Text(
              'ExtraBite Native Flutter App v1.0.0 (Package: com.extrabite.app)',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Browse surplus meals within 2km, reserve portion, pay at pickup.';
      case UserRole.pgOwner:
        return 'Post leftover PG mess food, scan customer QR code at pickup.';
      case UserRole.admin:
        return 'Monitor platform metrics, verify PGs, track food rescued.';
    }
  }
}
