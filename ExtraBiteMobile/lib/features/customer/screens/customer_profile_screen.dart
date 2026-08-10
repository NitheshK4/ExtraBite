import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Name Card
            _buildProfileCard(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: const Text(
                'PK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pavan Kumar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'pavan.kumar@example.com',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '+91 9876543210',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Vegetarian Mode Only'),
              subtitle: const Text('Show only vegetarian food listings in explorer feed.'),
              activeColor: AppColors.primary,
              value: _isVegPreference,
              onChanged: (val) {
                setState(() {
                  _isVegPreference = val;
                });
              },
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              title: const Text('Food Allergens & Intolerances'),
              subtitle: const Text('Configure custom allergen warnings (e.g. Peanuts, Gluten).'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showAllergenDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Get alerts for ending-soon reservations & hot deals.'),
              activeColor: AppColors.primary,
              value: _enableNotifications,
              onChanged: (val) {
                setState(() {
                  _enableNotifications = val;
                });
              },
            ),
            const Divider(color: AppColors.border, height: 1),
            const ListTile(
              title: Text('Saved Pickup Location'),
              subtitle: Text('Near VIT-AP University Campus'),
              trailing: Icon(Icons.my_location, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
              title: const Text('Food Safety Incident Reporting'),
              subtitle: const Text('Report concerns about food quality or safety issues directly to admins.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showSafetyReportDialog(context);
              },
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text('Help & Support FAQ'),
              subtitle: const Text('Learn how pickup reservation and physical payments work.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showFAQDialog(context);
              },
            ),
            const Divider(color: AppColors.border, height: 1),
            const ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
              title: Text('About ExtraBite'),
              subtitle: Text('Version 1.0.0 (Beta) • Marketplace Foundation'),
            ),
          ],
        ),
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  void _showAllergenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allergen Profile'),
        content: const Text('Mock Allergen configurations will be persisted when backend integrations are live. Standard support covers Peanuts, Gluten, Egg, Soy, and Dairy warnings.'),
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
        title: const Text('Report Safety Concern'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We take food safety extremely seriously.'),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Describe safety or quality issue (e.g. stale food, unhygienic packaging)',
                border: OutlineInputBorder(),
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
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q: How do I pay?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Payment is strictly physical at pickup directly to the property owners using Cash or personal UPI.'),
              SizedBox(height: 12),
              Text('Q: Can I cancel a reservation?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Yes, you can cancel an active reservation from the Reservations tab anytime before the pickup window starts.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got It')),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Mock logout action. Auth flow is not implemented in Stage 1.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
