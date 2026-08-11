import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/food_listing.dart';
import '../../../models/reservation.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/food_provider.dart';
import '../../../providers/reservation_provider.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final foodState = ref.watch(foodProvider);
    final allReservations = ref.watch(reservationProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ownerPropName = (user.propertyName ?? user.name).toLowerCase();
    final ownerListings = foodState.listings.where(
      (listing) => listing.propertyName.toLowerCase() == ownerPropName || listing.propertyId == user.id,
    ).toList();

    final pendingPickups = allReservations.where(
      (r) => (r.propertyName.toLowerCase() == ownerPropName || ownerListings.any((l) => l.id == r.foodListingId)) &&
          r.status == ReservationStatus.reserved,
    ).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.propertyName ?? 'Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.propertyName ?? 'PG / Hostel Manager',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Metrics Summary
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Listings',
                    value: '${ownerListings.length}',
                    icon: Icons.fastfood_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pending Pickups',
                    value: '$pendingPickups',
                    icon: Icons.qr_code_scanner,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Listing Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Food Listings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddMealSheet(context, ref, user),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Meal'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (ownerListings.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        const Text(
                          'No surplus meals listed yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Click "+ Add Meal" above to post fresh surplus food for nearby students and residents.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddMealSheet(context, ref, user),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add First Meal'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ownerListings.length,
                itemBuilder: (context, index) {
                  final item = ownerListings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: item.isVegetarian
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: item.isVegetarian ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.foodName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '₹${item.sellingPrice.toInt()}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '₹${item.originalPrice.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textLight,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.primary),
                                    tooltip: 'Decrease portion',
                                    onPressed: item.availablePortions > 0
                                        ? () {
                                            ref.read(foodProvider.notifier).decrementPortions(item.id, 1);
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '${item.availablePortions} left',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                    tooltip: 'Increase portion',
                                    onPressed: () {
                                      ref.read(foodProvider.notifier).decrementPortions(item.id, -1);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                    tooltip: 'Delete listing',
                                    onPressed: () {
                                      ref.read(foodProvider.notifier).removeListing(item.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Removed "${item.foodName}".')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),

            // Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out Owner Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMealSheet(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMealBottomSheet(user: user, ref: ref),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out? All cached owner session data will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _AddMealBottomSheet extends StatefulWidget {
  final UserModel user;
  final WidgetRef ref;

  const _AddMealBottomSheet({required this.user, required this.ref});

  @override
  State<_AddMealBottomSheet> createState() => _AddMealBottomSheetState();
}

class _AddMealBottomSheetState extends State<_AddMealBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _portionsController = TextEditingController(text: '5');

  String _category = 'Dinner';
  bool _isVeg = true;
  int _pickupHours = 2;

  final _categories = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _portionsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final origPrice = double.tryParse(_originalPriceController.text) ?? 100.0;
      final sellPrice = double.tryParse(_sellingPriceController.text) ?? (origPrice / 2);
      final portions = int.tryParse(_portionsController.text) ?? 5;
      final foodName = _nameController.text.trim();
      final desc = _descriptionController.text.trim();

      final newListing = FoodListing(
        id: 'fl_${now.millisecondsSinceEpoch}',
        foodName: foodName,
        description: desc.isNotEmpty
            ? desc
            : 'Fresh surplus $_category meal prepared at ${widget.user.propertyName ?? widget.user.name}.',
        propertyId: widget.user.id,
        propertyName: widget.user.propertyName ?? widget.user.name,
        distanceKm: 0.8,
        category: _category,
        isVegetarian: _isVeg,
        originalPrice: origPrice,
        sellingPrice: sellPrice,
        availablePortions: portions,
        preparedTime: now.subtract(const Duration(minutes: 30)),
        pickupStarts: now,
        pickupEnds: now.add(Duration(hours: _pickupHours)),
        ingredients: _isVeg ? ['Rice', 'Vegetables', 'Spices'] : ['Basmati Rice', 'Chicken', 'Spices'],
        allergens: const [],
        verificationStatus: 'verified',
      );

      widget.ref.read(foodProvider.notifier).addListing(newListing);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('🎉 "$foodName" listed live! Available for customer reservations.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Post Surplus Meal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Food Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Name *',
                  hintText: 'e.g. Chicken Rice, Veg Thali, Idli Sambar',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter meal name' : null,
              ),
              const SizedBox(height: 12),

              // Category & Veg Switch
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text(_isVeg ? '🌱 Veg' : '🍗 Non-Veg'),
                    selected: true,
                    selectedColor: _isVeg ? Colors.green.shade100 : Colors.red.shade100,
                    onSelected: (_) {
                      setState(() => _isVeg = !_isVeg);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Prices & Portions
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Original ₹ *',
                        hintText: '100',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Surplus ₹ *',
                        hintText: '50',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _portionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Portions *',
                        hintText: '8',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Portions count' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pickup Window Hours
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pickup available for next:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 hr')),
                      ButtonSegment(value: 2, label: Text('2 hrs')),
                      ButtonSegment(value: 3, label: Text('3 hrs')),
                    ],
                    selected: {_pickupHours},
                    onSelectionChanged: (set) => setState(() => _pickupHours = set.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description / Notes (Optional)',
                  hintText: 'e.g. Includes sambar, chutney, freshly made.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Post Meal Live for Students', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

