import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/reservation.dart';
import '../../../models/order_type.dart';
import '../../../providers/reservation_provider.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeList = ref.watch(activeReservationsProvider);
    final pastList = ref.watch(pastReservationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Food Bills & Reservations'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'ACTIVE'),
              Tab(text: 'PAST HISTORY'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveTab(context, ref, activeList),
            _buildPastTab(context, pastList),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, WidgetRef ref, List<Reservation> activeList) {
    if (activeList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_outline,
        title: 'No active reservations',
        description: 'Reserved surplus meals will appear here. Find delicious surplus food nearby to start saving!',
      );
    }

    final formatTime = DateFormat('hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeList.length,
      itemBuilder: (context, index) {
        final res = activeList[index];
        final windowStr = '${formatTime.format(res.pickupStarts)} - ${formatTime.format(res.pickupEnds)}';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showInvoiceDetailsSheet(context, res),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top header row: Order ID + Order Type Badge + Status
                  Row(
                    children: [
                      Text(
                        'Order #${res.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildOrderTypeBadge(res.orderType),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Reserved',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Food details
                  Text(
                    res.foodName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    res.propertyName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Key metrics row: Qty + Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quantity', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${res.quantity} portion(s)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Amount Paid', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹${res.amountPaid.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Pickup Info Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup Time Window',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                windowStr,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prepaid Online Callout + View Details indicator
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          '✓ Paid Online (Prepaid) • Tap for QR & Invoice',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button Action
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _showCancelDialog(context, ref, res.id);
                      },
                      child: const Text('Cancel Reservation'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPastTab(BuildContext context, List<Reservation> pastList) {
    if (pastList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No past reservations',
        description: 'Your completed or cancelled reservations will show up here.',
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pastList.length,
      itemBuilder: (context, index) {
        final res = pastList[index];
        final isCompleted = res.status == ReservationStatus.completed;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: () => _showInvoiceDetailsSheet(context, res),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    res.foodName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  '₹${res.amountPaid.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.primary : Colors.grey,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(res.propertyName),
                    const SizedBox(width: 8),
                    _buildOrderTypeBadge(res.orderType),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      dateFormat.format(res.reservedAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    const SizedBox(width: 8),
                    const Text(
                      'Paid Online',
                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? AppColors.primaryLight 
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCompleted ? 'Completed' : 'Cancelled',
                style: TextStyle(
                  color: isCompleted ? AppColors.primary : Colors.red.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderTypeBadge(OrderType? orderType) {
    if (orderType == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: const Text(
          'Legacy',
          style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      );
    }

    final isDineIn = orderType == OrderType.dineIn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDineIn ? Colors.indigo.shade50 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDineIn ? Colors.indigo.shade200 : Colors.teal.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            orderType.icon,
            size: 12,
            color: isDineIn ? Colors.indigo.shade700 : Colors.teal.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            orderType.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDineIn ? Colors.indigo.shade700 : Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetailsSheet(BuildContext context, Reservation res) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prepaid Order Invoice #${res.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            _buildDetailRow('Meal Reserved', res.foodName),
            _buildDetailRow('PG / Hostel', res.propertyName),
            _buildDetailRow(
              'Order Fulfillment',
              res.orderType != null
                  ? '${res.orderType == OrderType.dineIn ? "🍽️" : "🛍️"} ${res.orderType!.displayName}'
                  : 'Legacy / Unspecified',
            ),
            _buildDetailRow('Quantity', '${res.quantity} portion(s)'),
            _buildDetailRow('Amount Paid', '₹${res.amountPaid.toStringAsFixed(0)} (Paid Online)'),
            _buildDetailRow('Payment Mode', res.paymentMethod),
            _buildDetailRow('Payment Status', 'PAID (Pre-paid Online)'),
            _buildDetailRow('Order Date', dateFormat.format(res.reservedAt)),
            _buildDetailRow('Order Status', res.status.name.toUpperCase()),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, size: 64, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    'Pickup Code: ${res.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Show this QR / code to PG staff to verify your prepaid order',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '✓ 100% Pre-paid • Zero Payment on Collection',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: const Text('Are you sure you want to cancel this reservation? Surplus portions are limited and others might need them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              ref.read(reservationProvider.notifier).cancelReservation(id);
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

