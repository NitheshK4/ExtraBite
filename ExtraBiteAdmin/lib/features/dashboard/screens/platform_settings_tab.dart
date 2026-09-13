import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';

class PlatformSettingsTab extends ConsumerWidget {
  const PlatformSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Configuration & Policy Status',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Operational parameters, backend architecture invariants, and security policies.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: adminState.isConnected ? AppColors.primaryContainer : AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: adminState.isConnected ? AppColors.primary : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          adminState.isConnected ? 'Database Connected' : 'Sync Offline',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: adminState.isConnected ? AppColors.primary : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Core Architecture Invariants Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Enforced Platform Invariants',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildInvariantItem(
                      title: 'Zero Online Payment Gateway ("Pay at Pickup" Invariant)',
                      description: 'Eliminates refund disputes and payment gateway fees. All reservations are marked pay_at_pickup by schema constraint.',
                      statusText: 'Active Policy',
                      isEnforced: true,
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildInvariantItem(
                      title: 'Haversine 10km Discovery Boundary',
                      description: 'Limits customer meal radius to 10 kilometers to guarantee food warmth and student pickup feasibility.',
                      statusText: 'Active Policy',
                      isEnforced: true,
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildInvariantItem(
                      title: 'Mandatory FSSAI Compliance Verification',
                      description: 'PG hosts cannot list meals until an administrator verifies license credentials and toggles is_approved = true.',
                      statusText: 'Active Policy',
                      isEnforced: true,
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildInvariantItem(
                      title: 'Automatic Portion Replenishment on Cancellation',
                      description: 'Database triggers restore available portions to food_listings immediately upon reservation cancellation.',
                      statusText: 'Active Policy',
                      isEnforced: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Infrastructure & Storage Settings
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Backend Infrastructure Status',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildConfigItem('Database Engine', 'PostgreSQL with Row Level Security (RLS)'),
                    _buildConfigItem('Security Model', 'JWT Role Authentication (Admin, PG Owner, Customer)'),
                    _buildConfigItem('Storage Buckets', 'food-images (Public), pg-photos (Public), pg-documents (Private)'),
                    _buildConfigItem('Schema Version', 'ExtraBite Core Schema v2.4 (Strict FK & Check Constraints)'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvariantItem({
    required String title,
    required String description,
    required String statusText,
    required bool isEnforced,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isEnforced ? Icons.check_circle : Icons.pending,
          color: isEnforced ? AppColors.primary : AppColors.secondary,
          size: 20,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
