import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/qr_code_dialog.dart';

class CustomerReservationsScreen extends ConsumerWidget {
  const CustomerReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Food Reservations'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: reservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No active food reservations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse nearby surplus meals to reserve your portion.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final res = reservations[index];
                final isPickedUp = res.status == ReservationStatus.pickedUp;
                final isCancelled = res.status == ReservationStatus.cancelled;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPickedUp
                                    ? Colors.blue[50]
                                    : (isCancelled
                                        ? Colors.grey[200]
                                        : Colors.green[50]),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPickedUp
                                      ? Colors.blue
                                      : (isCancelled
                                          ? Colors.grey
                                          : Colors.green),
                                ),
                              ),
                              child: Text(
                                res.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPickedUp
                                      ? Colors.blue[800]
                                      : (isCancelled
                                          ? Colors.grey[700]
                                          : Colors.green[800]),
                                ),
                              ),
                            ),
                            Text(
                              'Passcode: ${res.pickupPasscode}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title & PG
                        Text(
                          res.listingTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${res.pgName} • ${res.portions} Portion(s)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),

                        // Payment & QR Action Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Amount Due at Pickup',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₹${res.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            if (!isPickedUp && !isCancelled)
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        QrCodeDialog(reservation: res),
                                  );
                                },
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Show QR Pass'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
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
