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
    final locationState = ref.watch(locationProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo, Greeting, and Profile Avatar
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

          // GPS-First Live Location & Radius Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Location Icon or Spinner
                if (locationState.status == LocationStatus.locating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else if (locationState.status == LocationStatus.denied ||
                    locationState.status == LocationStatus.deniedForever ||
                    locationState.status == LocationStatus.serviceDisabled)
                  const Icon(Icons.location_off_outlined, color: AppColors.error, size: 18)
                else
                  const Icon(Icons.my_location, color: AppColors.primary, size: 18),

                const SizedBox(width: 8),

                // Live Locality Label
                Expanded(
                  child: InkWell(
                    onTap: () => _showLocationRadiusSheet(context, ref, locationState),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                locationState.status == LocationStatus.locating
                                    ? 'Finding your current location…'
                                    : locationState.localityLabel,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                        Text(
                          locationState.isManualFallback
                              ? 'Approximate area (GPS disabled)'
                              : locationState.subLocality,
                          style: TextStyle(
                            fontSize: 11,
                            color: locationState.isManualFallback ? AppColors.warning : AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Radius Chip ("Within 2 km")
                InkWell(
                  onTap: () => _showLocationRadiusSheet(context, ref, locationState),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Within ${locationState.radiusKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                // Instant GPS Refresh Button
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Refresh GPS location',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    ref.read(locationProvider.notifier).requestAndFetchGPSLocation();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationRadiusSheet(BuildContext context, WidgetRef ref, LocationState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationRadiusBottomSheet(locationState: state, ref: ref),
    );
  }
}

class _LocationRadiusBottomSheet extends StatefulWidget {
  final LocationState locationState;
  final WidgetRef ref;

  const _LocationRadiusBottomSheet({required this.locationState, required this.ref});

  @override
  State<_LocationRadiusBottomSheet> createState() => _LocationRadiusBottomSheetState();
}

class _LocationRadiusBottomSheetState extends State<_LocationRadiusBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredFallbacks = [];

  final List<Map<String, dynamic>> _radiusOptions = [
    {'label': '1 km', 'meters': 1000.0, 'desc': 'Walking distance (5-10 mins)'},
    {'label': '2 km', 'meters': 2000.0, 'desc': 'Default radius (Hostels & PGs nearby)'},
    {'label': '5 km', 'meters': 5000.0, 'desc': 'Short scooter / bike ride'},
    {'label': '10 km', 'meters': 10000.0, 'desc': 'Wider campus & town area'},
  ];

  final List<Map<String, dynamic>> _approximateFallbacks = [
    {
      'title': 'Near VIT-AP University',
      'subtitle': 'Inavolu, Amaravati',
      'lat': 16.4950,
      'lng': 80.5000,
      'tag': 'VIT-AP',
    },
    {
      'title': 'Near SRM University-AP',
      'subtitle': 'Neerukonda, Mangalagiri',
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
      'title': 'Thullur Center',
      'subtitle': 'Capital Region, Amaravati',
      'lat': 16.5350,
      'lng': 80.4850,
      'tag': 'Thullur',
    },
    {
      'title': 'Mangalagiri Town',
      'subtitle': 'Near Highway Junction, Guntur',
      'lat': 16.4350,
      'lng': 80.5600,
      'tag': 'Mangalagiri',
    },
    {
      'title': 'Vijayawada Benz Circle',
      'subtitle': 'MG Road, Vijayawada',
      'lat': 16.5062,
      'lng': 80.6480,
      'tag': 'Vijayawada',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredFallbacks = List.from(_approximateFallbacks);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredFallbacks = List.from(_approximateFallbacks);
      });
      return;
    }

    setState(() {
      _filteredFallbacks = _approximateFallbacks.where((loc) {
        final title = (loc['title'] as String).toLowerCase();
        final sub = (loc['subtitle'] as String).toLowerCase();
        final tag = (loc['tag'] as String).toLowerCase();
        return title.contains(query) || sub.contains(query) || tag.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.locationState;
    final isPermissionDenied = state.status == LocationStatus.denied ||
        state.status == LocationStatus.deniedForever ||
        state.status == LocationStatus.serviceDisabled;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gps_fixed, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'GPS Discovery & Radius',
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
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Permission Warning Card if GPS is disabled or denied
            if (isPermissionDenied) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage ?? 'GPS Permission is required to show real-time nearby meals within 2 km.',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.settings, size: 16),
                            label: const Text('Open Settings', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              widget.ref.read(locationProvider.notifier).openAppSettings();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Try Again', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final nav = Navigator.of(context);
                              await widget.ref.read(locationProvider.notifier).requestAndFetchGPSLocation();
                              if (mounted) nav.pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Search / Type Area with Instant Suggestions
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search campus, area, or landmark...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            // Pop-out search suggestions if user typed
            if (_searchController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _filteredFallbacks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'No matching areas found. Try "VIT", "SRM", "Thullur", or "Mangalagiri".',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredFallbacks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final fb = _filteredFallbacks[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place, color: AppColors.primary, size: 18),
                            title: Text(fb['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(fb['subtitle'] as String, style: const TextStyle(fontSize: 11)),
                            onTap: () {
                              widget.ref.read(locationProvider.notifier).setManualFallback(
                                    localityName: fb['title'] as String,
                                    subLocality: fb['subtitle'] as String,
                                    latitude: fb['lat'] as double,
                                    longitude: fb['lng'] as double,
                                  );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primary,
                                  content: Text('📍 Location set to "${fb['title']}"'),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
            const SizedBox(height: 16),

            // Current GPS Location Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.localityLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.subLocality,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync, color: AppColors.primary),
                    tooltip: 'Re-fetch GPS',
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await widget.ref.read(locationProvider.notifier).requestAndFetchGPSLocation();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('📍 Live GPS position updated.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Radius Selector Header
            const Text(
              'Select Discovery Radius',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Radius Options List
            ..._radiusOptions.map((opt) {
              final isSelected = state.radiusMeters == opt['meters'];
              return InkWell(
                onTap: () {
                  widget.ref.read(locationProvider.notifier).setRadius(opt['meters'] as double);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('🎯 Search radius updated to ${opt['label']}.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['label'] as String,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              opt['desc'] as String,
                              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Chip(
                          label: Text('ACTIVE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              );
            }),

            // Approximate Preset Area Chips
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Popular Campuses & Towns',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _approximateFallbacks.map((fb) {
                final isSelected = state.localityLabel == fb['title'];
                return ActionChip(
                  avatar: const Icon(Icons.place, size: 14, color: AppColors.primary),
                  label: Text(
                    fb['tag'] as String? ?? fb['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: isSelected ? AppColors.primaryLight : Colors.grey.shade100,
                  onPressed: () {
                    widget.ref.read(locationProvider.notifier).setManualFallback(
                          localityName: fb['title'] as String,
                          subLocality: fb['subtitle'] as String,
                          latitude: fb['lat'] as double,
                          longitude: fb['lng'] as double,
                        );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


