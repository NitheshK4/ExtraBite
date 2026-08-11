import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';

class LocationHeader extends ConsumerWidget {
  const LocationHeader({super.key});

  String getGreeting([String? name]) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    if (name != null && name.trim().isNotEmpty) {
      final firstName = name.trim().split(' ').first;
      return '$timeGreeting, $firstName 👋';
    }
    return '$timeGreeting 👋';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final initials = user?.initials ?? 'EB';
    final currentLocation = ref.watch(locationProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/branding/extrabite_logo.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ExtraBite',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getGreeting(user?.name),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/customer/profile'),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tappable Location Row
          InkWell(
            onTap: () => _showLocationPicker(context, ref, currentLocation),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      currentLocation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context, WidgetRef ref, String currentLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerSheet(currentLocation: currentLocation, ref: ref),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final String currentLocation;
  final WidgetRef ref;

  const _LocationPickerSheet({required this.currentLocation, required this.ref});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late final TextEditingController _customLocationController;

  final List<Map<String, String>> _popularLocations = [
    {
      'title': 'Near VIT-AP University',
      'subtitle': 'Inavolu, Amaravati, Andhra Pradesh',
      'icon': 'campus',
    },
    {
      'title': 'Near SRM University-AP',
      'subtitle': 'Neerukonda, Mangalagiri, Andhra Pradesh',
      'icon': 'campus',
    },
    {
      'title': 'Thullur Center',
      'subtitle': 'Capital Region, Amaravati',
      'icon': 'town',
    },
    {
      'title': 'Mangalagiri Town',
      'subtitle': 'Near Highway Junction, Guntur',
      'icon': 'town',
    },
    {
      'title': 'Vijayawada Benz Circle',
      'subtitle': 'MG Road / Benz Circle area',
      'icon': 'city',
    },
  ];

  @override
  void initState() {
    super.initState();
    _customLocationController = TextEditingController(text: widget.currentLocation);
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  void _selectLocation(String locationName) {
    widget.ref.read(locationProvider.notifier).updateLocation(locationName);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('📍 Location updated to "$locationName"'),
        duration: const Duration(seconds: 2),
      ),
    );
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.place_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Choose Your Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Custom search / location input
            TextField(
              controller: _customLocationController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Enter campus, hostel, or landmark...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, color: AppColors.primary),
                  tooltip: 'Apply location',
                  onPressed: () {
                    final text = _customLocationController.text.trim();
                    if (text.isNotEmpty) {
                      _selectLocation(text);
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _selectLocation(val.trim());
                }
              },
            ),
            const SizedBox(height: 12),

            // Use Current GPS Location Button
            InkWell(
              onTap: () {
                _selectLocation('Near VIT-AP University (Current GPS)');
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current GPS Location',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                          ),
                          Text(
                            'Fetch nearest surplus meals in your area',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Popular Campuses & Areas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Popular options list
            ..._popularLocations.map((loc) {
              final isSelected = widget.currentLocation == loc['title'];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    loc['icon'] == 'campus' ? Icons.school_outlined : Icons.location_city_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  loc['title']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  loc['subtitle']!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : const Icon(Icons.chevron_right, color: AppColors.textLight),
                onTap: () => _selectLocation(loc['title']!),
              );
            }),
          ],
        ),
      ),
    );
  }
}

