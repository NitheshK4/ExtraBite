import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/admin_provider.dart';
import 'dashboard_overview_tab.dart';
import 'pg_verification_tab.dart';
import 'user_management_tab.dart';
import 'food_listings_tab.dart';
import 'reservations_feed_tab.dart';
import 'safety_reports_tab.dart';
import 'analytics_impact_tab.dart';
import 'platform_settings_tab.dart';

class AdminDashboardLayout extends ConsumerStatefulWidget {
  final int initialTab;

  const AdminDashboardLayout({
    super.key,
    required this.initialTab,
  });

  @override
  ConsumerState<AdminDashboardLayout> createState() => _AdminDashboardLayoutState();
}

class _AdminDashboardLayoutState extends ConsumerState<AdminDashboardLayout> {
  late int _selectedTab;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadDashboardData();
    });
  }

  @override
  void didUpdateWidget(covariant AdminDashboardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _selectedTab = widget.initialTab;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index, String route) {
    setState(() {
      _selectedTab = index;
    });
    context.go(route);
  }

  String _formatLastSynced(DateTime lastSynced) {
    final diff = DateTime.now().difference(lastSynced);
    if (diff.inSeconds < 45) return 'Synced just now';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    return 'Synced ${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final adminState = ref.watch(adminProvider);
    final user = authState.user;

    final adminName = (user != null && user.name.trim().isNotEmpty)
        ? user.name
        : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'Admin');
    final adminRole = user?.role == UserRole.admin ? 'Administrator' : 'Admin';
    final avatarInitial = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A';

    final tabs = [
      const DashboardOverviewTab(),
      const PgVerificationTab(),
      const UserManagementTab(),
      const FoodListingsTab(),
      const ReservationsFeedTab(),
      const SafetyReportsTab(),
      const AnalyticsImpactTab(),
      const PlatformSettingsTab(),
    ];

    final tabTitle = switch (_selectedTab) {
      0 => 'Operations Overview',
      1 => 'Property Approvals Queue',
      2 => 'User Management',
      3 => 'Food Listings Operations',
      4 => 'Reservations Live Feed',
      5 => 'Safety & Reports Queue',
      6 => 'Analytics & Impact',
      7 => 'Platform Settings',
      _ => 'Operations Console',
    };

    final pendingReportsCount = adminState.reports.where((r) => r.status == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 1. Fixed Desktop Sidebar (256px / w-64)
          Container(
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
                          const Icon(
                            Icons.eco,
                            color: AppColors.primary,
                            size: 26,
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
                        // Group: MAIN
                        _buildGroupHeader('MAIN'),
                        _buildNavItem(
                          icon: Icons.dashboard,
                          title: 'Dashboard Overview',
                          index: 0,
                          route: '/dashboard',
                        ),
                        _buildNavItem(
                          icon: Icons.verified_user_outlined,
                          title: 'PG Verification',
                          index: 1,
                          route: '/pg-verification',
                          badgeCount: adminState.pendingProfiles.length,
                          badgeColor: AppColors.secondary,
                        ),
                        _buildNavItem(
                          icon: Icons.group_outlined,
                          title: 'User Management',
                          index: 2,
                          route: '/users',
                        ),

                        const SizedBox(height: 14),

                        // Group: MARKETPLACE
                        _buildGroupHeader('MARKETPLACE'),
                        _buildNavItem(
                          icon: Icons.restaurant_outlined,
                          title: 'Food Listings',
                          index: 3,
                          route: '/food-listings',
                        ),
                        _buildNavItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Reservations Feed',
                          index: 4,
                          route: '/reservations',
                        ),

                        const SizedBox(height: 14),

                        // Group: SYSTEM
                        _buildGroupHeader('SYSTEM'),
                        _buildNavItem(
                          icon: Icons.warning_amber_rounded,
                          title: 'Safety & Reports',
                          index: 5,
                          route: '/reports',
                          badgeCount: pendingReportsCount,
                          badgeColor: AppColors.error,
                        ),
                        _buildNavItem(
                          icon: Icons.insights_outlined,
                          title: 'Analytics & Impact',
                          index: 6,
                          route: '/analytics',
                        ),
                        _buildNavItem(
                          icon: Icons.settings_outlined,
                          title: 'Platform Settings',
                          index: 7,
                          route: '/settings',
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Box: Real Authenticated Admin User Profile & Logout
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
          ),

          // 2. Right Side Main Content Panel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Bar (Height: 64px)
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(color: AppColors.outline, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Breadcrumb
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Admin',
                              style: GoogleFonts.inter(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, size: 16, color: AppColors.outlineVariant),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                tabTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right Controls: Search, Connectivity Status, Notification Bell, Sync info, Refresh CTA
                      Flexible(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Live Focused Search Box
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300, minWidth: 100),
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: GoogleFonts.inter(fontSize: 13),
                                    onChanged: (val) {
                                      ref.read(adminProvider.notifier).setSearchQuery(val);
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search PGs, users, order IDs...',
                                      hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.onSurfaceVariant),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 16, color: AppColors.onSurfaceVariant),
                                              onPressed: () {
                                                _searchController.clear();
                                                ref.read(adminProvider.notifier).setSearchQuery('');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Honest Connectivity Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: adminState.errorMessage != null
                                    ? AppColors.errorContainer
                                    : (adminState.isLoading ? AppColors.secondaryContainer : AppColors.primaryContainer),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: adminState.errorMessage != null
                                          ? AppColors.error
                                          : (adminState.isLoading ? AppColors.secondary : AppColors.veg),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    adminState.errorMessage != null
                                        ? 'Connection Issue'
                                        : (adminState.isLoading ? 'Syncing...' : 'Supabase Connected'),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: adminState.errorMessage != null
                                          ? AppColors.error
                                          : (adminState.isLoading ? AppColors.secondary : AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Notification Button
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.onSurfaceVariant),
                              tooltip: 'Notifications',
                              hoverColor: AppColors.primaryContainer,
                              onPressed: () {},
                            ),
                            const SizedBox(width: 4),

                            // Vertical divider
                            Container(
                              width: 1,
                              height: 24,
                              color: AppColors.outline,
                            ),
                            const SizedBox(width: 10),

                            // Real Synced timestamp
                            Text(
                              _formatLastSynced(adminState.lastSyncedAt),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Refresh Button CTA
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: adminState.isLoading
                                  ? null
                                  : () {
                                      ref.read(adminProvider.notifier).loadDashboardData();
                                    },
                              icon: adminState.isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  : const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                              label: Text(
                                'Refresh',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Error status overlay banner
                if (adminState.errorMessage != null)
                  Container(
                    color: AppColors.errorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Text(
                      adminState.errorMessage!,
                      style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),

                // Scrollable Workspace
                Expanded(
                  child: _selectedTab < tabs.length
                      ? tabs[_selectedTab]
                      : const Center(child: Text('Coming Soon')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
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

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    required String route,
    int badgeCount = 0,
    Color badgeColor = AppColors.secondary,
    bool isDisabled = false,
  }) {
    final isSelected = _selectedTab == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () => _onTabSelected(index, route),
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
}
