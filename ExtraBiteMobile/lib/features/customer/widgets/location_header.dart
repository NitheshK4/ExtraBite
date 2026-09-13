import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/location_history_item.dart';
import '../../../providers/location_history_provider.dart';
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
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),

          // Location details (Tappable to pick location)
          Expanded(
            child: InkWell(
              onTap: () =>
                  _showLocationPicker(context, ref, locationState.displayName),
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
                          locationState.status ==
                                      LocationStateStatus.available &&
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

  void _showLocationPicker(
      BuildContext context, WidgetRef ref, String currentLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _LocationPickerSheet(currentLocation: currentLocation),
    );
  }
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  final String currentLocation;

  const _LocationPickerSheet({required this.currentLocation});

  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  late final TextEditingController _customLocationController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _customLocationController = TextEditingController();
    _customLocationController.addListener(() {
      setState(() {
        _searchQuery = _customLocationController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  void _selectLocationItem(LocationHistoryItem item) {
    ref.read(locationHistoryProvider.notifier).addLocation(item);
    ref.read(locationProvider.notifier).updateLocation(
          item.title,
          latitude: item.latitude,
          longitude: item.longitude,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('📍 Location updated to "${item.title}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectCustomLocation(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    // Check if it matches any catalog item
    final matched = knownLocationsCatalog.firstWhere(
      (c) => c.title.toLowerCase() == clean.toLowerCase(),
      orElse: () => LocationHistoryItem(
        id: 'loc_${clean.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
        title: clean,
        subtitle: 'Searched location',
        latitude: 16.4971,
        longitude: 80.5005,
        icon: 'place',
        timestamp: DateTime.now(),
      ),
    );

    _selectLocationItem(matched);
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Recent Locations?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove all recent search locations?',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              ref.read(locationHistoryProvider.notifier).clearHistory();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(locationHistoryProvider);

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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary, size: 20),
                        tooltip: 'Clear input',
                        onPressed: () {
                          _customLocationController.clear();
                        },
                      )
                    : null,
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _selectCustomLocation(val.trim());
                }
              },
            ),
            const SizedBox(height: 12),

            // Use Current GPS Location Button
            InkWell(
              onTap: () {
                ref.read(locationProvider.notifier).resetToDefault();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location,
                        color: AppColors.primary, size: 20),
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
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DYNAMIC SECTION: Search Results OR Recent Locations
            if (_searchQuery.isNotEmpty) ...[
              Text(
                'Search Results',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildSearchResults(_searchQuery),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Locations',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearHistory(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (history.isEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.history,
                          size: 36,
                          color: AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 8),
                      Text(
                        'Search for a location to get started.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your selected campus or area will be saved here for quick access.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...history.map((item) {
                  final isSelected = widget.currentLocation == item.title;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon == 'campus'
                            ? Icons.school_outlined
                            : item.icon == 'city' || item.icon == 'town'
                                ? Icons.location_city_outlined
                                : Icons.place_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.check_circle,
                                color: AppColors.primary, size: 20),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: AppColors.textLight),
                          tooltip: 'Remove',
                          onPressed: () {
                            ref
                                .read(locationHistoryProvider.notifier)
                                .removeLocation(item.id);
                          },
                        ),
                      ],
                    ),
                    onTap: () => _selectLocationItem(item),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(String query) {
    final cleanQuery = query.toLowerCase();
    final matches = knownLocationsCatalog.where((item) {
      return item.title.toLowerCase().contains(cleanQuery) ||
          item.subtitle.toLowerCase().contains(cleanQuery);
    }).toList();

    // Check if query exactly matches a catalog item
    final exactMatch = matches
        .any((item) => item.title.toLowerCase() == query.trim().toLowerCase());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (matches.isEmpty)
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.search, color: AppColors.primary, size: 20),
            ),
            title: Text(
              query.trim(),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Select this custom location',
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textLight),
            onTap: () => _selectCustomLocation(query),
          )
        else ...[
          ...matches.map((item) {
            final isSelected = widget.currentLocation == item.title;
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon == 'campus'
                      ? Icons.school_outlined
                      : item.icon == 'city' || item.icon == 'town'
                          ? Icons.location_city_outlined
                          : Icons.place_outlined,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              title: Text(
                item.title,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20)
                  : const Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () => _selectLocationItem(item),
            );
          }),
          if (!exactMatch)
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
              ),
              title: Text(
                'Search for "$query"',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Set as custom location',
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () => _selectCustomLocation(query),
            ),
        ],
      ],
    );
  }
}
