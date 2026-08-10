import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Signup Controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupPropertyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    _signupPropertyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedRole = authState.selectedRole ?? UserRole.personal;
    final isOwner = selectedRole == UserRole.owner;
    final isLoading = authState.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            ref.read(authProvider.notifier).resetToRoleSelection();
          },
        ),
        title: Text(
          isOwner ? 'Hostel / PG Owner Auth' : 'Personal User Auth',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role Badge Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOwner ? Icons.storefront : Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedRole.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isOwner
                                ? 'Register your PG/Hostel to list surplus food'
                                : 'Sign in to reserve surplus meals near you',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(authProvider.notifier).resetToRoleSelection();
                      },
                      child: const Text('Change', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error banner if any
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Log In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form View
              SizedBox(
                height: isOwner ? 480 : 420,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(isLoading, selectedRole),
                    _buildSignupForm(isLoading, selectedRole, isOwner),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading, UserRole role) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter your email';
              if (!val.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter your password';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (_loginFormKey.currentState!.validate()) {
                      await ref.read(authProvider.notifier).login(
                            email: _loginEmailController.text,
                            password: _loginPasswordController.text,
                          );
                    }
                  },
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Log In as ${role.displayName}'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm(bool isLoading, UserRole role, bool isOwner) {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _signupNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signupEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter your email';
                if (!val.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signupPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your phone number' : null,
            ),
            if (isOwner) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _signupPropertyNameController,
                decoration: const InputDecoration(
                  labelText: 'PG / Hostel / Mess Name',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter your property name' : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _signupPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.length < 4 ? 'Password must be at least 4 chars' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (_signupFormKey.currentState!.validate()) {
                        await ref.read(authProvider.notifier).signup(
                              name: _signupNameController.text,
                              email: _signupEmailController.text,
                              phone: _signupPhoneController.text,
                              password: _signupPasswordController.text,
                              role: role,
                              propertyName: isOwner ? _signupPropertyNameController.text : null,
                            );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Create ${role.displayName} Account'),
            ),
          ],
        ),
      ),
    );
  }
}
