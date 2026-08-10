import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/user_model.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/auth'),
            child: const Text('Sign In'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Avatar & Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phoneNumber ?? '+91 98765 43210',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Demo Role Switcher Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Demo Role Quick-Switcher',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Instantly experience ExtraBite as a Customer, PG Owner, or Admin.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: user.role == UserRole.pgOwner ? AppColors.primary : Colors.white,
                            foregroundColor: user.role == UserRole.pgOwner ? Colors.white : AppColors.primary,
                          ),
                          onPressed: () {
                            ref.read(authProvider.notifier).switchDemoRole(UserRole.pgOwner);
                            context.go('/owner-dashboard');
                          },
                          child: const Text('PG Owner'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: user.role == UserRole.admin ? AppColors.primary : Colors.white,
                            foregroundColor: user.role == UserRole.admin ? Colors.white : AppColors.primary,
                          ),
                          onPressed: () {
                            ref.read(authProvider.notifier).switchDemoRole(UserRole.admin);
                            context.go('/admin-dashboard');
                          },
                          child: const Text('Admin'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dietary Preferences
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dietary Preferences',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['Pure Veg', 'High Protein', 'Gluten Free', 'Vegan'].map((pref) {
                        final isSelected = user.dietaryPreferences.contains(pref);
                        return FilterChip(
                          label: Text(pref),
                          selected: isSelected,
                          onSelected: (val) {
                            final current = List<String>.from(user.dietaryPreferences);
                            if (val) {
                              current.add(pref);
                            } else {
                              current.remove(pref);
                            }
                            ref.read(authProvider.notifier).updateProfile(
                                  fullName: user.fullName,
                                  phoneNumber: user.phoneNumber ?? '',
                                  dietaryPreferences: current,
                                );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help, Rules, & Sign Out
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    title: const Text('Pay at Pickup Policy'),
                    subtitle: const Text('Zero prepayments. Pay hosts in person.'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Pay at Pickup Policy'),
                          content: const Text(
                            'ExtraBite is 100% Pay at Pickup. You never pay online or enter payment credentials in the app. Simply collect your meal and settle payment directly with the PG management.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Understood'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.red),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      ref.read(authProvider.notifier).signOut();
                      context.go('/auth');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
