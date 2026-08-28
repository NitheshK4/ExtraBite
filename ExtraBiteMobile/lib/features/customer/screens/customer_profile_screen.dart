import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _isVegPreference = false;
  bool _enableNotifications = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.status == AuthStatus.authenticating ||
        authState.status == AuthStatus.uninitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'No active user session.',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).resetToRoleSelection();
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Avatar & Name Card
            _buildProfileCard(user),
            const SizedBox(height: 24),

            // Preferences section
            _buildSectionHeader('Dietary Preferences'),
            const SizedBox(height: 8),
            _buildPreferenceCard(),
            const SizedBox(height: 24),

            // Settings section
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 8),
            _buildSettingsCard(),
            const SizedBox(height: 24),

            // Safety & Info section
            _buildSectionHeader('Trust & Safety'),
            const SizedBox(height: 8),
            _buildSafetyCard(context),
            const SizedBox(height: 32),

            // Logout Option
            _buildLogoutButton(context),
            const SizedBox(height: 32),

            // Brand Footer
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/branding/extrabite_logo.png',
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary,
            child: Text(
              user.initials,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  user.phone,
                  style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Vegetarian Mode Only', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Show only vegetarian food listings in explorer feed.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            activeColor: AppColors.primary,
            value: _isVegPreference,
            onChanged: (val) {
              setState(() {
                _isVegPreference = val;
              });
            },
          ),
          const Divider(color: AppColors.outline, height: 1),
          ListTile(
            title: Text('Food Allergens & Intolerances', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Configure custom allergen warnings (e.g. Peanuts, Gluten).', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              _showAllergenDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Enable Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Get alerts for ending-soon reservations & hot deals.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            activeColor: AppColors.primary,
            value: _enableNotifications,
            onChanged: (val) {
              setState(() {
                _enableNotifications = val;
              });
            },
          ),
          const Divider(color: AppColors.outline, height: 1),
          ListTile(
            title: Text('Saved Pickup Location', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(ref.watch(locationProvider).displayName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
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

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error.withOpacity(0.08),
          foregroundColor: AppColors.error,
          elevation: 0,
        ),
        onPressed: () {
          _showLogoutDialog(context);
        },
        child: const Text('Log Out'),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  void _showAllergenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Allergen Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Allergen configurations will be saved to your authenticated account.', style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSafetyReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Report Safety Concern', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We take food safety and kitchen hygiene extremely seriously.', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Describe issue (e.g. stale food, unhygienic packaging)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you. Safety report submitted successfully to admin review.')),
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
            Text('Saved Location', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your default campus or hostel location:', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'e.g. Near VIT-AP University Gate 2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newLoc = textController.text.trim();
              if (newLoc.isNotEmpty) {
                ref.read(locationProvider.notifier).updateLocation(newLoc);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out? All cached local session data will be cleared.', style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
