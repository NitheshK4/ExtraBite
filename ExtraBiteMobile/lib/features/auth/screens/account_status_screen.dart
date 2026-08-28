import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

enum AccountStatusType {
  suspended,
  sessionExpired,
  unauthorized,
}

class AccountStatusScreen extends ConsumerWidget {
  final AccountStatusType type;
  final String? referenceCode;

  const AccountStatusScreen({
    super.key,
    this.type = AccountStatusType.suspended,
    this.referenceCode = '#ERR-SEC-8921',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuspended = type == AccountStatusType.suspended;
    final isExpired = type == AccountStatusType.sessionExpired;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            ref.read(authProvider.notifier).logout();
            context.go('/auth/role-selection');
          },
        ),
        centerTitle: true,
        title: Text(
          'Account Security & Status',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // 1. Status Main Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSuspended ? AppColors.error.withOpacity(0.3) : AppColors.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isSuspended ? AppColors.errorLight : AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuspended
                            ? Icons.gpp_bad_outlined
                            : (isExpired ? Icons.lock_clock_outlined : Icons.shield_outlined),
                        size: 44,
                        color: isSuspended ? AppColors.error : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isSuspended
                          ? 'Account Suspended'
                          : (isExpired ? 'Session Expired' : 'Access Restricted'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSuspended ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isSuspended
                          ? 'Your account has been temporarily flagged for a policy review regarding food safety guidelines.'
                          : (isExpired
                              ? 'For your security, your session has timed out. Please sign in again to continue.'
                              : 'You do not have permission to access this resource.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (referenceCode != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'REF: $referenceCode',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (isSuspended) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support request logged. Support email: support@extrabite.in'),
                            ),
                          );
                        } else {
                          ref.read(authProvider.notifier).logout();
                          context.go('/auth/role-selection');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuspended ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSuspended ? 'Contact Safety Support' : 'Sign In Again',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isSuspended) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/auth/role-selection');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Return to Sign In',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Footer Contact Info
              Text(
                'Need urgent assistance? Reach out to safety@extrabite.in',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
