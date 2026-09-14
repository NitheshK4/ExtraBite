import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/food_listing.dart';
import '../../../models/user_model.dart';
import '../../../providers/food_provider.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final FoodListing? initialListing;

  const AddMealScreen({
    super.key,
    required this.user,
    this.initialListing,
  });

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

  Uint8List? _imageBytes;
  String? _imageExtension;
  String? _existingImageUrl;
  bool _imageRemoved = false;

  bool _isLoading = false;
  String _loadingStatus = 'Publishing Meal live... Please wait.';
  Map<String, dynamic>? _ownerPg;

  bool get _isEditing => widget.initialListing != null;

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
    if (widget.initialListing != null) {
      final item = widget.initialListing!;
      _titleController.text = item.foodName;
      _descriptionController.text = item.description;
      _originalPriceController.text = item.originalPrice.toStringAsFixed(0);
      _sellingPriceController.text = item.sellingPrice.toStringAsFixed(0);
      _portionsController.text = item.availablePortions.toString();
      _ingredientsController.text = item.ingredients.join(', ');
      _allergensController.text = item.allergens.join(', ');
      _category = item.category;
      _dietaryType = item.dietaryType;
      _pickupDate = item.pickupStarts;
      _startTime = TimeOfDay.fromDateTime(item.pickupStarts);
      _endTime = TimeOfDay.fromDateTime(item.pickupEnds);
      _existingImageUrl = item.imageUrl;
    }
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
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final extension = pickedFile.name.split('.').last.toLowerCase();
      const validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      if (!validExtensions.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please choose a valid image format (JPG, PNG, or WebP).'),
            ),
          );
        }
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      // Enforce 5MB file-size limit
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Image file is too large. Please select a photo under 5MB.'),
            ),
          );
        }
        return;
      }

      // Compress image on mobile platforms
      Uint8List finalBytes = bytes;
      if (!kIsWeb) {
        try {
          final compressed = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 900,
            minHeight: 600,
            quality: 80,
          );
          if (compressed.isNotEmpty) {
            finalBytes = Uint8List.fromList(compressed);
          }
        } catch (_) {
          finalBytes = bytes;
        }
      }

      setState(() {
        _imageBytes = finalBytes;
        _imageExtension = extension;
        _imageRemoved = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _imageBytes = null;
      _imageExtension = null;
      _existingImageUrl = null;
      _imageRemoved = true;
    });
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
        const SnackBar(
            content: Text(
                'No property registered or approved. Cannot publish meals.')),
      );
      return;
    }

    final isApproved = _ownerPg!['is_approved'] as bool? ?? false;
    final isActive = _ownerPg!['is_active'] as bool? ?? false;

    if (!isApproved || !isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Your property must be approved and active to post meals.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingStatus = _isEditing
          ? 'Updating meal listing...'
          : 'Publishing surplus meal...';
    });

    try {
      String? imageUrl = _existingImageUrl;
      if (_imageRemoved) {
        imageUrl = null;
      }

      // If a new image was picked, upload it to Supabase Storage
      if (_imageBytes != null && _imageExtension != null) {
        setState(() => _loadingStatus = 'Uploading food photo...');
        final repo = ref.read(foodRepositoryProvider);
        try {
          imageUrl = await repo.uploadFoodImage(
            _imageBytes!,
            widget.user.id,
            _imageExtension!,
            listingId: widget.initialListing?.id,
          );
        } catch (uploadErr) {
          final isBucket404 =
              uploadErr.toString().contains('Bucket not found') ||
                  uploadErr.toString().contains('404');
          if (mounted) {
            final proceedWithoutImage = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(
                  isBucket404
                      ? 'Storage Bucket Not Found'
                      : 'Photo Upload Failed',
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
                content: Text(
                  isBucket404
                      ? 'The "food-images" storage bucket has not been created in your Supabase project yet.\n\nWould you like to save your meal details without the new photo for now?'
                      : 'Could not upload food image: $uploadErr\n\nWould you like to save your meal details without the new photo for now?',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save Without Photo'),
                  ),
                ],
              ),
            );

            if (proceedWithoutImage != true) {
              setState(() => _isLoading = false);
              return;
            }
            imageUrl = _existingImageUrl;
          }
        }
      }

      setState(() {
        _loadingStatus = _isEditing
            ? 'Saving listing changes...'
            : 'Publishing listing live...';
      });

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
          : text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

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

      if (_isEditing) {
        final updatedListing = await repo.updateListing(
          widget.initialListing!.id,
          rowData,
          _ownerPg!,
        );
        ref.read(foodProvider.notifier).updateListing(updatedListing);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              content:
                  Text('✅ "${updatedListing.foodName}" successfully updated!'),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final newListing = await repo.createListing(rowData, _ownerPg!);
        ref.read(foodProvider.notifier).addListing(newListing);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              content:
                  Text('🎉 "${newListing.foodName}" successfully published!'),
            ),
          );
          Navigator.pop(context);
        }
      }

      // Refresh listings in background to ensure sync
      ref.read(foodProvider.notifier).loadListings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Pick from Gallery',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.primary),
              title: Text('Take a Photo',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final hasNewImage = _imageBytes != null;
    final hasExistingImage = _existingImageUrl != null &&
        _existingImageUrl!.isNotEmpty &&
        !_imageRemoved;

    if (!hasNewImage && !hasExistingImage) {
      return GestureDetector(
        onTap: _showImagePickerSheet,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_outlined,
                    size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                'Add Food Image',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'JPG, PNG, WebP · Under 5MB',
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: hasNewImage
                ? Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    _existingImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 48, color: AppColors.textLight),
                    ),
                  ),
          ),

          // Action overlay buttons (Change & Remove)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.black.withOpacity(0.65),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    tooltip: 'Change Photo',
                    onPressed: _showImagePickerSheet,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.black.withOpacity(0.65),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 18),
                    tooltip: 'Remove Photo',
                    onPressed: _removeSelectedImage,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasNewImage ? 'New image selected' : 'Current listing image',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ownerPg == null && !_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(_isEditing ? 'Edit Meal' : 'Add Meal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Owner Property Registration Required',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700),
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
          _isEditing ? 'Edit Surplus Meal' : 'Add Surplus Meal',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 18),
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
                  // Image picker area with preview & validation
                  _buildImagePreview(),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Meal Name / Title *',
                      hintText: 'e.g. Fresh Paneer Butter Masala Combo',
                      prefixIcon: Icon(Icons.restaurant_menu),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter meal title'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText:
                          'Brief description about portions, side dishes, etc.',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meal Category
                  Text(
                    'Meal Category *',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _category = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Dietary Type
                  Text(
                    'Dietary Preference *',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietaryTypes.map((type) {
                      final isSelected = _dietaryType == type['value'];
                      return ChoiceChip(
                        label: Text(type['label']!),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _dietaryType = type['value']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Pricing row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Original Price (₹) *',
                            prefixText: '₹ ',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Enter original price';
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed <= 0)
                              return 'Enter valid price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'ExtraBite Price (₹) *',
                            prefixText: '₹ ',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Enter selling price';
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed <= 0)
                              return 'Enter valid price';
                            final orig = double.tryParse(
                                    _originalPriceController.text.trim()) ??
                                0;
                            if (parsed >= orig)
                              return 'Must be less than original';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  // Discount / Savings summary
                  if (_calculateDiscountPercent() > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_outlined,
                              color: AppColors.secondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Customer saves ₹${_calculateSavings().toStringAsFixed(0)} (${_calculateDiscountPercent().toStringAsFixed(0)}% OFF)',
                            style: GoogleFonts.inter(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Portions
                  TextFormField(
                    controller: _portionsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Available Portions / Meals *',
                      prefixIcon: Icon(Icons.format_list_numbered),
                      helperText:
                          'Number of extra portions available right now',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Enter portions count';
                      final parsed = int.tryParse(val);
                      if (parsed == null || parsed <= 0)
                        return 'Must be at least 1';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Pickup Window
                  Text(
                    'Pickup Window *',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today,
                              color: AppColors.primary),
                          title: const Text('Pickup Date'),
                          trailing: TextButton(
                            child: Text(
                              '${_pickupDate.day}/${_pickupDate.month}/${_pickupDate.year}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _pickupDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 1)),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 7)),
                              );
                              if (picked != null)
                                setState(() => _pickupDate = picked);
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.access_time,
                                    color: AppColors.primary),
                                title: const Text('Start Time',
                                    style: TextStyle(fontSize: 13)),
                                subtitle: Text(_startTime.format(context),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _startTime);
                                  if (picked != null)
                                    setState(() => _startTime = picked);
                                },
                              ),
                            ),
                            Container(
                                width: 1, height: 40, color: AppColors.outline),
                            Expanded(
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(left: 12),
                                leading: const Icon(Icons.timelapse,
                                    color: AppColors.secondary),
                                title: const Text('End Time',
                                    style: TextStyle(fontSize: 13)),
                                subtitle: Text(_endTime.format(context),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                      context: context, initialTime: _endTime);
                                  if (picked != null)
                                    setState(() => _endTime = picked);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Optional ingredients & allergens
                  TextFormField(
                    controller: _ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Key Ingredients (comma separated)',
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
                    onPressed: _isLoading ? null : _publish,
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Publish Surplus Meal',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        _loadingStatus,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 14),
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
