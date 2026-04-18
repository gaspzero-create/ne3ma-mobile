import 'dart:convert' as convert;
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/providers/location_provider.dart';
import 'package:ne3ma/core/services/image_upload_service.dart';
import 'package:ne3ma/features/donations/data/models/donation_model.dart';
import 'package:ne3ma/features/donations/data/models/category_model.dart';
import 'package:ne3ma/features/donations/presentation/widgets/location_picker_widget.dart';
import 'package:ne3ma/features/donations/providers/add_donation_form_provider.dart';
import 'package:ne3ma/features/donations/providers/category_provider.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';
import 'package:ne3ma/features/donations/utils/category_utils.dart';

// ─── Colour tokens (match the design) ─────────────────────────────────────────
const _kGreen = Color(0xFF6B8E4E);
const _kGreenLight = Color(0xFFE8F0E1);
const _kBg = Color(0xFFF5F5F0);
const _kFieldBg = Color(0xFFEFEFEA);
const _kTextDark = Color(0xFF1C1C1E);
const _kTextGrey = Color(0xFF9E9E9E);
const _kMapBg = Color(0xFFDFDFD8);

// Backend enum uses DROP and PICKUP, keep the old UI labels.
const _pickupTypes = ['DROP', 'PICKUP'];

class AddDonationScreen extends ConsumerStatefulWidget {
  const AddDonationScreen({
    super.key,
    this.initialDonation,
  });

  final DonationModel? initialDonation;

  @override
  ConsumerState<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends ConsumerState<AddDonationScreen> {
  XFile? _imageFile;
  String? _imageBase64;
  String? _existingImageUrl;
  bool _isUploadingImage = false;
  bool _checklistConfirmed = true;
  String? _category;
  String _pickupType = _pickupTypes[1];
  DateTime? _expiryDate;
  double? _selectedLat;
  double? _selectedLng;

  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _descFocus = FocusNode();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool get _isEditMode => widget.initialDonation != null;
  DonationModel? get _initialDonation => widget.initialDonation;

  Uint8List? get _savedImageBytes {
    final base64 = _imageBase64;
    if (base64 == null || base64.isEmpty) return null;

    try {
      return convert.base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    final location = ref.read(locationProvider);
    final initialDonation = _initialDonation;

    if (_isEditMode && initialDonation != null) {
      _nameCtrl.text = initialDonation.title;
      _quantityCtrl.text = initialDonation.quantity;
      _descCtrl.text = initialDonation.description ?? '';
      _category = initialDonation.categoryId;
      _pickupType = initialDonation.pickupType;
      _expiryDate = DateTime.tryParse(initialDonation.expiresAt)?.toLocal();
      _checklistConfirmed = initialDonation.checklistConfirmed ?? true;
      _selectedLat = initialDonation.lat ?? location.safeLat;
      _selectedLng = initialDonation.lng ?? location.safeLng;
      _existingImageUrl = initialDonation.imageUrl;
    } else {
      final saved = ref.read(addDonationFormProvider);
      _nameCtrl.text = saved.title;
      _quantityCtrl.text = saved.quantity;
      _descCtrl.text = saved.description;
      _category = saved.category.isEmpty ? null : saved.category;
      _pickupType = saved.pickupType;
      _expiryDate = saved.expiresAt.isEmpty
          ? null
          : DateTime.tryParse(saved.expiresAt);
      _imageBase64 = saved.imageBase64;
      _checklistConfirmed = saved.checklistConfirmed;
      _selectedLat = location.safeLat;
      _selectedLng = location.safeLng;

      _nameCtrl.addListener(() {
        ref.read(addDonationFormProvider.notifier).setTitle(_nameCtrl.text);
      });
      _quantityCtrl.addListener(() {
        ref
            .read(addDonationFormProvider.notifier)
            .setQuantity(_quantityCtrl.text);
      });
      _descCtrl.addListener(() {
        ref.read(addDonationFormProvider.notifier).setDescription(_descCtrl.text);
      });
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _quantityFocus.dispose();
    _descFocus.dispose();
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
      ref
          .read(addDonationFormProvider.notifier)
          .setExpiresAt(picked.toIso8601String());
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    setState(() {
      _imageFile = file;
      _isUploadingImage = true;
    });

    try {
      final compressedFile = await ImageUploadService.compressImage(
        File(file.path),
      );
      final bytes = await compressedFile.readAsBytes();
      final base64String = convert.base64Encode(bytes);

      setState(() {
        _imageBase64 = base64String;
        _isUploadingImage = false;
      });
      ref.read(addDonationFormProvider.notifier).setImageBase64(base64String);
      debugPrint('✅ AddDonation: Image compressed - ${bytes.length} bytes');
    } catch (e) {
      debugPrint('❌ AddDonation: Image compression failed - $e');
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image compression failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kGreen),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kGreen),
              title: const Text('Take a photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? _validateForm() {
    if (_imageBase64 == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      return 'Please add a picture.';
    }
    if (_nameCtrl.text.trim().isEmpty) return 'Please enter a name.';
    if (_category == null) return 'Please select a category.';
    if (_quantityCtrl.text.trim().isEmpty) return 'Please enter a quantity.';
    if (_expiryDate == null) return 'Please pick an expiry date.';
    return null;
  }

  void _restoreSavedCategory(List<CategoryModel> categories) {
    if (_isEditMode) return;

    final selectedCategory = _category;
    if (selectedCategory == null || selectedCategory.isEmpty) return;

    final alreadyResolved = categories.any((category) {
      return category.id == selectedCategory;
    });
    if (alreadyResolved) return;

    CategoryModel? resolvedCategory;
    for (final category in categories) {
      if (matchesStoredCategory(
        storedValue: selectedCategory,
        categoryId: category.id,
        categoryName: category.name,
      )) {
        resolvedCategory = category;
        break;
      }
    }

    if (resolvedCategory == null) return;
    final matchedCategory = resolvedCategory;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _category == matchedCategory.id) return;
      setState(() => _category = matchedCategory.id);
      ref
          .read(addDonationFormProvider.notifier)
          .setCategory(matchedCategory.id);
    });
  }

