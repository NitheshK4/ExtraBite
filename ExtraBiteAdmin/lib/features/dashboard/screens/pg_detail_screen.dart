import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/pg_profile.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/pg_rejection_modal.dart';

class PgDetailScreen extends ConsumerStatefulWidget {
  final String pgId;

  const PgDetailScreen({
    super.key,
    required this.pgId,
  });

  @override
  ConsumerState<PgDetailScreen> createState() => _PgDetailScreenState();
}

class _PgDetailScreenState extends ConsumerState<PgDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).selectProfileById(widget.pgId);
    });
  }

  Future<void> _approvePg(PgProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Confirm Approval',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to approve "${profile.pgName}"? This will allow them to post surplus food meals immediately.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.45),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              side: const BorderSide(color: AppColors.outline),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(adminProvider.notifier).approveProfile(widget.pgId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${profile.pgName}" has been successfully approved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/pg-verification');
      }
    }
  }

  Future<void> _rejectPg(PgProfile profile) async {
    final reason = await PgRejectionModal.show(context, profile.pgName);

    if (reason != null && reason.trim().isNotEmpty && mounted) {
      final success = await ref.read(adminProvider.notifier).rejectProfile(
            widget.pgId,
            reason.trim(),
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property "${profile.pgName}" marked as rejected.'),
            backgroundColor: AppColors.onSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/pg-verification');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final adminState = ref.watch(adminProvider);
    final profile = adminState.selectedProfile;
    final user = authState.user;

    final adminName = (user != null && user.name.trim().isNotEmpty)
        ? user.name
        : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'Admin');
    final adminRole = user?.role == UserRole.admin ? 'Administrator' : 'Admin';
    final avatarInitial = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 1. Fixed 256px Left Sidebar
          _buildSidebar(context, adminState, adminName, adminRole, avatarInitial),

          // 2. Right Side Workspace
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Action Bar (80px)
                _buildTopBar(context, profile),

                // Main Content Workspace
                Expanded(
                  child: adminState.isLoading && profile == null
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : (profile == null
                          ? _buildNotFoundState(context)
                          : _buildDetailContent(context, profile)),
                ),

                // Pinned Bottom Moderation Action Bar
                if (profile != null) _buildPinnedModerationBar(context, profile, adminState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar (Fixed 256px)
  // ---------------------------------------------------------------------------
  Widget _buildSidebar(
    BuildContext context,
    AdminState adminState,
    String adminName,
    String adminRole,
    String avatarInitial,
  ) {
    return Container(
      width: 256,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Branding Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/branding/extrabite_logo.png',
                      height: 28,
                      width: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ExtraBite',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'OPERATIONS PORTAL',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebarGroupHeader('MAIN'),
                  _buildSidebarNavItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard Overview',
                    onTap: () => context.go('/dashboard'),
                    isSelected: false,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.verified_user_outlined,
                    title: 'PG Verification',
                    onTap: () => context.go('/pg-verification'),
                    isSelected: true,
                    badgeCount: adminState.pendingProfiles.length,
                    badgeColor: AppColors.secondary,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.group_outlined,
                    title: 'User Management',
                    onTap: () {},
                    isSelected: false,
                    isDisabled: true,
                  ),
                  const SizedBox(height: 14),
                  _buildSidebarGroupHeader('MARKETPLACE'),
                  _buildSidebarNavItem(
                    icon: Icons.restaurant_outlined,
                    title: 'Food Listings',
                    onTap: () {},
                    isSelected: false,
                    isDisabled: true,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Reservations Feed',
                    onTap: () {},
                    isSelected: false,
                    isDisabled: true,
                  ),
                  const SizedBox(height: 14),
                  _buildSidebarGroupHeader('SYSTEM'),
                  _buildSidebarNavItem(
                    icon: Icons.warning_amber_rounded,
                    title: 'Safety & Reports',
                    onTap: () {},
                    isSelected: false,
                    isDisabled: true,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.insights_outlined,
                    title: 'Analytics & Impact',
                    onTap: () {},
                    isSelected: false,
                    isDisabled: true,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.settings_outlined,
                    title: 'Platform Settings',
                    onTap: () {},
                    isSelected: false,
                    isDisabled: true,
                  ),
                ],
              ),
            ),
          ),

          // Footer Profile & Logout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    avatarInitial,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        adminName,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        adminRole,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.onSurfaceVariant),
                  tooltip: 'Log Out',
                  hoverColor: AppColors.errorContainer,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSelected,
    int badgeCount = 0,
    Color badgeColor = AppColors.secondary,
    bool isDisabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : (isDisabled ? AppColors.onSurfaceVariant.withOpacity(0.5) : AppColors.onSurfaceVariant),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? AppColors.onPrimaryContainer
                          : (isDisabled ? AppColors.onSurfaceVariant.withOpacity(0.5) : AppColors.onSurfaceVariant),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Action Bar (80px)
  // ---------------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context, PgProfile? profile) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumb Navigation
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => context.go('/dashboard'),
                  child: Text(
                    'Admin',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.outlineVariant),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => context.go('/pg-verification'),
                  child: Text(
                    'PG Verification',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.outlineVariant),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Property Review',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Controls: Status Badge + Back Action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profile != null) _buildStatusBadge(profile),
              const SizedBox(width: 16),
              Container(width: 1, height: 28, color: AppColors.outline),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => context.go('/pg-verification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(
                  'Back to Queue',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PgProfile profile) {
    if (profile.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Approved & Active',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_top, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            'Awaiting Verification',
            style: GoogleFonts.inter(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Detail Content (12-Column Responsive Grid)
  // ---------------------------------------------------------------------------
  Widget _buildDetailContent(BuildContext context, PgProfile profile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left 4-Column Area (Width: ~380px)
                        SizedBox(
                          width: 380,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPropertyImageGallery(profile),
                              const SizedBox(height: 24),
                              _buildLocationVerificationCard(profile),
                              const SizedBox(height: 24),
                              _buildFssaiVerificationCard(profile),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Right 8-Column Details Area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeaderOverviewCard(profile),
                              const SizedBox(height: 24),
                              _buildOwnerDetailsCard(profile),
                              const SizedBox(height: 24),
                              _buildAddressCard(profile),
                              const SizedBox(height: 24),
                              _buildKitchenDescriptionCard(profile),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPropertyImageGallery(profile),
                        const SizedBox(height: 20),
                        _buildHeaderOverviewCard(profile),
                        const SizedBox(height: 20),
                        _buildLocationVerificationCard(profile),
                        const SizedBox(height: 20),
                        _buildFssaiVerificationCard(profile),
                        const SizedBox(height: 20),
                        _buildOwnerDetailsCard(profile),
                        const SizedBox(height: 20),
                        _buildAddressCard(profile),
                        const SizedBox(height: 20),
                        _buildKitchenDescriptionCard(profile),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // 1. Property Image Gallery Card
  Widget _buildPropertyImageGallery(PgProfile profile) {
    final hasImage = profile.imageUrl != null && profile.imageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          // Main 4:3 Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      profile.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  else
                    _buildImagePlaceholder(),

                  // Bottom Gradient Overlay with Label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xCC000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Main Exterior',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            hasImage ? '1 Photo' : '0 Photos',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Thumbnail Strip Below
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Active Thumbnail
                Container(
                  width: 54,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: hasImage
                        ? Image.network(
                            profile.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20, color: AppColors.textLight),
                          )
                        : const Icon(Icons.image, size: 20, color: AppColors.textLight),
                  ),
                ),
                const SizedBox(width: 8),

                // Placeholder slots
                ...List.generate(2, (index) {
                  return Container(
                    width: 54,
                    height: 42,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant, width: 1),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppColors.outlineVariant),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment_rounded, size: 48, color: AppColors.textLight),
            const SizedBox(height: 8),
            Text(
              'No photo uploaded',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Location Verification Card
  Widget _buildLocationVerificationCard(PgProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Location Verification',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Map Preview Graphic
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPainter(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_pin, color: AppColors.error, size: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.onSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Verified Coordinates',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Coordinates in JetBrains Mono
          Text(
            'GEOLOCATION COORDINATES',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lat: ${profile.latitude}, Lon: ${profile.longitude}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Locality Pill
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${profile.neighborhood.isNotEmpty ? profile.neighborhood : profile.city}, ${profile.city}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. FSSAI Verification Card
  Widget _buildFssaiVerificationCard(PgProfile profile) {
    final hasFssai = profile.fssaiLicenseNumber != null && profile.fssaiLicenseNumber!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.tertiary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'FSSAI Verification',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasFssai ? AppColors.primaryContainer : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasFssai ? 'Provided' : 'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasFssai ? AppColors.primary : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'FSSAI LICENSE NUMBER',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              profile.fssaiLicenseNumber ?? 'Not Provided',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasFssai ? AppColors.onSurface : AppColors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Header Overview Card (Right Column)
  Widget _buildHeaderOverviewCard(PgProfile profile) {
    final formattedDate = profile.createdAt != null
        ? DateFormat('MMMM dd, yyyy').format(profile.createdAt!)
        : 'Recently Submitted';

    final shortId = profile.id.length >= 8 ? profile.id.substring(0, 8).toUpperCase() : profile.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.pgName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: #PG-$shortId',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          'Submitted on $formattedDate',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(profile),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Owner Details Card
  Widget _buildOwnerDetailsCard(PgProfile profile) {
    final ownerName = profile.ownerName ?? 'Property Owner';
    final ownerInitial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Owner Information',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  ownerInitial,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ownerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Host Account',
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
                      'Account ID: ${profile.ownerId}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.outline),
          const SizedBox(height: 14),

          // Contact Details (Wrap for responsive safety)
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: _buildContactItem(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: profile.ownerEmail ?? '-',
                ),
              ),
              SizedBox(
                width: 220,
                child: _buildContactItem(
                  icon: Icons.phone_outlined,
                  label: 'Contact Phone',
                  value: profile.contactPhone.isNotEmpty ? profile.contactPhone : '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Address Card
  Widget _buildAddressCard(PgProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Full Property Address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            profile.address,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                child: _buildAddressPill('Neighborhood / Landmark', profile.neighborhood.isNotEmpty ? profile.neighborhood : '-'),
              ),
              SizedBox(
                width: 220,
                child: _buildAddressPill('City', profile.city),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 7. Kitchen Description Card
  Widget _buildKitchenDescriptionCard(PgProfile profile) {
    final description = (profile.description != null && profile.description!.trim().isNotEmpty)
        ? profile.description!
        : 'No kitchen or offering description was provided during registration.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.soup_kitchen_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kitchen & Offering Description',
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: profile.isActive ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  profile.isActive ? 'Active Mess Facility' : 'Inactive Facility',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: profile.isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pinned Bottom Moderation Bar
  // ---------------------------------------------------------------------------
  Widget _buildPinnedModerationBar(BuildContext context, PgProfile profile, AdminState adminState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left status prompt
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: profile.isApproved ? AppColors.primary : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    profile.isApproved
                        ? 'Property verification active and approved.'
                        : 'Review complete? Take moderation action to update PG listing capability.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: adminState.isLoading ? null : () => _rejectPg(profile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: Text(
                  'Reject Property',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: adminState.isLoading ? null : () => _approvePg(profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  'Approve PG Property',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Not Found State
  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'The requested property details could not be loaded.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/pg-verification'),
            child: const Text('Back to Verification Queue'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Canvas Grid Painter for Map Box Graphic
// ---------------------------------------------------------------------------
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.08)
      ..strokeWidth = 1;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
