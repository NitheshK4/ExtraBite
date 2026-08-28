import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/pg_profile.dart';
import '../../../providers/admin_provider.dart';

class PgVerificationTab extends ConsumerWidget {
  const PgVerificationTab({super.key});

  String _getInitials(String name) {
    if (name.isEmpty) return 'PG';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final pendingList = adminState.filteredPendingProfiles;
    final isSearching = adminState.searchQuery.trim().isNotEmpty;

    if (adminState.isLoading && pendingList.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (pendingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.check_circle_outline,
                color: isSearching ? AppColors.onSurfaceVariant : AppColors.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No Matching Properties' : 'No Pending Approvals',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'No pending properties found matching "${adminState.searchQuery}".'
                  : 'All registered hostel and PG properties have been successfully approved.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'PROPERTY NAME',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'OWNER',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'LOCATION',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'FSSAI STATUS',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SUBMITTED',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 88),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),

          // Table Rows
          Expanded(
            child: ListView.separated(
              itemCount: pendingList.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outline),
              itemBuilder: (context, index) {
                final profile = pendingList[index];
                return _buildTableRow(context, profile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, PgProfile profile) {
    final hasFssai = profile.fssaiLicenseNumber != null && profile.fssaiLicenseNumber!.isNotEmpty;
    final initials = _getInitials(profile.pgName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      child: Row(
        children: [
          // 1. Property Name with Initial Box
          Expanded(
            flex: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    profile.pgName,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 2. Owner
          Expanded(
            flex: 3,
            child: Text(
              profile.ownerName ?? 'Owner: ${profile.ownerId.substring(0, 8)}',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 3. Location
          Expanded(
            flex: 3,
            child: Text(
              profile.neighborhood.isNotEmpty ? '${profile.neighborhood}, ${profile.city}' : profile.city,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 4. FSSAI Status Badge
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasFssai ? AppColors.primaryContainer : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasFssai ? Icons.check_circle : Icons.pending,
                      size: 12,
                      color: hasFssai ? AppColors.veg : AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasFssai ? 'Valid' : 'Reviewing Docs',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasFssai ? AppColors.veg : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Submitted
          Expanded(
            flex: 2,
            child: Text(
              _formatRelativeTime(profile.createdAt),
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ),

          // 6. Action Button
          SizedBox(
            width: 88,
            child: ElevatedButton(
              onPressed: () {
                context.push('/pg-verification/${profile.id}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.onSurface,
                elevation: 0,
                side: const BorderSide(color: AppColors.outline),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('View', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
