import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../services/qr_service.dart';
import '../../services/audit_service.dart';
import '../../models/reservation_model.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _handleScannedValue(rawValue);
  }

  void _handleScannedValue(String rawValue) {
    setState(() => _isProcessing = true);

    final currentUser = ref.read(authProvider).currentUser;
    final allReservations = ref.read(reservationProvider);
    final ownerPgId = currentUser?.pgId ?? 'pg_01';

    final result = QrService.verifyQrCode(
      rawQrString: rawValue,
      allReservations: allReservations,
      currentOwnerPgId: ownerPgId,
    );

    if (result.isValid && result.reservation != null) {
      _showConfirmationDialog(result.reservation!);
    } else {
      _showErrorDialog(result.status, result.message);
    }
  }

  void _showConfirmationDialog(ReservationModel reservation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.secondary, size: 28),
            SizedBox(width: 8),
            Text('Verify Pickup Pass'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reservation.listingTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Customer: ${reservation.customerName}'),
            Text('Portions: ${reservation.portionsCount}'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Collect at Pickup:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '₹${reservation.totalAmount.round()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const PayAtPickupBadge(isCompact: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () {
              final user = ref.read(authProvider).currentUser;
              ref.read(reservationProvider.notifier).completePickup(reservation.id);

              if (user != null) {
                ref.read(auditProvider.notifier).logEvent(
                      actor: user,
                      action: 'QR_PICKUP_VERIFIED',
                      entityType: 'reservation',
                      entityId: reservation.readableId,
                      details: {
                        'portions': reservation.portionsCount,
                        'amount': reservation.totalAmount,
                        'payment': 'Collected at pickup',
                      },
                    );
              }

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Pickup completed and verified successfully!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
              context.pop();
            },
            child: const Text('Confirm Pickup (Payment Received)'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(QrVerificationStatus status, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Invalid Pickup Pass'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Pickup Pass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dialpad_rounded),
            tooltip: 'Manual Code Entry',
            onPressed: () => context.push('/manual-code-verify'),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Viewfinder Overlay
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          // Instructions at bottom
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Point camera at the customer\'s QR pass',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Remember to collect the Pay at Pickup amount in person.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
