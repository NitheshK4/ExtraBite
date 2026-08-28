import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../core/location/location_state.dart';

class LocationHeader extends ConsumerWidget {
  const LocationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userInitials = user?.initials ?? 'AK';

    final locationState = ref.watch(locationProvider);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Logo
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Image.asset(
              'assets/branding/extrabite_logo.png',
              height: 36,
              width: 36,
              fit: BoxFit.contain,
            ),
          ),

          // Location details (Tappable to pick location)
          Expanded(
            child: InkWell(
              onTap: () => _showLocationPicker(context, ref, locationState.displayName),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationState.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          locationState.status == LocationStateStatus.available &&
                                  locationState.latitude != null &&
                                  locationState.longitude != null
                              ? '${locationState.latitude!.toStringAsFixed(3)}, ${locationState.longitude!.toStringAsFixed(3)}'
                              : 'Tap to change area',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // User Profile Initials Pill / Button
          InkWell(
            onTap: () => context.go('/customer/profile'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
              ),
              child: Center(
                child: Text(
                  userInitials,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
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
                Row(
                  children: [
                    const Icon(Icons.place_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Choose Your Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.outline),
            const SizedBox(height: 12),

            // Custom search / location input
            TextField(
              controller: _customLocationController,
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
                widget.ref.read(locationProvider.notifier).resetToDefault();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text('📍 Reset to GPS location tracking'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current GPS Location',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Fetch nearest surplus meals using device GPS',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Popular Campuses & Areas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
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
                    color: isSelected ? AppColors.primaryLight : AppColors.surfaceContainerHigh,
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
                  style: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  loc['subtitle']!,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
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
