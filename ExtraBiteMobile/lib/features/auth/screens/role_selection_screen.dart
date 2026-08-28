import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final hasSession =
        authState.status == AuthStatus.authenticated ||
        authState.user != null;

    final isLoading = authState.status == AuthStatus.profileLoading ||
        authState.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (!hasSession && context.canPop()) {
              context.pop();
            } else if (!hasSession) {
              context.go('/auth/welcome');
            }
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/extrabite_logo.png',
              height: 24,
              width: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'ExtraBite',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Text(
                hasSession ? 'Choose Your Role' : 'Welcome to ExtraBite',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasSession
                    ? 'Select the role that describes how you will use ExtraBite.'
                    : 'How will you use ExtraBite? Select your role to get started.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Error banner if any
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: GoogleFonts.inter(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Card 1 — Personal User
              _buildRolePathCard(
                context: context,
                ref: ref,
                role: UserRole.personal,
                title: 'Personal User',
                badgeText: 'Students & Residents',
                badgeBgColor: AppColors.primaryLight,
                badgeTextColor: AppColors.primary,
                description: 'Discover affordable surplus meals near you.',
                features: const [
                  'Browse nearby campus mess surplus food',
                  'Reserve portions with massive student savings',
                  'Safe pickup from FSSAI-verified PGs',
                  'Scannable digital QR pickup pass',
                ],
                buttonText: 'Continue as Personal User',
                buttonColor: AppColors.primary,
                borderColor: AppColors.primary.withOpacity(0.35),
                icon: Icons.restaurant,
                iconBgColor: AppColors.primaryLight,
                iconColor: AppColors.primary,
                isLoading: isLoading,
                hasSession: hasSession,
              ),

              const SizedBox(height: 20),

              // Card 2 — Hostel / PG Owner
              _buildRolePathCard(
                context: context,
                ref: ref,
                role: UserRole.owner,
                title: 'Hostel / PG Owner',
                badgeText: 'Hostel & Mess Kitchens',
                badgeBgColor: AppColors.secondaryLight,
                badgeTextColor: AppColors.secondary,
                description: 'Share surplus food from your PG or hostel.',
                features: const [
                  'Publish surplus meals in under 60 seconds',
                  'Live portion stepper management',
                  'Instant incoming student reservations',
                  'Verification badge & sustainability impact',
                ],
                buttonText: 'Continue as PG Owner',
                buttonColor: AppColors.secondary,
                borderColor: AppColors.secondary.withOpacity(0.35),
                icon: Icons.storefront,
                iconBgColor: AppColors.secondaryLight,
                iconColor: AppColors.secondary,
                isLoading: isLoading,
                hasSession: hasSession,
              ),

              const SizedBox(height: 24),

              // Footer Desktop Admin Console Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin or Campus Manager? Access the Admin Operations Console on desktop.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolePathCard({
    required BuildContext context,
    required WidgetRef ref,
    required UserRole role,
    required String title,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String description,
    required List<String> features,
    required String buttonText,
    required Color buttonColor,
    required Color borderColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool isLoading,
    required bool hasSession,
  }) {
    void handleSelect() {
      if (hasSession) {
        ref.read(authProvider.notifier).setUserRole(role);
      } else {
        ref.read(authProvider.notifier).selectRole(role);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLoading ? null : handleSelect,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 14),

                // Features Checklist
                ...features.map(
                  (feat) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: buttonColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Action Button
                ElevatedButton(
                  onPressed: isLoading ? null : handleSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          buttonText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
