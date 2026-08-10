import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/status_badge.dart';

class ActiveReservationsScreen extends ConsumerWidget {
  const ActiveReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).currentUser;
    final reservationsNotifier = ref.watch(reservationProvider.notifier);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view reservations.')),
      );
    }

    final activeReservations = reservationsNotifier.getCustomerActiveReservations(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Active Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Reservation History',
            onPressed: () => context.push('/reservation-history'),
          ),
        ],
      ),
      body: activeReservations.isEmpty
          ? EmptyStateView(
              icon: Icons.receipt_long_rounded,
              title: 'No active reservations',
              subtitle: 'Discover surplus meals nearby and reserve with Pay at Pickup.',
              actionLabel: 'Discover Food',
              onAction: () => context.go('/discover'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: activeReservations.length,
              itemBuilder: (context, index) {
                final item = activeReservations[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.readableId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            StatusBadge.fromReservationStatus(item.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.listingTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.portionsCount} portion(s) • ${item.pgName}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Pickup by ${DateTimeUtils.formatTime(item.pickupDeadline)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                DateTimeUtils.getRemainingTimeLabel(item.pickupDeadline),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total at pickup', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  '₹${item.totalAmount.round()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_rounded, size: 16),
                              label: const Text('Show QR Pass'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () {
                                context.push('/qr-pass/${item.id}');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
