import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${item.locationAddress} (${item.distanceKm.toStringAsFixed(1)} km)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
  final _locationController = TextEditingController(text: 'Near VIT-AP University Gate 2');
  final _latController = TextEditingController(text: '16.4950');
  final _lngController = TextEditingController(text: '80.5000');
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _portionsController = TextEditingController(text: '5');

  String _category = 'Dinner';
  bool _isVeg = true;
  int _pickupHours = 2;
  bool _isAcquiringGps = false;
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _filteredSuggestions = [];

  // Popular and preset locations with exact verified coordinates
  final List<Map<String, dynamic>> _allLocations = [
    {
      'title': 'Near VIT-AP University Gate 2',
      'subtitle': 'Inavolu, Amaravati, AP',
      'lat': 16.4950,
      'lng': 80.5000,
      'tag': 'VIT-AP',
    },
    {
      'title': 'Near VIT-AP Main Campus & Hostels',
      'subtitle': 'Beside Academic Block, Amaravati',
      'lat': 16.4975,
      'lng': 80.5025,
      'tag': 'VIT-AP',
    },
    {
      'title': 'Near SRM University-AP Campus',
      'subtitle': 'Neerukonda, Mangalagiri, AP',
      'lat': 16.4682,
      'lng': 80.5085,
      'tag': 'SRM-AP',
    },
    {
      'title': 'Inavolu Village Center',
      'subtitle': 'Amaravati Capital Region',
      'lat': 16.4920,
      'lng': 80.4950,
      'tag': 'Inavolu',
    },
    {
      'title': 'Thullur Bus Station & Market',
      'subtitle': 'Thullur, Amaravati',
      'lat': 16.5350,
      'lng': 80.4850,
      'tag': 'Thullur',
    },
    {
      'title': 'Mangalagiri Highway Junction',
      'subtitle': 'Near Main Road, Mangalagiri',
      'lat': 16.4350,
      'lng': 80.5600,
      'tag': 'Mangalagiri',
    },
    {
      'title': 'Vijayawada Benz Circle Area',
      'subtitle': 'MG Road, Vijayawada',
      'lat': 16.5062,
      'lng': 80.6480,
      'tag': 'Vijayawada',
    },
    {
      'title': 'KL University / Vaddeswaram Area',
      'subtitle': 'Green Fields, Tadepalli',
      'lat': 16.4440,
      'lng': 80.6210,
      'tag': 'KLU',
    },
  ];

  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = List.from(_allLocations);
    _locationController.addListener(_onLocationInputChanged);
  }

  void _onLocationInputChanged() {
    final query = _locationController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = List.from(_allLocations);
      });
      return;
    }

    final matched = _allLocations.where((loc) {
      final title = (loc['title'] as String).toLowerCase();
      final sub = (loc['subtitle'] as String).toLowerCase();
      final tag = (loc['tag'] as String).toLowerCase();
      return title.contains(query) || sub.contains(query) || tag.contains(query);
    }).toList();

    setState(() {
      _filteredSuggestions = matched;
    });

    // Try forward geocoding in background if query is descriptive
    _attemptForwardGeocoding(query);
  }

  Future<void> _attemptForwardGeocoding(String address) async {
    if (address.length < 4) return;
    try {
      final locations = await locationFromAddress(address).timeout(
        const Duration(seconds: 2),
        onTimeout: () => <Location>[],
      );
      if (locations.isNotEmpty && mounted) {
        final first = locations.first;
        _latController.text = first.latitude.toStringAsFixed(6);
        _lngController.text = first.longitude.toStringAsFixed(6);
      }
    } catch (_) {}
  }

  void _selectLocationPreset(Map<String, dynamic> loc) {
    setState(() {
      _locationController.text = loc['title'] as String;
      _latController.text = (loc['lat'] as double).toStringAsFixed(6);
      _lngController.text = (loc['lng'] as double).toStringAsFixed(6);
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationInputChanged);
    _nameController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _portionsController.dispose();
    super.dispose();
  }

  Future<void> _fetchOwnerGPSLocation() async {
    setState(() => _isAcquiringGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (!serviceEnabled) {
        // Fallback to default coordinates or last known
        _latController.text = '16.495000';
        _lngController.text = '80.500000';
        _locationController.text = 'Near VIT-AP University (Default GPS Anchor)';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Location services disabled. Set to Near VIT-AP University anchor.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
        onTimeout: () => LocationPermission.denied,
      );
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 3),
          onTimeout: () => LocationPermission.denied,
        );
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      final lat = pos?.latitude ?? 16.4950;
      final lng = pos?.longitude ?? 80.5000;

      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);

      // Attempt reverse geocoding
      String resolvedName = 'Near Current PG Location, Amaravati';
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng).timeout(
          const Duration(seconds: 2),
          onTimeout: () => <Placemark>[],
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final name = p.name ?? p.subLocality ?? p.locality ?? 'PG Location';
          resolvedName = 'Near $name, ${p.locality ?? 'Amaravati'}';
        }
      } catch (_) {}

      _locationController.text = resolvedName;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 GPS location locked: $resolvedName'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      _latController.text = '16.495000';
      _lngController.text = '80.500000';
      _locationController.text = 'Near VIT-AP University Gate 2';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 GPS locked to Near VIT-AP University anchor.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAcquiringGps = false);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final origPrice = double.tryParse(_originalPriceController.text) ?? 100.0;
      final sellPrice = double.tryParse(_sellingPriceController.text) ?? (origPrice / 2);
      final portions = int.tryParse(_portionsController.text) ?? 5;
      final foodName = _nameController.text.trim();
      final location = _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'Near VIT-AP University';
      final lat = double.tryParse(_latController.text) ?? 16.4950;
      final lng = double.tryParse(_lngController.text) ?? 80.5000;
      final desc = _descriptionController.text.trim();

      final newListing = FoodListing(
        id: 'fl_${now.millisecondsSinceEpoch}',
        foodName: foodName,
        description: desc.isNotEmpty
            ? desc
            : 'Fresh surplus $_category meal prepared at ${widget.user.propertyName ?? widget.user.name}.',
        propertyId: widget.user.id,
        propertyName: widget.user.propertyName ?? widget.user.name,
        locationAddress: location,
        latitude: lat,
        longitude: lng,
        distanceKm: 0.5,
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
          content: Text('🎉 "$foodName" listed live! Visible to customers within radius.'),
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
                  hintText: 'e.g. Chicken Fried Rice, Veg Thali, Idli Sambar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter meal name' : null,
              ),
              const SizedBox(height: 12),

              // Pickup Location / Landmark Address with Live Auto-Suggestions
              TextFormField(
                controller: _locationController,
                onTap: () {
                  setState(() => _showSuggestions = true);
                },
                decoration: InputDecoration(
                  labelText: 'Pickup Location / Landmark *',
                  hintText: 'Type campus, area, or PG address...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showSuggestions ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() => _showSuggestions = !_showSuggestions);
                    },
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter pickup location' : null,
              ),

              // Quick Location Presets Chips Bar
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._allLocations.take(4).map((loc) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          avatar: const Icon(Icons.place, size: 14, color: AppColors.primary),
                          label: Text(
                            loc['tag'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          backgroundColor: AppColors.primaryLight,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _selectLocationPreset(loc),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Suggestions Dropdown List (Pops out when typing or tapping field)
              if (_showSuggestions && _filteredSuggestions.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 8),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _filteredSuggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredSuggestions[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                        title: Text(
                          item['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          item['subtitle'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        onTap: () => _selectLocationPreset(item),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // "Set PG location from current GPS" button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                ),
                icon: _isAcquiringGps
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  _isAcquiringGps ? 'Locking GPS Coordinates...' : 'Set PG location from my current GPS location',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _isAcquiringGps ? null : _fetchOwnerGPSLocation,
              ),
              const SizedBox(height: 10),

              // Latitude & Longitude display/editable fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'PG Latitude',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'PG Longitude',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.explore, size: 16),
                      ),
                    ),
                  ),
                ],
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
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter price' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Surplus ₹ *',
                        hintText: '50',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter price' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _portionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Portions *',
                        hintText: '8',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Count' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Pickup Window Hours (Cleanly wrapped column, no overflow!)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pickup available for next:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1 hr')),
                        ButtonSegment(value: 2, label: Text('2 hrs')),
                        ButtonSegment(value: 3, label: Text('3 hrs')),
                      ],
                      selected: {_pickupHours},
                      onSelectionChanged: (set) => setState(() => _pickupHours = set.first),
                    ),
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
                  hintText: 'e.g. Freshly cooked, includes curd & pickle.',
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

