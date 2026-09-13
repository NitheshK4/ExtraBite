import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/reservation.dart';
import '../../../providers/reservation_provider.dart';

class PickupVerificationModal extends ConsumerStatefulWidget {
  final String ownerPropertyName;

  const PickupVerificationModal({
    super.key,
    required this.ownerPropertyName,
  });

  static Future<void> show(BuildContext context, String ownerPropertyName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PickupVerificationModal(ownerPropertyName: ownerPropertyName),
    );
  }

  @override
  ConsumerState<PickupVerificationModal> createState() => _PickupVerificationModalState();
}

class _PickupVerificationModalState extends ConsumerState<PickupVerificationModal> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _tokenController = TextEditingController();
  Reservation? _verifiedReservation;
  String? _errorMessage;
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _verifyToken(String query) {
    final raw = query.trim().toUpperCase().replaceAll('#', '');
    if (raw.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an order ID or pickup token';
        _verifiedReservation = null;
      });
      return;
    }

    final allReservations = ref.read(reservationProvider);
    final match = allReservations.cast<Reservation?>().firstWhere(
      (r) {
        if (r == null) return false;
        final idMatch = r.id.toUpperCase() == raw || r.id.toUpperCase().endsWith(raw);
        final tokenMatch = r.pickupToken?.toUpperCase() == raw;
        final qrMatch = r.qrPayload?.toUpperCase().contains(raw) ?? false;
        return (idMatch || tokenMatch || qrMatch) && r.status == ReservationStatus.reserved;
      },
      orElse: () => null,
    );

    setState(() {
      if (match != null) {
        _verifiedReservation = match;
        _errorMessage = null;
      } else {
        _verifiedReservation = null;
        _errorMessage = 'No active reservation matching "$query" found for pickup.';
      }
    });
  }

  Future<void> _completePickup(Reservation res) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(reservationProvider.notifier).updateStatus(res.id, 'picked_up');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to update reservation: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Pickup Verification',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'SCAN QR CODE'),
              Tab(icon: Icon(Icons.pin_outlined), text: 'ENTER TOKEN / ID'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScannerTab(),
                _buildManualTokenTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    final activeReservations = ref.watch(reservationProvider).where((r) => r.status == ReservationStatus.reserved).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Scanner Viewfinder Card
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Viewfinder frame
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2, size: 80, color: Colors.white24),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  child: Text(
                    'Point camera at student\'s Digital Pass QR',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (activeReservations.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Verify Active Reservations',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: activeReservations.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.qr_code, color: AppColors.primary),
                      ),
                      title: Text(r.foodName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                        '#${r.id} • ${r.quantity} portion(s) • ₹${r.amountToCollect.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _completePickup(r),
                        child: Text('Verify', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('No active reservations awaiting pickup right now.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualTokenTab() {
    if (_isSuccess && _verifiedReservation != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Pickup Verified & Completed!',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '${_verifiedReservation!.quantity} portion(s) of ${_verifiedReservation!.foodName} collected.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.currency_rupee, color: AppColors.secondary, size: 20),
                  Text(
                    'Collect ₹${_verifiedReservation!.amountToCollect.toStringAsFixed(0)} from Student',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter 6-character pickup token or Order # from student\'s digital pass',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tokenController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Token or Order #',
                    hintText: 'e.g. EB-82910 or TOKEN',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  onSubmitted: _verifyToken,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: () => _verifyToken(_tokenController.text),
                child: const Text('Verify'),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
            ),
          ],
          if (_verifiedReservation != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${_verifiedReservation!.id}',
                        style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text('ACTIVE', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_verifiedReservation!.foodName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Portions: ${_verifiedReservation!.quantity} | Total: ₹${_verifiedReservation!.amountToCollect.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isProcessing ? null : () => _completePickup(_verifiedReservation!),
                      icon: _isProcessing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: Text('Confirm Pickup & Collect Payment', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
