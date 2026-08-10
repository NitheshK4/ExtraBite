import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../models/reservation_model.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';
import '../../shared/widgets/custom_button.dart';

class ReservationDetailScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservation = ref.watch(reservationProvider.notifier).getReservationById(reservationId);

    if (reservation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservation')),
        body: const Center(child: Text('Reservation not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(reservation.readableId),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: StatusBadge.fromReservationStatus(reservation.status)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.pgName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reservation.listingTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Portions reserved: ${reservation.portionsCount}'),
                  Text('Unit price: ₹${reservation.unitPrice.round()}'),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable at Pickup:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Strict Pay at Pickup Banner
            const PayAtPickupBadge(showDescription: true),

            const SizedBox(height: 20),

            // Pickup Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pickup Location & Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text('Address: ${reservation.pgAddress}'),
                  const SizedBox(height: 4),
                  Text('Pickup Deadline: ${DateTimeUtils.formatDateTime(reservation.pickupDeadline)}'),
                  const SizedBox(height: 4),
                  Text('Instructions: ${reservation.pickupInstructions}'),
                  const SizedBox(height: 8),
                  Text('Pickup Token: ${reservation.pickupToken}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            if (reservation.status.isActive && !reservation.isExpired) ...[
              CustomButton(
                label: 'Show QR Pickup Pass',
                icon: Icons.qr_code_rounded,
                onPressed: () => context.push('/qr-pass/${reservation.id}'),
              ),
              const SizedBox(height: 12),
              if (reservation.canCancel)
                CustomButton(
                  label: 'Cancel Reservation',
                  isSecondary: true,
                  textColor: Colors.red,
                  backgroundColor: Colors.red,
                  onPressed: () {
                    _showCancelDialog(context, ref, reservation);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: const Text(
          'Are you sure you want to cancel? Your portion will be returned to the PG\'s available stock for other students and residents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Reservation'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(reservationProvider.notifier).cancelReservation(
                    reservation.id,
                    reason: 'Cancelled by customer',
                  );
              Navigator.pop(ctx);
              Navigator.pop(context); // Return to reservations list
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
