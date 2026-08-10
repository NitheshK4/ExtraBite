import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/permissions/permission_service.dart';
import '../../models/food_listing_model.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/pay_at_pickup_badge.dart';

class CreateEditListingScreen extends ConsumerStatefulWidget {
  final String? listingId;

  const CreateEditListingScreen({super.key, this.listingId});

  @override
  ConsumerState<CreateEditListingScreen> createState() => _CreateEditListingScreenState();
}

class _CreateEditListingScreenState extends ConsumerState<CreateEditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _discountedPriceController = TextEditingController();
  final TextEditingController _portionsController = TextEditingController(text: '6');
  final TextEditingController _instructionsController = TextEditingController();

  String _category = 'Dinner';
  DietaryType _dietaryType = DietaryType.vegetarian;
  final List<String> _selectedAllergens = ['Dairy', 'Gluten'];
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  DateTime _pickupStartTime = DateTime.now();
  DateTime _pickupEndTime = DateTime.now().add(const Duration(hours: 2));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _portionsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    bool granted = false;
    if (source == ImageSource.camera) {
      granted = await PermissionService.requestCameraPermission(context);
    } else {
      granted = await PermissionService.requestPhotosPermission(context);
    }

    if (!granted) return;

    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        setState(() => _selectedImagePath = file.path);
      }
    } catch (_) {}
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).currentUser;
    final pgId = user?.pgId ?? 'pg_01';

    final origPrice = double.tryParse(_originalPriceController.text) ?? 150.0;
    final discPrice = double.tryParse(_discountedPriceController.text) ?? 60.0;
    final portions = int.tryParse(_portionsController.text) ?? 6;

    final newListing = FoodListingModel(
      id: 'list_${DateTime.now().millisecondsSinceEpoch}',
      pgId: pgId,
      pgName: 'Sri Sai Executive PG & Mess',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      imageUrl: _selectedImagePath ?? 'https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?w=600',
      originalPrice: origPrice,
      discountedPrice: discPrice,
      totalPortions: portions,
      availablePortions: portions,
      dietaryType: _dietaryType,
      allergens: _selectedAllergens,
      pickupStartTime: _pickupStartTime,
      pickupEndTime: _pickupEndTime,
      pickupInstructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : 'Collect at dining counter. Pay at pickup.',
      address: '14th Main Rd, 4th Block, Koramangala',
      neighborhood: 'Koramangala',
      latitude: 12.9352,
      longitude: 77.6245,
      createdAt: DateTime.now(),
    );

    ref.read(listingProvider.notifier).addListing(newListing);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Surplus meal listing published successfully!'),
        backgroundColor: AppColors.secondary,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Surplus Meal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Box
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt_rounded),
                            title: const Text('Take Food Photo'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library_rounded),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        _selectedImagePath != null ? 'Photo selected (Tap to change)' : 'Upload Food Photo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Authentic photos increase reservations by 3x',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Meal / Dish Name *',
                  hintText: 'e.g. Special South Indian Lunch Thali',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter dish name' : null,
              ),

              const SizedBox(height: 16),

              // Category & Dietary
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Meal Type', border: OutlineInputBorder()),
                      items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _category = val ?? 'Dinner'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<DietaryType>(
                      value: _dietaryType,
                      decoration: const InputDecoration(labelText: 'Dietary', border: OutlineInputBorder()),
                      items: DietaryType.values
                          .map((d) => DropdownMenuItem(value: d, child: Text(d.displayName)))
                          .toList(),
                      onChanged: (val) => setState(() => _dietaryType = val ?? DietaryType.vegetarian),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pricing & Portions
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Standard Price (₹) *',
                        hintText: '150',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountedPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ExtraBite Price (₹) *',
                        hintText: '60',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _portionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Portions *',
                        hintText: '6',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Strict Pay at Pickup Banner
              const PayAtPickupBadge(showDescription: true),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Meal Description & Items Included',
                  hintText: 'e.g. Includes 3 rotis, paneer sabzi, rice, dal, and curd packed in meal boxes.',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Pickup Instructions
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Instructions for Students / Customers',
                  hintText: 'e.g. Enter through Gate 2, show QR code at dining counter.',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              CustomButton(
                label: 'Publish Surplus Meal',
                onPressed: _submit,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
