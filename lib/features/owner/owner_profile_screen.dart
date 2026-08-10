import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/user_model.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PG & Host Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: const Icon(Icons.storefront_rounded, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sri Sai Executive PG & Mess',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Managed by ${user?.fullName ?? 'Host'} • Koramangala, Bengaluru',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Text(
                      'FSSAI Verified: 11220334000124',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Demo Switcher
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
                  const Text(
                    'Switch Demo Role',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
                            context.go('/discover');
                          },
                          child: const Text('Customer View'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).switchDemoRole(UserRole.admin);
                            context.go('/admin-dashboard');
                          },
                          child: const Text('Admin View'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('PG Address'),
                    subtitle: const Text('14th Main Rd, 4th Block, Koramangala, Bengaluru'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Contact Phone'),
                    subtitle: Text(user?.phoneNumber ?? '+91 91234 56789'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Default Pickup Windows'),
                    subtitle: const Text('Lunch: 1:30 PM – 3:30 PM\nDinner: 8:30 PM – 10:30 PM'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
    );
  }
}
