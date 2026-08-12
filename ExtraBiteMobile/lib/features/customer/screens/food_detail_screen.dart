import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

    // If listing does not allow Dine In, enforce Take Away selection
    if (!food.allowsDineIn && _selectedOrderType == OrderType.dineIn) {
      _selectedOrderType = OrderType.takeAway;
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
                  const SizedBox(height: 12),

                  // Dining Option Information Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: food.allowsDineIn ? Colors.teal.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: food.allowsDineIn ? Colors.teal.shade200 : Colors.amber.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          food.allowsDineIn ? Icons.restaurant : Icons.takeout_dining,
                          color: food.allowsDineIn ? Colors.teal.shade800 : Colors.deepOrange.shade800,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.allowsDineIn ? '🍽️ Dine-in & Takeaway Available' : '🛍️ Takeaway / Parcel Only',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: food.allowsDineIn ? Colors.teal.shade900 : Colors.deepOrange.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                food.allowsDineIn
                                    ? 'Students can sit and eat inside ${food.propertyName} mess, or take packed parcels.'
                                    : '${food.propertyName} does not offer dine-in seating. Only takeaway parcels are allowed.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: food.allowsDineIn ? Colors.teal.shade800 : Colors.deepOrange.shade800,
                                ),
                              ),
                            ],
                          ),
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
                  sublabel: food.allowsDineIn ? 'Eat at PG Mess' : 'Not Allowed by PG',
                  icon: Icons.restaurant,
                  isEnabled: food.allowsDineIn,
                  disabledReason: '${food.propertyName} only allows Takeaway parcels.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderTypeChoiceCard(
                  type: OrderType.takeAway,
                  label: 'Take Away',
                  sublabel: 'Packed Parcel',
                  icon: Icons.takeout_dining,
                  isEnabled: true,
                ),
              ),
            ],
          ),
          if (!food.allowsDineIn) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.deepOrange.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Notice: Dine-in not available at ${food.propertyName}. Parcel pickup only.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepOrange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    bool isEnabled = true,
    String? disabledReason,
  }) {
    final isSelected = _selectedOrderType == type;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: isEnabled
            ? () {
                setState(() {
                  _selectedOrderType = type;
                  _showOrderTypeValidationError = false;
                });
              }
            : () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.deepOrange.shade800,
                    behavior: SnackBarBehavior.floating,
                    content: Text(disabledReason ?? 'This option is not offered for this meal.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : (isEnabled ? Colors.grey.shade50 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (_showOrderTypeValidationError ? AppColors.error : AppColors.border),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isEnabled ? AppColors.textSecondary : Colors.grey.shade400),
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
                        color: isSelected
                            ? AppColors.primary
                            : (isEnabled ? AppColors.textPrimary : Colors.grey.shade500),
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.8)
                            : (isEnabled ? AppColors.textLight : Colors.red.shade400),
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
                )
              else if (!isEnabled)
                Icon(
                  Icons.block,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
            ],
          ),
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
    final totalPayable = food.sellingPrice * portions;
    String selectedPaymentMethod = 'Paytm UPI';
    bool isUpiInitiated = false;
    bool appLaunched = false;
    String txnRef = 'SAVOURE_${DateTime.now().millisecondsSinceEpoch}';
    Uri? retryUri;

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
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: !isUpiInitiated
                    ? Column(
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
                                    'Pay using UPI App',
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
                                    '100% Pre-paid via UPI App • Zero Payment on Pickup',
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
                                _buildPriceRow('UPI Platform & Pickup Fee', 'FREE (₹0)', isFree: true),
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

                          // UPI App Selection
                          const Text(
                            'Select Installed UPI App',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          _buildUpiOptionTile(
                            title: 'Paytm UPI',
                            subtitle: 'Direct redirect to Paytm app for 1-click payment',
                            icon: Icons.account_balance_wallet,
                            iconColor: const Color(0xFF002E6E),
                            value: 'Paytm UPI',
                            groupValue: selectedPaymentMethod,
                            onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                          ),
                          _buildUpiOptionTile(
                            title: 'Google Pay (GPay)',
                            subtitle: 'Fast UPI payment via Google Pay app',
                            icon: Icons.payment,
                            iconColor: const Color(0xFF1A73E8),
                            value: 'Google Pay UPI',
                            groupValue: selectedPaymentMethod,
                            onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                          ),
                          _buildUpiOptionTile(
                            title: 'PhonePe',
                            subtitle: 'Pay directly inside PhonePe app',
                            icon: Icons.smartphone,
                            iconColor: const Color(0xFF5F259F),
                            value: 'PhonePe UPI',
                            groupValue: selectedPaymentMethod,
                            onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                          ),
                          _buildUpiOptionTile(
                            title: 'BHIM / Any UPI App',
                            subtitle: 'Open UPI app chooser (CRED, Navi, Amazon Pay, etc.)',
                            icon: Icons.qr_code_scanner,
                            iconColor: const Color(0xFFE65100),
                            value: 'BHIM / Other UPI',
                            groupValue: selectedPaymentMethod,
                            onChanged: (val) => setModalState(() => selectedPaymentMethod = val!),
                          ),
                          _buildUpiOptionTile(
                            title: 'Scan UPI QR / VPA ID',
                            subtitle: 'Pay to savoure.food@icici with any app',
                            icon: Icons.qr_code_2,
                            iconColor: AppColors.primary,
                            value: 'UPI QR Code',
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
                                final payeeVpa = 'savoure.food@icici';
                                final payeeName = 'SavourE Foods';
                                final txnNote = 'Prepaid Meal ${food.foodName}';
                                final amountStr = totalPayable.toStringAsFixed(2);
                                txnRef = 'SAVOURE_${DateTime.now().millisecondsSinceEpoch}';

                                final standardUpiUri = Uri.parse(
                                  'upi://pay?pa=$payeeVpa&pn=${Uri.encodeComponent(payeeName)}&tn=${Uri.encodeComponent(txnNote)}&am=$amountStr&cu=INR&tr=$txnRef',
                                );

                                Uri targetUri = standardUpiUri;
                                if (selectedPaymentMethod.contains('Paytm')) {
                                  targetUri = Uri.parse(
                                    'paytmmp://pay?pa=$payeeVpa&pn=${Uri.encodeComponent(payeeName)}&tn=${Uri.encodeComponent(txnNote)}&am=$amountStr&cu=INR&tr=$txnRef',
                                  );
                                } else if (selectedPaymentMethod.contains('PhonePe')) {
                                  targetUri = Uri.parse(
                                    'phonepe://pay?pa=$payeeVpa&pn=${Uri.encodeComponent(payeeName)}&tn=${Uri.encodeComponent(txnNote)}&am=$amountStr&cu=INR&tr=$txnRef',
                                  );
                                } else if (selectedPaymentMethod.contains('Google Pay')) {
                                  targetUri = Uri.parse(
                                    'gpay://upi/pay?pa=$payeeVpa&pn=${Uri.encodeComponent(payeeName)}&tn=${Uri.encodeComponent(txnNote)}&am=$amountStr&cu=INR&tr=$txnRef',
                                  );
                                }

                                retryUri = targetUri;

                                setModalState(() {
                                  isUpiInitiated = true;
                                  appLaunched = false;
                                });

                                // Launch UPI app deep link intent asynchronously
                                launchUrl(targetUri, mode: LaunchMode.externalApplication).then((launched) {
                                  setModalState(() {
                                    appLaunched = launched;
                                  });
                                }).catchError((_) {
                                  launchUrl(standardUpiUri, mode: LaunchMode.externalApplication).then((launched) {
                                    setModalState(() {
                                      appLaunched = launched;
                                    });
                                  }).catchError((_) {});
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.touch_app, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pay ₹${totalPayable.toStringAsFixed(0)} via $selectedPaymentMethod',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              '🔒 Instant NPCI UPI Intent Redirection • Zero Extra Charges',
                              style: TextStyle(fontSize: 11, color: AppColors.textLight),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Modal Header with Back to selection option
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                tooltip: 'Change Payment App',
                                onPressed: () => setModalState(() => isUpiInitiated = false),
                              ),
                              const Text(
                                'UPI Payment Verification',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(bottomSheetContext),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Top Indicator & Status Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: appLaunched ? AppColors.primaryLight : Colors.amber.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: appLaunched
                                  ? const CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)
                                  : Icon(Icons.qr_code_2, size: 36, color: Colors.amber.shade800),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            appLaunched
                                ? 'Waiting for payment in $selectedPaymentMethod...'
                                : 'Complete UPI Payment',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          Text(
                            appLaunched
                                ? 'Please complete your ₹${totalPayable.toStringAsFixed(0)} payment in the $selectedPaymentMethod app. Once done, click the button below to confirm your meal.'
                                : 'Scan QR or pay using SavourE UPI ID in your favorite UPI app, then click below to confirm your meal reservation.',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Transaction Details Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Amount Payable', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Payee UPI ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    Row(
                                      children: [
                                        const Text(
                                          'savoure.food@icici',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(const ClipboardData(text: 'savoure.food@icici'));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('SavourE UPI ID copied to clipboard!'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Transaction Ref', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    Text(
                                      txnRef,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Meal / Item', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${food.foodName} ($portions portion)',
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Confirm / Verify Button
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
                                  '$selectedPaymentMethod (Prepaid)',
                                  txnRef,
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'I Have Paid • Verify & Confirm Order',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Re-open UPI App Button
                          if (retryUri != null && appLaunched)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                                onPressed: () => launchUrl(retryUri!, mode: LaunchMode.externalApplication),
                                child: Text(
                                  'Re-open $selectedPaymentMethod',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),

                          // Cancel Button
                          TextButton(
                            onPressed: () => Navigator.pop(bottomSheetContext),
                            child: const Text(
                              'Cancel Payment',
                              style: TextStyle(color: AppColors.textSecondary),
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

  Widget _buildUpiOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
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
    String txnRef,
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your UPI pre-payment was verified and surplus meal has been reserved! Present your pickup QR / confirmation code at the property to collect your meal.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildDialogRow('Order Reference', '#${reservation.id}'),
              _buildDialogRow('UPI Txn ID', txnRef),
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
                    Expanded(
                      child: Text(
                        '✓ Pre-paid Online (Zero Payment on Pickup)',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}


