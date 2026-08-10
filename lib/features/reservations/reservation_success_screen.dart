import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';

class ReservationSuccessScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationSuccessScreen({
    super.key,
    required this.reservationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservation = ref.watch(reservationProvider.notifier).getReservationById(reservationId);

    if (reservation == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Reservation Confirmed!'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/discover'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Success Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Reservation Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Your meal is held exclusively for you. Present your QR pass at pickup.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Reservation Pass Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reservation ID', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              reservation.readableId,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Pickup Token', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              reservation.pickupToken,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reservation.listingTitle,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${reservation.portionsCount} portion(s) • ${reservation.pgName}',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payable at Pickup:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₹${reservation.totalAmount.round()}',
                          style: const TextStyle(
                            fontSize: 22,
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

              const SizedBox(height: 32),

              // Buttons
              CustomButton(
                label: 'View QR Pickup Pass',
                icon: Icons.qr_code_rounded,
                onPressed: () {
                  context.go('/qr-pass/${reservation.id}');
                },
              ),

              const SizedBox(height: 12),

              CustomButton(
                label: 'Back to Discover',
                isSecondary: true,
                onPressed: () {
                  context.go('/discover');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
