import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/food_listing.dart';
import '../../providers/food_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/location_provider.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _portionsController = TextEditingController(text: '10');
  final _originalPriceController = TextEditingController(text: '120');
  final _pickupPriceController = TextEditingController(text: '40');

  String _category = 'Dinner';
  bool _isVeg = true;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final userState = ref.read(userProvider);
      final locationState = ref.read(locationProvider);
      final now = DateTime.now();

      final newListing = FoodListing(
        id: 'food_${now.millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        pgName: userState.pgName,
        description: _descriptionController.text.trim(),
        availablePortions: int.parse(_portionsController.text.trim()),
        totalPortions: int.parse(_portionsController.text.trim()),
        originalPrice: double.parse(_originalPriceController.text.trim()),
        pickupPrice: double.parse(_pickupPriceController.text.trim()),
        isVeg: _isVeg,
        category: _category,
        latitude: locationState.latitude + 0.002, // Close by
        longitude: locationState.longitude + 0.003,
        address: '#45, PG Mess Road, Koramangala 5th Block',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 3)),
        imageUrl: _selectedImage != null
            ? _selectedImage!.path
            : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop',
      );

      ref.read(foodProvider.notifier).addListing(newListing);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Extra food listing posted successfully!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Surplus Meal'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take Photo with Camera'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[400]!),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(File(_selectedImage!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: Color(0xFF2E7D32)),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload food photo',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Meal Title',
                  hintText: 'e.g. Paneer Butter Masala & Rotis',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description & Items Included',
                  hintText: 'e.g. 4 butter rotis, paneer gravy, rice.',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter description'
                    : null,
              ),
              const SizedBox(height: 16),

              // Category & Veg/Non-Veg Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        _isVeg ? 'VEG' : 'NON-VEG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isVeg ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      Switch(
                        value: _isVeg,
                        activeColor: Colors.green,
                        onChanged: (val) => setState(() => _isVeg = val),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Portion Count & Pricing Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _portionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Portions Left',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pickupPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Price (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pay at pickup callout badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payments, color: Color(0xFF2E7D32)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Customers will pay this exact amount to you in person at pickup.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish Extra Food Listing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
