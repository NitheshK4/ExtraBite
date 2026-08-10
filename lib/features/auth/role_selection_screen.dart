import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Choose Your Role',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you would like to use or explore ExtraBite.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              _buildRoleCard(
                context: context,
                ref: ref,
                role: UserRole.customer,
                title: 'Customer / Student',
                description: 'Discover nearby PG surplus meals, reserve with Pay at Pickup, and track passes.',
                icon: Icons.person_rounded,
                color: AppColors.primary,
                route: '/discover',
              ),

              const SizedBox(height: 16),

              _buildRoleCard(
                context: context,
                ref: ref,
                role: UserRole.pgOwner,
                title: 'PG Owner / Hostel Host',
                description: 'List unsold meals, manage inventory, verify customer QR passes, and avoid food waste.',
                icon: Icons.storefront_rounded,
                color: AppColors.secondary,
                route: '/owner-dashboard',
              ),

              const SizedBox(height: 16),

              _buildRoleCard(
                context: context,
                ref: ref,
                role: UserRole.admin,
                title: 'Admin / Operations',
                description: 'Approve PGs, moderate listings, review dispute reports, and monitor marketplace audit logs.',
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.indigo,
                route: '/admin-dashboard',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required WidgetRef ref,
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/auth?role=${role.name}');
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
