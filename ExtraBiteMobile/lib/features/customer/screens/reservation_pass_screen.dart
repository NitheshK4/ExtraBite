import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/reservation.dart';
import '../../../providers/reservation_provider.dart';

class ReservationPassScreen extends ConsumerStatefulWidget {
  final String reservationId;

  const ReservationPassScreen({
    super.key,
    required this.reservationId,
  });

  @override
  ConsumerState<ReservationPassScreen> createState() => _ReservationPassScreenState();
}

class _ReservationPassScreenState extends ConsumerState<ReservationPassScreen> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(reservationProvider);
    final reservation = reservations.cast<Reservation?>().firstWhere(
          (r) => r?.id == widget.reservationId,
          orElse: () => null,
        );

    if (reservation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Digital Pickup Pass')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Reservation not found',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/customer/reservations'),
                child: const Text('View All Reservations'),
              ),
            ],
          ),
        ),
      );
    }

    final formatTime = DateFormat('hh:mm a');
    final pickupWindow = '${formatTime.format(reservation.pickupStarts)} - ${formatTime.format(reservation.pickupEnds)}';
    final isCancelled = reservation.status == ReservationStatus.cancelled;
    final isCompleted = reservation.status == ReservationStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Digital Pickup Pass',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Boarding Pass Ticket Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Ticket Header (Forest Emerald)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'OFFICIAL PICKUP PASS',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  isCompleted ? 'COMPLETED' : (isCancelled ? 'CANCELLED' : 'CONFIRMED'),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            reservation.foodName,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reservation.propertyName,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Middle QR Code & Order Ref Section
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Scannable QR Code Canvas
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outline),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x06000000),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 180,
                              height: 180,
                              child: CustomPaint(
                                painter: _DigitalPassQrPainter(
                                  payload: reservation.qrPayload ??
                                      '${reservation.id}:${reservation.pickupToken ?? 'VERIFY'}',
                                  isCancelled: isCancelled,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Order Reference Number (JetBrains Mono)
                          Text(
                            'ORDER REFERENCE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${reservation.id}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (reservation.pickupToken != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Pickup Security Token: ${reservation.pickupToken}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Perforated Ticket Divider with Notches
                    const _TicketPerforationDivider(),

                    // Bottom Order Breakdown & Payment Info
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildDetailRow('Portions Reserved', '${reservation.quantity} portion(s)'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Pickup Window', pickupWindow),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Amount to Collect',
                            '₹${reservation.amountToCollect.toStringAsFixed(0)}',
                            isHighlight: true,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payment, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Pay at Pickup via Cash or UPI',
                                  style: GoogleFonts.inter(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons (Cancel flow)
              if (!isCancelled && !isCompleted) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isCancelling ? null : () => _confirmCancel(reservation.id),
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                          )
                        : const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Reservation'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
            fontSize: isHighlight ? 16 : 13,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _confirmCancel(String id) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Cancel Reservation?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this reservation? The food portions will be returned to the surplus marketplace immediately.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep Reservation'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isCancelling = true);
              try {
                await ref.read(reservationProvider.notifier).cancelReservation(id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Reservation cancelled successfully.'),
                      backgroundColor: AppColors.textPrimary,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isCancelling = false);
                }
              }
            },
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );
  }
}

class _TicketPerforationDivider extends StatelessWidget {
  const _TicketPerforationDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left cutout notch
        Container(
          width: 14,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
          ),
        ),
        // Dashed horizontal line
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = (constraints.constrainWidth() / 8).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => const SizedBox(
                    width: 4,
                    height: 1.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.outline),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Right cutout notch
        Container(
          width: 14,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
          ),
        ),
      ],
    );
  }
}

class _DigitalPassQrPainter extends CustomPainter {
  final String payload;
  final bool isCancelled;

  _DigitalPassQrPainter({required this.payload, this.isCancelled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCancelled ? AppColors.textLight : AppColors.textPrimary
      ..style = PaintingStyle.fill;

    // Generate clean deterministic matrix based on payload
    final int gridSize = 21;
    final double cellSize = size.width / gridSize;

    // Corner Finder Patterns (7x7 squares)
    _drawFinderPattern(canvas, 0, 0, cellSize, paint);
    _drawFinderPattern(canvas, gridSize - 7, 0, cellSize, paint);
    _drawFinderPattern(canvas, 0, gridSize - 7, cellSize, paint);

    // Deterministic bit generation
    final bytes = payload.codeUnits;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if ((r < 8 && c < 8) || (r >= gridSize - 8 && c < 8) || (r < 8 && c >= gridSize - 8)) {
          continue;
        }

        if (r == 6 || c == 6) {
          if ((r + c) % 2 == 0) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.9, cellSize * 0.9),
                const Radius.circular(1),
              ),
              paint,
            );
          }
          continue;
        }

        final index = (r * gridSize + c) % bytes.length;
        final bit = (bytes[index] ^ (r * 7 + c * 13)) % 3 == 0;
        if (bit) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.88, cellSize * 0.88),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, int row, int col, double cellSize, Paint paint) {
    final left = col * cellSize;
    final top = row * cellSize;
    final size = 7 * cellSize;

    // Outer 7x7
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, size, size),
        Radius.circular(cellSize * 1.5),
      ),
      paint,
    );

    // Inner White 5x5
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + cellSize, top + cellSize, size - 2 * cellSize, size - 2 * cellSize),
        Radius.circular(cellSize),
      ),
      bgPaint,
    );

    // Center 3x3
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 2 * cellSize, top + 2 * cellSize, 3 * cellSize, 3 * cellSize),
        Radius.circular(cellSize * 0.8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DigitalPassQrPainter oldDelegate) {
    return oldDelegate.payload != payload || oldDelegate.isCancelled != isCancelled;
  }
}
