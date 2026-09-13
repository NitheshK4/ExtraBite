import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import '../../../providers/admin_provider.dart';

class UserManagementTab extends ConsumerStatefulWidget {
  const UserManagementTab({super.key});

  @override
  ConsumerState<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends ConsumerState<UserManagementTab> {
  String _selectedRoleFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetailModal(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                user.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(
                    user.role.displayName,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppColors.outlineVariant),
              const SizedBox(height: 12),
              _buildDetailRow('User ID', user.id, isMonospace: true),
              _buildDetailRow('Email Address', user.email),
              _buildDetailRow('Phone Number', user.phone.isNotEmpty ? user.phone : 'Not Provided'),
              _buildDetailRow('Role', user.role.displayName),
              if (user.propertyName != null)
                _buildDetailRow('Associated Property', user.propertyName!),
              _buildDetailRow(
                'Registration Date',
                DateFormat('MMMM dd, yyyy - hh:mm a').format(user.createdAt),
              ),
              _buildDetailRow(
                'Account Status',
                user.isSuspended ? 'Suspended' : 'Active & Verified',
                statusColor: user.isSuspended ? AppColors.error : AppColors.primary,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
              style: isMonospace
                  ? GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor ?? AppColors.onSurface,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor ?? AppColors.onSurface,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSuspension(UserModel user) async {
    final willSuspend = !user.isSuspended;
    final actionName = willSuspend ? 'Suspend' : 'Activate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionName User Account',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to $actionName the account for "${user.name}" (${user.email})?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willSuspend ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(actionName),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(adminProvider.notifier).toggleUserSuspension(user.id, willSuspend);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account for "${user.name}" successfully updated.'),
            backgroundColor: willSuspend ? AppColors.error : AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final allUsers = adminState.users;

    // Apply Filter
    final filteredUsers = allUsers.where((u) {
      if (_selectedRoleFilter == 'CUSTOMERS' && u.role != UserRole.personal) return false;
      if (_selectedRoleFilter == 'OWNERS' && u.role != UserRole.owner) return false;
      if (_selectedRoleFilter == 'ADMINS' && u.role != UserRole.admin) return false;
      if (_selectedRoleFilter == 'SUSPENDED' && !u.isSuspended) return false;

      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.toLowerCase().trim();
        final name = u.name.toLowerCase();
        final email = u.email.toLowerCase();
        final phone = u.phone.toLowerCase();
        final prop = (u.propertyName ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q) || prop.contains(q);
      }
      return true;
    }).toList();

    final totalCount = allUsers.length;
    final customerCount = allUsers.where((u) => u.role == UserRole.personal).length;
    final ownerCount = allUsers.where((u) => u.role == UserRole.owner).length;
    final suspendedCount = allUsers.where((u) => u.isSuspended).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Page Header & KPI Summary Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inspect, monitor, and manage platform user identities and permissions.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => ref.read(adminProvider.notifier).loadUsers(),
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Refresh Users',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Stats Row
              Row(
                children: [
                  _buildStatPill('Total Users', '$totalCount', AppColors.primary),
                  const SizedBox(width: 12),
                  _buildStatPill('Customers', '$customerCount', AppColors.tertiary),
                  const SizedBox(width: 12),
                  _buildStatPill('PG Owners', '$ownerCount', AppColors.secondary),
                  const SizedBox(width: 12),
                  _buildStatPill('Suspended', '$suspendedCount', AppColors.error),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Filter & Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, phone, or PG property...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterButton('ALL', 'All Users'),
                        _buildFilterButton('CUSTOMERS', 'Customers'),
                        _buildFilterButton('OWNERS', 'PG Owners'),
                        _buildFilterButton('ADMINS', 'Admins'),
                        _buildFilterButton('SUSPENDED', 'Suspended'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. User Data Table
              if (adminState.isLoading && allUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filteredUsers.isEmpty)
                _buildEmptyState()
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.surfaceContainerHigh),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        horizontalMargin: 20,
                        columnSpacing: 28,
                        columns: const [
                          DataColumn(label: Text('USER / IDENTITY')),
                          DataColumn(label: Text('CONTACT')),
                          DataColumn(label: Text('ROLE')),
                          DataColumn(label: Text('PG FACILITY')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('JOINED DATE')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filteredUsers.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primaryContainer,
                                      child: Text(
                                        user.initials,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          user.name,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          user.id.substring(0, user.id.length >= 8 ? 8 : user.id.length),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      user.email,
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      user.phone.isNotEmpty ? user.phone : '—',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(_buildRoleBadge(user.role)),
                              DataCell(
                                Text(
                                  user.propertyName ?? '—',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: user.propertyName != null ? FontWeight.w600 : FontWeight.w400,
                                    color: user.propertyName != null ? AppColors.primary : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(user.isSuspended)),
                              DataCell(
                                Text(
                                  DateFormat('MMM dd, yyyy').format(user.createdAt),
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                                      tooltip: 'View User Details',
                                      onPressed: () => _showUserDetailModal(user),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        user.isSuspended ? Icons.check_circle_outline : Icons.block_outlined,
                                        size: 18,
                                        color: user.isSuspended ? AppColors.success : AppColors.error,
                                      ),
                                      tooltip: user.isSuspended ? 'Activate Account' : 'Suspend Account',
                                      onPressed: () => _toggleSuspension(user),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String key, String label) {
    final isSelected = _selectedRoleFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = key),
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

  Widget _buildRoleBadge(UserRole role) {
    final color = switch (role) {
      UserRole.admin => AppColors.error,
      UserRole.owner => AppColors.secondary,
      UserRole.personal => AppColors.tertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.displayName,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isSuspended) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSuspended ? AppColors.errorContainer : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isSuspended ? 'Suspended' : 'Active',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSuspended ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No users found matching current filter.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
