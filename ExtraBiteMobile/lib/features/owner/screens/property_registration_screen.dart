import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../core/location/location_state.dart';
import '../../../models/user_role.dart';

class PropertyRegistrationScreen extends ConsumerStatefulWidget {
  const PropertyRegistrationScreen({super.key});

  @override
  ConsumerState<PropertyRegistrationScreen> createState() =>
      _PropertyRegistrationScreenState();
}

class _PropertyRegistrationScreenState
    extends ConsumerState<PropertyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _pgNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController(text: '16.4971');
  final _lonController = TextEditingController(text: '80.5005');

  bool _isLoading = false;
  bool _isLocating = false;
  String? _gpsStatusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProfile();
      _detectCurrentLocation();
    });
  }

  Future<void> _loadExistingProfile() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      final repo = ref.read(pgProfileRepositoryProvider);
      final profile = await repo.fetchOwnerPg(user.id);
      if (profile != null && mounted) {
        setState(() {
          if (_pgNameController.text.isEmpty && profile['pg_name'] != null) {
            _pgNameController.text = profile['pg_name'].toString();
          }
          if (_addressController.text.isEmpty && profile['address'] != null) {
            _addressController.text = profile['address'].toString();
          }
          if (_phoneController.text.isEmpty && profile['contact_phone'] != null) {
            _phoneController.text = profile['contact_phone'].toString();
          }
          if (_descriptionController.text.isEmpty && profile['description'] != null) {
            _descriptionController.text = profile['description'].toString();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pgNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _gpsStatusMessage = null;
    });

    try {
      await ref.read(locationProvider.notifier).determinePosition();
      final locState = ref.read(locationProvider);

      if (locState.status == LocationStateStatus.available &&
          locState.latitude != null &&
          locState.longitude != null) {
        _latController.text = locState.latitude!.toStringAsFixed(6);
        _lonController.text = locState.longitude!.toStringAsFixed(6);
        setState(() {
          _gpsStatusMessage = 'GPS Location acquired successfully';
        });
      } else if (locState.status == LocationStateStatus.permissionDenied) {
        setState(() {
          _gpsStatusMessage = 'Location permission denied. Using manual coordinates.';
        });
      } else if (locState.status == LocationStateStatus.serviceDisabled) {
        setState(() {
          _gpsStatusMessage = 'Location services disabled. Please enable GPS or enter coordinates.';
        });
      } else {
        setState(() {
          _gpsStatusMessage = 'Unable to get GPS. Enter coordinates manually.';
        });
      }
    } catch (_) {
      setState(() {
        _gpsStatusMessage = 'Location detection failed. Using default/manual coordinates.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null ||
        user.role != UserRole.owner ||
        !user.roleFinalized ||
        !user.isOwnerEligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unauthorized to register property.')),
      );
      return;
    }

    final double lat = double.tryParse(_latController.text.trim()) ?? 16.4971;
    final double lon = double.tryParse(_lonController.text.trim()) ?? 80.5005;

    setState(() => _isLoading = true);

    try {
      final pgRepo = ref.read(pgProfileRepositoryProvider);
      // Derive ownerId directly from user profile (which comes from Auth session)
      await pgRepo.submitPgProfile(
        ownerId: user.id,
        pgName: _pgNameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: lat,
        longitude: lon,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      // Re-evaluate auth notifier's onboarding state to navigate to approval pending
      await ref.read(authProvider.notifier).recheckPropertyStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete your PG profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Complete your PG profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us about your property so customers know where their food comes from.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _pgNameController,
                  decoration: const InputDecoration(
                    labelText: 'PG / Hostel / Mess Name',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter property name'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter address'
                      : null,
                ),
                const SizedBox(height: 16),

                // Location GPS coordinate container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.my_location, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Property Geolocation',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _isLocating ? null : _detectCurrentLocation,
                            icon: _isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 16),
                            label: const Text('Detect GPS', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      if (_gpsStatusMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _gpsStatusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _gpsStatusMessage!.contains('successfully')
                                ? AppColors.success
                                : AppColors.secondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) => val == null || double.tryParse(val) == null
                                  ? 'Valid latitude'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lonController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) => val == null || double.tryParse(val) == null
                                  ? 'Valid longitude'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit for Approval',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
