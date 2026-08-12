import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/food_provider.dart';
import '../../../providers/reservation_provider.dart';
import '../../../models/food_listing.dart';
import '../../../models/order_type.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final String foodId;

  const FoodDetailScreen({
    super.key,
    required this.foodId,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _portionsToReserve = 1;
  OrderType? _selectedOrderType;
  bool _showOrderTypeValidationError = false;

  @override
  Widget build(BuildContext context) {
    final food = ref.watch(foodDetailProvider(widget.foodId));
    
    if (food == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Surplus food listing not found.')),
      );
    }

    final formatTime = DateFormat('hh:mm a');
    final pickupWindowStr = '${formatTime.format(food.pickupStarts)} - ${formatTime.format(food.pickupEnds)}';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(food.foodName),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image/Icon Banner Area
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Icon(
                        food.isVegetarian ? Icons.eco : Icons.kebab_dining,
                        size: 80,
                        color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Food Title + Veg tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.foodName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                          ),
                        ),
                        child: Text(
                          food.isVegetarian ? 'VEG' : 'NON-VEG',
                          style: TextStyle(
                            color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Pickup Location & Property Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                food.propertyName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                food.locationAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.navigation, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${food.distanceKm.toStringAsFixed(1)} km away',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.restaurant, size: 14, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text(
                              'Prepared ${DateFormat('hh:mm a').format(food.preparedTime)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    food.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Ingredients & Allergens
                  if (food.ingredients.isNotEmpty) ...[
                    const Text(
                      'Ingredients',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: food.ingredients.map((ing) => Chip(
                        label: Text(ing),
                        backgroundColor: Colors.grey.shade50,
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (food.allergens.isNotEmpty) ...[
                    const Text(
                      'Allergen Warnings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: food.allergens.map((all) => Chip(
                        label: Text(all, style: const TextStyle(color: AppColors.error)),
                        backgroundColor: AppColors.error.withOpacity(0.05),
                        side: const BorderSide(color: AppColors.error, width: 0.5),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Pickup Window banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Surplus Food Pickup Window',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pickupWindowStr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
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
          ),
          
          // Sticky Bottom Reservation Panel
          _buildReservationPanel(context, food),
        ],
      ),
    );
  }

  Widget _buildReservationPanel(BuildContext context, FoodListing food) {
    final available = food.availablePortions;
    final isSoldOut = available <= 0;

    // Dynamically clamp portion count to match availability
    int displayPortions = _portionsToReserve;
    if (isSoldOut) {
      displayPortions = 0;
    } else if (displayPortions > available) {
      displayPortions = available;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Order Option Selection (Dine In vs Take Away)
          Row(
            children: [
              const Text(
                'Select Order Option *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (_showOrderTypeValidationError && _selectedOrderType == null)
                const Text(
                  '(Selection Required)',
                  style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOrderTypeChoiceCard(
                  type: OrderType.dineIn,
                  label: 'Dine In',
                  sublabel: 'Eat at PG Mess',
                  icon: Icons.restaurant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderTypeChoiceCard(
                  type: OrderType.takeAway,
                  label: 'Take Away',
                  sublabel: 'Packed Parcel',
                  icon: Icons.takeout_dining,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quantity selection row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Portions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: !isSoldOut && _portionsToReserve > 1
                        ? () => setState(() => _portionsToReserve--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$displayPortions',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: !isSoldOut && _portionsToReserve < available
                        ? () => setState(() => _portionsToReserve++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Price + CTA Row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Price', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '₹${(food.sellingPrice * displayPortions).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: food.isExpired || isSoldOut
                      ? null
                      : () {
                          _triggerReservation(context, food);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    food.isExpired
                        ? 'Pickup Expired'
                        : (isSoldOut
                            ? 'Sold Out'
                            : (_selectedOrderType == null
                                ? 'Select Order Option'
                                : 'Pay ₹${(food.sellingPrice * displayPortions).toStringAsFixed(0)} Online & Reserve')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeChoiceCard({
    required OrderType type,
    required String label,
    required String sublabel,
    required IconData icon,
  }) {
    final isSelected = _selectedOrderType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedOrderType = type;
          _showOrderTypeValidationError = false;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (_showOrderTypeValidationError ? AppColors.error : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? AppColors.primary.withOpacity(0.8) : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _triggerReservation(BuildContext context, FoodListing food) {
    // MANDATORY VALIDATION: Check if OrderType (Dine In / Take Away) is selected
    if (_selectedOrderType == null) {
      setState(() {
        _showOrderTypeValidationError = true;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please select Dine In or Take Away before completing your pre-payment.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final available = food.availablePortions;
    if (available <= 0) return; // Prevent zero-portions reservation

    int portions = _portionsToReserve;
    if (portions > available) {
      portions = available;
    }
    if (portions <= 0) return;

    _showOnlinePaymentSheet(context, food, portions, _selectedOrderType!);
  }

  void _showOnlinePaymentSheet(
    BuildContext context,
    FoodListing food,
    int portions,
    OrderType orderType,
  ) {
    String selectedPaymentMethod = 'UPI (Google Pay / PhonePe / Paytm)';
    final totalPayable = food.sellingPrice * portions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Online Pre-Payment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Prepaid Only Notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '100% Pre-paid Online • Zero Payment on Pickup',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bill Breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Surplus Item', food.foodName),
                          _buildPriceRow('Order Option', '${orderType == OrderType.dineIn ? "🍽️" : "🛍️"} ${orderType.displayName}'),
                          _buildPriceRow('Portions', '$portions portion(s) × ₹${food.sellingPrice.toStringAsFixed(0)}'),
                          _buildPriceRow('Platform & Pickup Fee', 'FREE (₹0)', isFree: true),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Payable Amount',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '₹${totalPayable.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Selection
                    const Text(
                      'Select Payment Platform',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildPaymentOptionTile(
                      title: 'UPI (GPay / PhonePe / Paytm / BHIM)',
                      subtitle: 'Instant pre-payment via any UPI app or ID',
                      icon: Icons.qr_code_scanner,
                      value: 'UPI (Google Pay / PhonePe / Paytm)',
                      groupValue: selectedPaymentMethod,
                      onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                    ),
                    _buildPaymentOptionTile(
                      title: 'Credit / Debit Cards',
                      subtitle: 'Visa, MasterCard, RuPay & Maestro',
                      icon: Icons.credit_card,
                      value: 'Credit / Debit Card',
                      groupValue: selectedPaymentMethod,
                      onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                    ),
                    _buildPaymentOptionTile(
                      title: 'Net Banking',
                      subtitle: 'All major Indian banks supported',
                      icon: Icons.account_balance,
                      value: 'Net Banking',
                      groupValue: selectedPaymentMethod,
                      onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                    ),
                    _buildPaymentOptionTile(
                      title: 'Digital Wallets',
                      subtitle: 'Paytm, Amazon Pay & PhonePe Wallet',
                      icon: Icons.account_balance_wallet_outlined,
                      value: 'Digital Wallet',
                      groupValue: selectedPaymentMethod,
                      onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                    ),

                    const SizedBox(height: 16),

                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(bottomSheetContext); // Close sheet
                          _processOnlinePaymentAndReserve(
                            context,
                            food,
                            portions,
                            orderType,
                            selectedPaymentMethod,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${totalPayable.toStringAsFixed(0)} Securely Online',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        '🔒 256-Bit SSL Encrypted Online Payment',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isFree ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _processOnlinePaymentAndReserve(
    BuildContext context,
    FoodListing food,
    int portions,
    OrderType orderType,
    String paymentMethod,
  ) {
    // Decrement available portions in real-time
    ref.read(foodProvider.notifier).decrementPortions(food.id, portions);

    // Call state notifier to add pre-paid reservation state
    final reservation = ref.read(reservationProvider.notifier).createReservation(
      listing: food,
      quantity: portions,
      orderType: orderType,
      paymentMethod: paymentMethod,
    );

    // Show Confirmed Pre-paid Reservation Modal / Invoice
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Payment & Reservation Confirmed')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your online pre-payment was successful and surplus meal has been reserved! Present your pickup QR / confirmation code at the property to collect your meal.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDialogRow('Order Reference', '#${reservation.id}'),
            _buildDialogRow('Reserved Item', reservation.foodName),
            _buildDialogRow('Order Type', '${reservation.orderType == OrderType.dineIn ? "🍽️" : "🛍️"} ${reservation.orderTypeDisplayName}'),
            _buildDialogRow('Quantity', '${reservation.quantity} portion(s)'),
            _buildDialogRow('Amount Paid', '₹${reservation.amountPaid.toStringAsFixed(0)} (Paid Online)'),
            _buildDialogRow('Payment Mode', reservation.paymentMethod),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    '✓ Pre-paid Online (Zero Payment on Pickup)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/customer/reservations'); // Navigate to active list
            },
            child: const Text('View Active Reservations & QR'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

