import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/food_provider.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const AddMealScreen({super.key, required this.user});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _portionsController = TextEditingController(text: '5');
  final _ingredientsController = TextEditingController();
  final _allergensController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _category = 'Lunch';
  String _dietaryType = 'vegetarian';
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);

  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _ownerPg;

  final _categories = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  final _dietaryTypes = [
    {'value': 'vegetarian', 'label': '🌱 Vegetarian'},
    {'value': 'non_vegetarian', 'label': '🍗 Non-Vegetarian'},
    {'value': 'vegan', 'label': '🥗 Vegan'},
    {'value': 'egg', 'label': '🥚 Contains Egg'}
  ];

  @override
  void initState() {
    super.initState();
    _loadOwnerPg();
  }

  Future<void> _loadOwnerPg() async {
    setState(() => _isLoading = true);
    final repo = ref.read(foodRepositoryProvider);
    final pg = await repo.fetchOwnerPg(widget.user.id);
    if (mounted) {
      setState(() {
        _ownerPg = pg;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _portionsController.dispose();
    _ingredientsController.dispose();
    _allergensController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<Uint8List?> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: 80,
      );
      return result;
    } catch (_) {
      return await file.readAsBytes();
    }
  }

  double _calculateDiscountPercent() {
    final orig = double.tryParse(_originalPriceController.text.trim()) ?? 0.0;
    final sell = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    if (orig <= 0 || sell <= 0 || sell >= orig) return 0.0;
    return ((orig - sell) / orig) * 100.0;
  }

  double _calculateSavings() {
    final orig = double.tryParse(_originalPriceController.text.trim()) ?? 0.0;
    final sell = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    if (orig <= 0 || sell <= 0 || sell >= orig) return 0.0;
    return orig - sell;
  }

  Future<void> _publish() async {
    if (_ownerPg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No property registered or approved. Cannot publish meals.')),
      );
      return;
    }

    final isApproved = _ownerPg!['is_approved'] as bool? ?? false;
    final isActive = _ownerPg!['is_active'] as bool? ?? false;

    if (!isApproved || !isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your property must be approved and active to post meals.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        final compressedBytes = await _compressImage(_imageFile!);
        if (compressedBytes != null) {
          final repo = ref.read(foodRepositoryProvider);
          final extension = _imageFile!.path.split('.').last.toLowerCase();
          imageUrl = await repo.uploadFoodImage(
            compressedBytes,
            _ownerPg!['id'] as String,
            extension.isNotEmpty ? extension : 'jpg',
          );
        }
      }

      final startDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        throw Exception('Pickup end time cannot be before start time');
      }

      List<String> parseList(String text) => text.trim().isEmpty
          ? <String>[]
          : text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final rowData = {
        'pg_id': _ownerPg!['id'] as String,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'image_url': imageUrl,
        'original_price': double.parse(_originalPriceController.text),
        'discounted_price': double.parse(_sellingPriceController.text),
        'total_portions': int.parse(_portionsController.text),
        'available_portions': int.parse(_portionsController.text),
        'dietary_type': _dietaryType,
        'ingredients': parseList(_ingredientsController.text),
        'allergens': parseList(_allergensController.text),
        'pickup_start_time': startDateTime.toIso8601String(),
        'pickup_end_time': endDateTime.toIso8601String(),
        'pickup_instructions': _instructionsController.text.trim(),
        'status': 'active',
      };

      final repo = ref.read(foodRepositoryProvider);
      final newListing = await repo.createListing(rowData, _ownerPg!);

      await ref.read(foodProvider.notifier).loadListings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('🎉 "${newListing.foodName}" successfully published!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    if (_ownerPg == null && !_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Add Meal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Owner Property Registration Required',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your PG/hostel property profile must be registered and fully approved by admins before listing surplus food.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Surplus Meal',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image picker area
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                                title: Text('Pick from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                                title: Text('Take a Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.primary),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Add Food Image',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'High-quality photo attracts faster reservations',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Food/Meal Title *',
                      hintText: 'e.g. Rice + Sambar + Fry, Chicken Biryani',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter meal title' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. Prepared fresh for lunch. Fully hygienic.',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                          ),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter()))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _category = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _dietaryType,
                          decoration: const InputDecoration(
                            labelText: 'Dietary Type *',
                          ),
                          items: _dietaryTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!, style: GoogleFonts.inter()))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _dietaryType = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Original Price (₹) *',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Enter price' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ExtraBite Price (₹) *',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Enter price' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _portionsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Portions *',
                          ),
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Count' : null,
                        ),
                      ),
                    ],
                  ),
                  if (_calculateDiscountPercent() > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            '${_calculateDiscountPercent().toStringAsFixed(0)}% OFF • Student saves ₹${_calculateSavings().toStringAsFixed(0)} per portion',
                            style: GoogleFonts.inter(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  Text(
                    'Pickup Window Setting',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    tileColor: AppColors.surface,
                    title: Text('Pickup Date', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text('${_pickupDate.day}/${_pickupDate.month}/${_pickupDate.year}', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.calendar_month, color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.outline),
                    ),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _pickupDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (selected != null) {
                        setState(() => _pickupDate = selected);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          tileColor: AppColors.surface,
                          title: Text('Start Time', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(_startTime.format(context), style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.outline),
                          ),
                          onTap: () async {
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (selected != null) {
                              setState(() => _startTime = selected);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          tileColor: AppColors.surface,
                          title: Text('End Time', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(_endTime.format(context), style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.outline),
                          ),
                          onTap: () async {
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (selected != null) {
                              setState(() => _endTime = selected);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients (comma separated)',
                      hintText: 'e.g. Rice, Lentils, Spices',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _allergensController,
                    decoration: const InputDecoration(
                      labelText: 'Allergen Warnings (comma separated)',
                      hintText: 'e.g. Peanuts, Gluten',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Instructions / Notes',
                      hintText: 'e.g. Collect near dining hall gate.',
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _publish,
                    child: Text(
                      'Publish Surplus Meal',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Publishing Meal live... Please wait.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
