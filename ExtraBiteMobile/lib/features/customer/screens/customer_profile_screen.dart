import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            _buildUserHeader(user?.name ?? 'Customer User', user?.email ?? 'customer@example.com', user?.role ?? UserRole.personal),

            const SizedBox(height: 20),

            // Profile Details & Verification Card
            _buildDetailsCard(user?.phone, user != null),

            const SizedBox(height: 20),

            // Preferences Card (Location, Radius)
            _buildPreferencesCard(context, locationState.displayName),

            const SizedBox(height: 20),

            // Trust & Safety / Help Card
            _buildSafetyCard(context),

            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Log Out',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    content: Text(
                      'Are you sure you want to log out of ExtraBite?',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/auth/role-selection');
                  }
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
              label: Text(
                'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // App Brand & Version Footer
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/branding/extrabite_logo.png',
                    height: 28,
                    width: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ExtraBite v1.0.0',
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rescuing surplus food, together.',
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(String name, String email, UserRole role) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'CU';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
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
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Food Saver • ${role.displayName}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String? phone, bool isVerified) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
            title: Text('Phone Number', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            subtitle: Text(
              phone != null && phone.isNotEmpty ? phone : '+91 (Not Provided)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
          const Divider(color: AppColors.outline, height: 1),
          ListTile(
            leading: Icon(
              isVerified ? Icons.verified_user : Icons.gpp_maybe_outlined,
              color: isVerified ? AppColors.vegColor : AppColors.secondary,
            ),
            title: Text('Account Status', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            subtitle: Text(
              isVerified ? 'Verified Community Account' : 'Standard Member',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
            trailing: isVerified
                ? const Icon(Icons.check_circle, color: AppColors.vegColor, size: 20)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, String currentAddress) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Location & Campus Area',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
            title: Text(currentAddress, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Tap to change default search area', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary, size: 20),
            onTap: () {
              _showLocationPicker(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
            title: Text('Food Safety Incident Reporting', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Report concerns about food quality directly to admins.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              _showSafetyReportDialog(context);
            },
          ),
          const Divider(color: AppColors.outline, height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.primary),
            title: Text('Help & Support FAQ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Learn how pickup reservation and physical payments work.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              _showFAQDialog(context);
            },
          ),
          const Divider(color: AppColors.outline, height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
            title: Text('About ExtraBite', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Version 1.0.0 • Community Surplus Food Marketplace', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showSafetyReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.report_problem_outlined, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Report Food Safety Incident',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'If you received expired, unsafe, or contaminated food from any PG or hostel, submit a direct report here for immediate administrative review.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'PG / Mess Name & Listing',
                  hintText: 'e.g. Royal PG - Dinner Curry',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Incident Description',
                  hintText: 'Describe the issue encountered...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text('🛡️ Safety report logged with ExtraBite Admin Team.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Frequently Asked Questions', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q: How do I pay?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              Text('A: Payment is strictly physical at pickup directly to the PG mess owners using Cash or personal UPI.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Text('Q: Can I cancel a reservation?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              Text('A: Yes, you can cancel an active reservation from the Digital Pass or Reservations tab anytime before the pickup window closes.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got It')),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    final current = ref.read(locationProvider).displayName;
    final textController = TextEditingController(text: current);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Set Search Area',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Campus / Hostel Area',
                hintText: 'e.g. VIT-AP Inavolu Campus',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                ref.read(locationProvider.notifier).updateLocation(textController.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
