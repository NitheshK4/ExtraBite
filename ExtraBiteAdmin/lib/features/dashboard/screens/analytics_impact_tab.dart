import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';

class AnalyticsImpactTab extends ConsumerStatefulWidget {
  const AnalyticsImpactTab({super.key});

  @override
  ConsumerState<AnalyticsImpactTab> createState() => _AnalyticsImpactTabState();
}

class _AnalyticsImpactTabState extends ConsumerState<AnalyticsImpactTab> {
  String _selectedRange = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final data = adminState.analytics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analytics & Sustainability Impact',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time metrics computed directly from database profiles, listings, and reservations.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildRangePill('TODAY', 'Today'),
                          _buildRangePill('7D', '7 Days'),
                          _buildRangePill('30D', '30 Days'),
                          _buildRangePill('ALL', 'All Time'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => ref.read(adminProvider.notifier).loadAnalytics(),
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        tooltip: 'Refresh Analytics',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (adminState.isLoading && data == null)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (data != null) ...[
                // 2. Primary Impact KPI Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                          child: _buildKpiCard(
                            title: 'Portions Rescued',
                            value: '${data.rescuedPortions}',
                            subtitle: 'Surplus meals saved from waste',
                            icon: Icons.eco,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                          child: _buildKpiCard(
                            title: 'Food Value Rescued',
                            value: '₹${data.totalFoodValueRescued.toStringAsFixed(0)}',
                            subtitle: 'Student savings at pickup',
                            icon: Icons.savings_outlined,
                            color: AppColors.tertiary,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                          child: _buildKpiCard(
                            title: 'Completion Rate',
                            value: '${data.completionRate.toStringAsFixed(1)}%',
                            subtitle: '${data.completedPickups} of ${data.totalReservations} fulfilled',
                            icon: Icons.task_alt,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                          child: _buildKpiCard(
                            title: 'Active Surplus Meals',
                            value: '${data.activeFoodListings}',
                            subtitle: '${data.totalFoodListings} total meals listed',
                            icon: Icons.restaurant,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. Demographics & Infrastructure Breakdown
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 800;

                    final userDistCard = Container(
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
                              const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'User Base Distribution',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildProgressBar(
                            label: 'Students / Customers',
                            count: data.totalCustomers,
                            total: data.totalUsers,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 14),
                          _buildProgressBar(
                            label: 'PG Mess Hosts',
                            count: data.totalPgOwners,
                            total: data.totalUsers,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 14),
                          _buildProgressBar(
                            label: 'Administrators',
                            count: data.totalAdmins,
                            total: data.totalUsers,
                            color: AppColors.tertiary,
                          ),
                        ],
                      ),
                    );

                    final partnerStatusCard = Container(
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
                              const Icon(Icons.apartment_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Partner Facilities Status',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildProgressBar(
                            label: 'Verified Active Messes',
                            count: data.verifiedPgs,
                            total: data.verifiedPgs + data.pendingPgs,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 14),
                          _buildProgressBar(
                            label: 'Awaiting Verification',
                            count: data.pendingPgs,
                            total: data.verifiedPgs + data.pendingPgs,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 14),
                          _buildProgressBar(
                            label: 'Cancelled Orders',
                            count: data.cancelledReservations,
                            total: data.totalReservations,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    );

                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: userDistCard),
                              const SizedBox(width: 24),
                              Expanded(child: partnerStatusCard),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              userDistCard,
                              const SizedBox(height: 20),
                              partnerStatusCard,
                            ],
                          );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangePill(String key, String label) {
    final isSelected = _selectedRange == key;
    return InkWell(
      onTap: () => setState(() => _selectedRange = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percentStr = total > 0 ? '${(percentage * 100).toStringAsFixed(0)}%' : '0%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count ($percentStr)',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