  Future<void> _publish() async {
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for image to finish uploading...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final error = _validateForm();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final expiresAt = _expiryDate!.toIso8601String();
    final location = ref.read(locationProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode ? 'Updating donation...' : 'Creating donation...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
      ),
    );

    final notifier = ref.read(donationsProvider.notifier);
    final success = _isEditMode
        ? await notifier.updateDonation(
            id: _initialDonation!.id,
            title: _nameCtrl.text.trim(),
            categoryId: _category!,
            pickupType: _pickupType,
            quantity: _quantityCtrl.text.trim(),
            expiresAt: expiresAt,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            imageBase64: _imageBase64,
            lat: _selectedLat ?? location.safeLat,
            lng: _selectedLng ?? location.safeLng,
            checklistConfirmed: _checklistConfirmed,
          )
        : await notifier.createDonation(
            title: _nameCtrl.text.trim(),
            categoryId: _category!,
            pickupType: _pickupType,
            quantity: _quantityCtrl.text.trim(),
            expiresAt: expiresAt,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            imageBase64: _imageBase64,
            lat: _selectedLat ?? location.safeLat,
            lng: _selectedLng ?? location.safeLng,
            checklistConfirmed: _checklistConfirmed,
          );

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? '✅ Donation updated successfully!'
                : '✅ Donation published successfully! 🎉',
          ),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      if (!_isEditMode) {
        ref.read(addDonationFormProvider.notifier).reset();
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.maybePop(context);
      });
    } else {
      final state = ref.read(donationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Error: ${state.error ?? (_isEditMode ? "Failed to update donation" : "Failed to create donation")}',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationsProvider);
    final categoriesAsync = ref.watch(donationCategoriesProvider);
    final categories = categoriesAsync.value ?? const <CategoryModel>[];

    _restoreSavedCategory(categories);

    final screenHeight = MediaQuery.of(context).size.height;
    final responsiveSpacerHeight = math.max(80.0, screenHeight * 0.12);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _kTextDark,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _isEditMode ? 'Update donation' : 'Add a post',
          style: const TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePickerCard(
                    imageFile: _imageFile,
                    imageBytes: _savedImageBytes,
                    imageUrl: _existingImageUrl,
                    onTap: _showImageSourceSheet,
                    onRemove: () => setState(() {
                      _imageFile = null;
                      _imageBase64 = null;
                      _existingImageUrl = null;
                      if (!_isEditMode) {
                        ref
                            .read(addDonationFormProvider.notifier)
                            .setImageBase64(null);
                      }
                    }),
                  ),
                  const SizedBox(height: 24),
                  const _FieldLabel('Name'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    hint: 'Homemade cupcakes',
                    nextFocus: _quantityFocus,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Category'),
                            const SizedBox(height: 8),
                            _CategoryDropdown(
                              value: _category,
                              categories: categories,
                              isLoading: categoriesAsync.isLoading,
                              onChanged: (v) {
                                setState(() => _category = v);
                                if (v != null) {
                                  ref
                                      .read(addDonationFormProvider.notifier)
                                      .setCategory(v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Quantity'),
                            const SizedBox(height: 8),
                            _AppTextField(
                              controller: _quantityCtrl,
                              focusNode: _quantityFocus,
                              hint: '2.5 kg ...',
                              nextFocus: _descFocus,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Expiry Date'),
                  const SizedBox(height: 8),
                  _DateField(date: _expiryDate, onTap: _pickDate),
                  const SizedBox(height: 20),
                  const _FieldLabel('Description'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _descCtrl,
                    focusNode: _descFocus,
                    hint: 'Optional details about the donation…',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Pickup type'),
                  const SizedBox(height: 8),
                  _PickupTypeSelector(
                    value: _pickupType,
                    onChanged: (v) {
                      setState(() => _pickupType = v);
                      ref
                          .read(addDonationFormProvider.notifier)
                          .setPickupType(v);
                    },
                  ),
                  const SizedBox(height: 24),
                  _MapVisualizationCard(
                    initialLat: _selectedLat,
                    initialLng: _selectedLng,
                    onLocationSelected: (lat, lng) {
                      debugPrint(
                        '📍 AddDonation: Location selected = $lat, $lng',
                      );
                      setState(() {
                        _selectedLat = lat;
                        _selectedLng = lng;
                      });
                    },
                  ),
                  SizedBox(height: responsiveSpacerHeight),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PublishBar(
                isLoading: state.isLoading,
                label: _isEditMode ? 'Update' : 'Publish',
                onPublish: _publish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _kTextDark,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),
  );
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final FocusNode? nextFocus;
  final int maxLines;

  const _AppTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.nextFocus,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      maxLines: maxLines,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          focusNode.unfocus();
        }
      },
      style: const TextStyle(color: _kTextDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextGrey, fontSize: 15),
        filled: true,
        fillColor: _kFieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: _kGreen, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: _kGreen, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: _kGreen, width: 2),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? value;
  final List<CategoryModel> categories;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = categories.any((category) => category.id == value)
        ? value
        : null;
    final hint = isLoading
        ? 'Loading...'
        : categories.isEmpty
        ? 'No categories'
        : 'Select';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kFieldBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kGreen, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Text(
            hint,
            style: const TextStyle(color: _kTextGrey, fontSize: 15),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kGreen),
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: _kTextDark, fontSize: 15),
          items: categories
              .map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(displayCategoryLabel(category.name)),
                ),
              )
              .toList(),
          onChanged: isLoading || categories.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

class _PickupTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PickupTypeSelector({required this.value, required this.onChanged});

  static const _labels = {'DROP': 'Delivery', 'PICKUP': 'Pickup'};

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _pickupTypes.map((type) {
        final selected = type == value;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _kGreen : _kFieldBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _kGreen, width: 1.2),
              ),
              child: Text(
                _labels[type]!,
                style: TextStyle(
                  color: selected ? Colors.white : _kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = date != null
        ? DateFormat('dd/MM/yy').format(date!)
        : 'dd/mm/yy';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kFieldBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _kGreen, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: date != null ? _kTextDark : _kTextGrey,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: _kTextGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final XFile? imageFile;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImagePickerCard({
    required this.imageFile,
    required this.imageBytes,
    this.imageUrl,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: _kGreenLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGreen, width: 1.5),
        ),
        child: imageFile != null || imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty)
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageFile != null
                        ? Image.file(File(imageFile!.path), fit: BoxFit.cover)
                        : imageBytes != null
                        ? Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: _kGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add a picture',
          style: TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Required',
          style: TextStyle(color: _kTextGrey, fontSize: 13),
        ),
      ],
    );
  }
}

class _MapVisualizationCard extends StatelessWidget {
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng) onLocationSelected;

  const _MapVisualizationCard({
    required this.initialLat,
    required this.initialLng,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Add a little extra bottom margin so the card isn't cut off while scrolling
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _kMapBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          LocationPickerWidget(
            initialLat: initialLat,
            initialLng: initialLng,
            onLocationSelected: onLocationSelected,
            showHint: false,
          ),
        ],
      ),
    );
  }
}

class _PublishBar extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPublish;

  const _PublishBar({
    required this.isLoading,
    required this.label,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _kBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPublish,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen,
            disabledBackgroundColor: _kGreen.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
