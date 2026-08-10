import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/status_badge.dart';

class ReservationHistoryScreen extends ConsumerWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).currentUser;
    final reservationsNotifier = ref.watch(reservationProvider.notifier);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in.')),
      );
    }

    final historyList = reservationsNotifier.getCustomerReservationHistory(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Pickups & History'),
      ),
      body: historyList.isEmpty
          ? EmptyStateView(
              icon: Icons.history_toggle_off_rounded,
              title: 'No past pickup history',
              subtitle: 'Your completed or cancelled reservations will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final item = historyList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.listingTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge.fromReservationStatus(item.status),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('${item.portionsCount} portion(s) • ${item.pgName}'),
                        const SizedBox(height: 4),
                        Text(
                          'Reserved: ${DateTimeUtils.formatDateTime(item.createdAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (item.cancellationReason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${item.cancellationReason}',
                            style: const TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                    trailing: Text(
                      '₹${item.totalAmount.round()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onTap: () => context.push('/reservation-detail/${item.id}'),
                  ),
                );
              },
            ),
    );
  }
}
