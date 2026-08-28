import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final allUsersProvider =
    FutureProvider.autoDispose<List<AdminUserRecord>>((ref) async {
  return ref.read(adminRepositoryProvider).getAllUsers();
});

final pendingUsersProvider =
    FutureProvider.autoDispose<List<AdminUserRecord>>((ref) async {
  return ref.read(adminRepositoryProvider).getPendingUsers();
});

// ---------------------------------------------------------------------------
// Admin Dashboard Screen
// ---------------------------------------------------------------------------

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _approveOwner(AdminUserRecord user) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).approveOwner(user.id);
      _showSnack('✅ ${user.fullName} approved as PG Owner');
    });
  }

  Future<void> _revokeOwner(AdminUserRecord user) async {
    final confirmed = await _showConfirm(
      'Revoke PG Owner eligibility from ${user.fullName}?',
    );
    if (!confirmed) return;
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).revokeOwner(user.id);
      _showSnack('⚠️ PG Owner eligibility revoked for ${user.fullName}');
    });
  }

  Future<void> _toggleSuspend(AdminUserRecord user) async {
    final action = user.isSuspended ? 'Unsuspend' : 'Suspend';
    final confirmed = await _showConfirm('$action ${user.fullName}?');
    if (!confirmed) return;
    await _runAction(() async {
      await ref
          .read(adminRepositoryProvider)
          .setSuspended(user.id, suspended: !user.isSuspended);
      _showSnack(
          '${user.isSuspended ? '🔓 Unsuspended' : '🔒 Suspended'}: ${user.fullName}');
    });
  }

  Future<void> _runAction(Future<void> Function() fn) async {
    setState(() => _actionLoading = true);
    try {
      await fn();
      ref.invalidate(allUsersProvider);
      ref.invalidate(pendingUsersProvider);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _showConfirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Action'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset(
            'assets/branding/extrabite_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(allUsersProvider);
              ref.invalidate(pendingUsersProvider);
            },
          ),
          // Sign out
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48 + 60),
          child: Column(
            children: [
              // Stats summary row
              pendingAsync.when(
                data: (pending) => allUsersAsync.when(
                  data: (all) => _StatsBar(
                    pendingCount: pending.length,
                    ownerCount:
                        all.where((u) => u.role == UserRole.owner).length,
                    customerCount: all
                        .where((u) =>
                            u.role == UserRole.personal && u.roleFinalized)
                        .length,
                    totalCount: all.length,
                  ),
                  loading: () => const SizedBox(height: 44),
                  error: (_, __) => const SizedBox(height: 44),
                ),
                loading: () => const SizedBox(height: 44),
                error: (_, __) => const SizedBox(height: 44),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pending'),
                        const SizedBox(width: 6),
                        pendingAsync.when(
                          data: (list) => list.isEmpty
                              ? const SizedBox.shrink()
                              : _BadgeChip(count: list.length),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const Tab(text: 'PG Owners'),
                  const Tab(text: 'All Users'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ---- Tab 1: Pending ----
                    _UserListTab(
                      asyncUsers: pendingAsync,
                      filter: (u) {
                        if (_searchQuery.isEmpty) return true;
                        return u.fullName.toLowerCase().contains(_searchQuery) ||
                            u.email.toLowerCase().contains(_searchQuery);
                      },
                      emptyMessage: 'No pending applications',
                      emptyIcon: Icons.check_circle_outline_rounded,
                      onApprove: _approveOwner,
                      onRevoke: _revokeOwner,
                      onToggleSuspend: _toggleSuspend,
                      showApproveButton: true,
                    ),
                    // ---- Tab 2: PG Owners ----
                    _UserListTab(
                      asyncUsers: allUsersAsync,
                      filter: (u) {
                        if (u.role != UserRole.owner) return false;
                        if (_searchQuery.isEmpty) return true;
                        return u.fullName.toLowerCase().contains(_searchQuery) ||
                            u.email.toLowerCase().contains(_searchQuery);
                      },
                      emptyMessage: 'No PG Owners yet',
                      emptyIcon: Icons.storefront_outlined,
                      onApprove: _approveOwner,
                      onRevoke: _revokeOwner,
                      onToggleSuspend: _toggleSuspend,
                      showApproveButton: false,
                    ),
                    // ---- Tab 3: All Users ----
                    _UserListTab(
                      asyncUsers: allUsersAsync,
                      filter: (u) {
                        if (_searchQuery.isEmpty) return true;
                        return u.fullName.toLowerCase().contains(_searchQuery) ||
                            u.email.toLowerCase().contains(_searchQuery);
                      },
                      emptyMessage: 'No users found',
                      emptyIcon: Icons.people_outline,
                      onApprove: _approveOwner,
                      onRevoke: _revokeOwner,
                      onToggleSuspend: _toggleSuspend,
                      showApproveButton: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Loading overlay during action
          if (_actionLoading)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats Bar Widget
// ---------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  final int pendingCount;
  final int ownerCount;
  final int customerCount;
  final int totalCount;

  const _StatsBar({
    required this.pendingCount,
    required this.ownerCount,
    required this.customerCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatChip(
            label: 'Pending',
            value: pendingCount,
            color: Colors.orange.shade300,
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Owners',
            value: ownerCount,
            color: Colors.lightBlue.shade300,
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Customers',
            value: customerCount,
            color: Colors.greenAccent.shade400,
            icon: Icons.person_outline,
          ),
          const Spacer(),
          Text(
            '$totalCount total',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final int count;
  const _BadgeChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User List Tab
// ---------------------------------------------------------------------------

class _UserListTab extends StatelessWidget {
  final AsyncValue<List<AdminUserRecord>> asyncUsers;
  final bool Function(AdminUserRecord) filter;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function(AdminUserRecord) onApprove;
  final Future<void> Function(AdminUserRecord) onRevoke;
  final Future<void> Function(AdminUserRecord) onToggleSuspend;
  final bool showApproveButton;

  const _UserListTab({
    required this.asyncUsers,
    required this.filter,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onApprove,
    required this.onRevoke,
    required this.onToggleSuspend,
    required this.showApproveButton,
  });

  @override
  Widget build(BuildContext context) {
    return asyncUsers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load users:\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      data: (users) {
        final filtered = users.where(filter).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 56, color: AppColors.textLight),
                const SizedBox(height: 12),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _UserCard(
            user: filtered[i],
            onApprove: onApprove,
            onRevoke: onRevoke,
            onToggleSuspend: onToggleSuspend,
            showApproveButton: showApproveButton,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// User Card
// ---------------------------------------------------------------------------

class _UserCard extends StatelessWidget {
  final AdminUserRecord user;
  final Future<void> Function(AdminUserRecord) onApprove;
  final Future<void> Function(AdminUserRecord) onRevoke;
  final Future<void> Function(AdminUserRecord) onToggleSuspend;
  final bool showApproveButton;

  const _UserCard({
    required this.user,
    required this.onApprove,
    required this.onRevoke,
    required this.onToggleSuspend,
    required this.showApproveButton,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = !user.roleFinalized;
    final isOwner = user.role == UserRole.owner;
    final isSuspended = user.isSuspended;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSuspended
              ? AppColors.error.withOpacity(0.4)
              : isPending
                  ? Colors.orange.withOpacity(0.4)
                  : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _avatarColor(user.role),
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? '(no name)' : user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (user.phone.isNotEmpty)
                        Text(
                          user.phone,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
                // Suspend toggle
                IconButton(
                  tooltip: isSuspended ? 'Unsuspend' : 'Suspend',
                  icon: Icon(
                    isSuspended
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    color: isSuspended ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
                  onPressed: () => onToggleSuspend(user),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Status badges ──
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _StatusBadge(
                  label: _roleLabel(user.role),
                  color: _roleColor(user.role),
                ),
                if (!user.roleFinalized)
                  const _StatusBadge(
                    label: 'Not Finalized',
                    color: Colors.orange,
                  ),
                if (user.isOwnerEligible)
                  const _StatusBadge(
                    label: 'Owner Eligible',
                    color: Colors.lightBlue,
                  ),
                if (user.isSuspended)
                  const _StatusBadge(label: 'Suspended', color: AppColors.error),
                if (user.isVerified)
                  const _StatusBadge(label: 'Verified', color: AppColors.success),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Joined ${_formatDate(user.createdAt)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            // ── Action buttons ──
            Row(
              children: [
                // Approve button — shown if pending or explicitly requested
                if (showApproveButton && !user.isOwnerEligible && !isOwner)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.verified_rounded, size: 16),
                      label: const Text('Approve as Owner',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => onApprove(user),
                    ),
                  ),
                // Revoke button — shown only for eligible / actual owners
                if (user.isOwnerEligible || isOwner) ...[
                  if (showApproveButton && !user.isOwnerEligible && !isOwner)
                    const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      label: const Text('Revoke Owner',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => onRevoke(user),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'PG Owner';
      case UserRole.admin:
        return 'Admin';
      default:
        return 'Customer';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Colors.lightBlue;
      case UserRole.admin:
        return Colors.deepPurple;
      default:
        return AppColors.primary;
    }
  }

  Color _avatarColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return const Color(0xFF1976D2);
      case UserRole.admin:
        return const Color(0xFF6A1B9A);
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Status Badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color is MaterialColor
              ? color
              : color,
        ),
      ),
    );
  }
}
