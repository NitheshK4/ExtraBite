import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/status_badge.dart';

class OwnerReservationsQueueScreen extends ConsumerWidget {
  const OwnerReservationsQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final pgId = user?.pgId ?? 'pg_01';
    final queue = ref.watch(reservationProvider.notifier).getOwnerReservationsQueue(pgId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Reservations Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => context.push('/qr-scanner'),
          ),
        ],
      ),
      body: queue.isEmpty
          ? EmptyStateView(
              icon: Icons.done_all_rounded,
              title: 'Queue is clear!',
              subtitle: 'All customer reservations have been picked up or no active reservations currently.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final item = queue[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            StatusBadge.fromReservationStatus(item.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.listingTitle,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${item.customerName} • ${item.customerPhone}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        Text(
                          'Reserved Portions: ${item.portionsCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Deadline: ${DateTimeUtils.formatTime(item.pickupDeadline)} (${DateTimeUtils.getRemainingTimeLabel(item.pickupDeadline)})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Collect at Pickup: ₹${item.totalAmount.round()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Verify Pickup'),
                              onPressed: () => context.push('/manual-code-verify'),
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
