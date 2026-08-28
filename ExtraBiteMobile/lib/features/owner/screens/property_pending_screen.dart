import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class PropertyPendingScreen extends ConsumerStatefulWidget {
  const PropertyPendingScreen({super.key});

  @override
  ConsumerState<PropertyPendingScreen> createState() => _PropertyPendingScreenState();
}

class _PropertyPendingScreenState extends ConsumerState<PropertyPendingScreen> {
  Map<String, dynamic>? _pgProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    final user = ref.read(authProvider).user;
    if (user != null) {
      final repo = ref.read(pgProfileRepositoryProvider);
      final profile = await repo.fetchOwnerPg(user.id);
      if (mounted) {
        setState(() {
          _pgProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isRechecking = authState.status == AuthStatus.profileLoading || _isLoadingProfile;
    final isRejected = _pgProfile?['is_rejected'] as bool? ?? false;
    final rejectionReason = _pgProfile?['rejection_reason'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/branding/extrabite_logo.png',
                      height: 28,
                      width: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ExtraBite',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: isRejected
                        ? AppColors.errorLight
                        : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRejected ? Icons.assignment_late_outlined : Icons.hourglass_top_rounded,
                    size: 48,
                    color: isRejected ? AppColors.error : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                isRejected ? 'Property Registration Needs Updates' : 'Your PG is under review',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (isRejected) ...[
                Text(
                  'Our admin team reviewed your PG property submission and requested revisions before approval.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.feedback_outlined, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Feedback / Reason',
                            style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rejectionReason ?? 'Please update property details or coordinates and resubmit.',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => context.push('/owner/property-registration'),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(
                    'Edit & Resubmit Property',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ] else ...[
                Text(
                  'Your property details have been submitted successfully.\n\nOur admin team will review your PG before you can start listing surplus food.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],

              if (authState.errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRejected ? AppColors.surfaceContainerHigh : AppColors.primary,
                  foregroundColor: isRejected ? AppColors.textPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isRechecking
                    ? null
                    : () async {
                        await _loadProfile();
                        await ref.read(authProvider.notifier).recheckPropertyStatus();
                      },
                icon: isRechecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  isRechecking ? 'Checking…' : 'Check Approval Status',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.outline),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isRechecking
                    ? null
                    : () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
