import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/reservation_model.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';

class ManualCodeVerificationScreen extends ConsumerStatefulWidget {
  const ManualCodeVerificationScreen({super.key});

  @override
  ConsumerState<ManualCodeVerificationScreen> createState() => _ManualCodeVerificationScreenState();
}

class _ManualCodeVerificationScreenState extends ConsumerState<ManualCodeVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  ReservationModel? _matchedReservation;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _searchCode() {
    final query = _codeController.text.trim().toUpperCase();
    if (query.isEmpty) return;

    final currentUser = ref.read(authProvider).currentUser;
    final ownerPgId = currentUser?.pgId ?? 'pg_01';
    final allReservations = ref.read(reservationProvider);

    ReservationModel? match;
    try {
      match = allReservations.firstWhere(
        (r) =>
            r.pgId == ownerPgId &&
            (r.readableId.toUpperCase() == query || r.pickupToken.toUpperCase() == query),
      );
    } catch (_) {
      match = null;
    }

    setState(() {
      if (match == null) {
        _matchedReservation = null;
        _errorMessage = 'No reservation found matching "$query" for your PG.';
      } else if (match.status == ReservationStatus.pickedUp) {
        _matchedReservation = null;
        _errorMessage = 'This reservation (${match.readableId}) was already picked up.';
      } else if (match.status == ReservationStatus.cancelled) {
        _matchedReservation = null;
        _errorMessage = 'This reservation was cancelled by the customer.';
      } else {
        _matchedReservation = match;
        _errorMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Pickup Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Pickup Token or Reservation ID',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask the customer for their 4-digit token (e.g. TOK-9812) or reservation ID (e.g. EB-84921).',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. TOK-9812 or EB-84921',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.pin_rounded),
                    ),
                    onSubmitted: (_) => _searchCode(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _searchCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Text('Find'),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_matchedReservation != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _matchedReservation!.readableId,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _matchedReservation!.pickupToken,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _matchedReservation!.listingTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Customer: ${_matchedReservation!.customerName} (${_matchedReservation!.customerPhone})'),
                    Text('Quantity: ${_matchedReservation!.portionsCount} portion(s)'),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount to Collect:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '₹${_matchedReservation!.totalAmount.round()}',
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
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Confirm Pickup & Payment Received',
                      backgroundColor: AppColors.secondary,
                      onPressed: () {
                        ref.read(reservationProvider.notifier).completePickup(_matchedReservation!.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Pickup verified and completed!'),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                        context.pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
