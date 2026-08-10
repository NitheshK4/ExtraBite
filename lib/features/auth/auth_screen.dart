import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/custom_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final UserRole initialRole;

  const AuthScreen({
    super.key,
    this.initialRole = UserRole.customer,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  late UserRole _selectedRole;

  // Common Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // PG Owner Specific Controllers
  final TextEditingController _pgNameController = TextEditingController();
  final TextEditingController _fssaiController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Customer Specific: Dietary preferences
  final List<String> _selectedDietaryPreferences = ['Pure Veg'];
  final List<String> _dietaryOptions = [
    'Pure Veg',
    'Non-Veg',
    'High Protein',
    'Vegan',
    'Eggitarian',
    'Jain Friendly',
  ];

  // Admin Specific
  final TextEditingController _adminPinController = TextEditingController(text: '84920');

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _syncFormWithRole(_selectedRole);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pgNameController.dispose();
    _fssaiController.dispose();
    _addressController.dispose();
    _adminPinController.dispose();
    super.dispose();
  }

  void _syncFormWithRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      switch (role) {
        case UserRole.customer:
          _emailController.text = 'alex.customer@extrabite.app';
          _nameController.text = 'Alex Morgan';
          _phoneController.text = '+91 98765 43210';
          break;
        case UserRole.pgOwner:
          _emailController.text = 'rajesh.hostel@extrabite.app';
          _nameController.text = 'Rajesh Sharma';
          _phoneController.text = '+91 91234 56789';
          _pgNameController.text = 'Sri Sai Executive PG & Mess';
          _fssaiController.text = '11220334000124';
          _addressController.text = '14th Main Rd, 4th Block, Koramangala';
          break;
        case UserRole.admin:
          _emailController.text = 'admin.ops@extrabite.app';
          _nameController.text = 'Super Admin';
          _phoneController.text = '+91 99999 00000';
          break;
      }
    });
  }

  void _submit() {
    ref.read(authProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _selectedRole,
        );

    switch (_selectedRole) {
      case UserRole.customer:
        context.go('/discover');
        break;
      case UserRole.pgOwner:
        context.go('/owner-dashboard');
        break;
      case UserRole.admin:
        context.go('/admin-dashboard');
        break;
    }
  }

  Color get _portalColor {
    switch (_selectedRole) {
      case UserRole.customer:
        return AppColors.primary;
      case UserRole.pgOwner:
        return AppColors.secondary;
      case UserRole.admin:
        return Colors.indigo;
    }
  }

  String get _portalTitle {
    switch (_selectedRole) {
      case UserRole.customer:
        return 'Customer & Student Portal';
      case UserRole.pgOwner:
        return 'PG & Hostel Host Portal';
      case UserRole.admin:
        return 'Admin & Operations Portal';
    }
  }

  String get _portalSubtitle {
    switch (_selectedRole) {
      case UserRole.customer:
        return 'Discover discounted surplus meals from top PGs with Pay-at-Pickup.';
      case UserRole.pgOwner:
        return 'List unsold kitchen meals, monetize surplus, and eliminate food waste.';
      case UserRole.admin:
        return 'Authorized platform oversight, PG verification, and system audit logs.';
    }
  }

  IconData get _portalIcon {
    switch (_selectedRole) {
      case UserRole.customer:
        return Icons.lunch_dining_rounded;
      case UserRole.pgOwner:
        return Icons.storefront_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _isSignUp ? 'Create $_portalTitle Account' : _portalTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/role-selection'),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Change Role', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Role Switcher
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildRoleTab(
                    role: UserRole.customer,
                    label: 'Customer',
                    icon: Icons.person_rounded,
                    activeColor: AppColors.primary,
                  ),
                  _buildRoleTab(
                    role: UserRole.pgOwner,
                    label: 'PG Host',
                    icon: Icons.storefront_rounded,
                    activeColor: AppColors.secondary,
                  ),
                  _buildRoleTab(
                    role: UserRole.admin,
                    label: 'Admin',
                    icon: Icons.shield_rounded,
                    activeColor: Colors.indigo,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Portal Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _portalColor.withValues(alpha: 0.14),
                    _portalColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _portalColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _portalColor,
                    child: Icon(_portalIcon, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _portalTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _portalColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _portalSubtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSignUp ? 'Sign Up as ${_selectedRole.displayName}' : 'Sign In to Your Account',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Fields specific to Sign Up
                  if (_isSignUp) ...[
                    // Customer / Host Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _selectedRole == UserRole.pgOwner ? 'Manager / Host Name' : 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role-Specific Sign Up Fields
                    if (_selectedRole == UserRole.pgOwner) ...[
                      TextField(
                        controller: _pgNameController,
                        decoration: const InputDecoration(
                          labelText: 'PG / Hostel Name',
                          prefixIcon: Icon(Icons.apartment_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _fssaiController,
                        decoration: const InputDecoration(
                          labelText: 'FSSAI License / Kitchen Reg. No.',
                          prefixIcon: Icon(Icons.verified_outlined),
                          border: OutlineInputBorder(),
                          helperText: '14-digit FSSAI registration number',
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Kitchen & Dining Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedRole == UserRole.customer) ...[
                      const Text(
                        'Dietary Preferences',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dietaryOptions.map((pref) {
                          final isSelected = _selectedDietaryPreferences.contains(pref);
                          return FilterChip(
                            label: Text(pref),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.18),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDietaryPreferences.add(pref);
                                } else {
                                  _selectedDietaryPreferences.remove(pref);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedRole == UserRole.admin) ...[
                      TextField(
                        controller: _adminPinController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Master Operations Key',
                          prefixIcon: Icon(Icons.key_rounded),
                          border: OutlineInputBorder(),
                          helperText: 'Required for administrative privileges',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // Common Email & Password
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    label: _isSignUp ? 'Create Account & Continue' : 'Sign In as ${_selectedRole.displayName}',
                    backgroundColor: _portalColor,
                    onPressed: _submit,
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already registered? Sign in here'
                            : 'New to ExtraBite? Create a ${_selectedRole.displayName} account',
                        style: TextStyle(color: _portalColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Demo Quick Login Shortcut Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 20, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        '1-Click Demo Login for ${_selectedRole.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedRole == UserRole.customer
                        ? 'Logs in as Alex Morgan (Student) with demo reservations and favorites.'
                        : _selectedRole == UserRole.pgOwner
                            ? 'Logs in as Rajesh Sharma (Hostel Owner) with Sri Sai PG active surplus listings.'
                            : 'Logs in as Super Admin with operational audit logs and approvals dashboard.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text('Instant Demo Login (${_selectedRole.displayName})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _portalColor,
                        side: BorderSide(color: _portalColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _submit,
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

  Widget _buildRoleTab({
    required UserRole role,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _syncFormWithRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
