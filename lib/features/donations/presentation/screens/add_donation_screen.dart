import 'dart:io';
import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ne3ma/features/donations/providers/add_donation_form_provider.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';
import 'package:ne3ma/core/services/image_upload_service.dart';
import 'package:ne3ma/core/constants/app_colors.dart';

// ─── Colour tokens (match the design) ─────────────────────────────────────────
const _kGreen      = Color(0xFF6B8E4E);
const _kGreenLight = Color(0xFFE8F0E1);
const _kBg         = Color(0xFFF5F5F0);
const _kFieldBg    = Color(0xFFEFEFEA);
const _kTextDark   = Color(0xFF1C1C1E);
const _kTextGrey   = Color(0xFF9E9E9E);
const _kMapBg      = Color(0xFFDFDFD8);

// Only use valid backend enum values for category
const _categories = [
  'DRY',     // Dry goods
  'FRESH',  // Fresh food
  'URGENT', // Urgent donations
];

// ─── Pickup types that map to the backend enum ────────────────────────────────
const _pickupTypes = ['DELIVERY', 'PICKUP',];

class AddPostScreen extends ConsumerStatefulWidget {
  const AddPostScreen({super.key});

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  // ── Local UI state ───────────────────────────────────────────────────────────
  XFile?    _imageFile;          // raw picked file
  String?   _imageBase64;        // compressed image as base64
  bool      _isUploadingImage = false;
  bool      _checklistConfirmed = true;
  String?   _category;
  String    _pickupType = _pickupTypes[1]; // default: PICKUP
  DateTime? _expiryDate;

  // ── Form controllers & focus nodes ──────────────────────────────────────────
  final _formKey      = GlobalKey<FormState>();
  final _nameFocus    = FocusNode();
  final _quantityFocus = FocusNode();
  final _descFocus    = FocusNode();
  final _nameCtrl     = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();

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
    // Prefill from saved provider state so form survives navigation
    final saved = ref.read(addDonationFormProvider);
    _nameCtrl.text = saved.title;
    _quantityCtrl.text = saved.quantity;
    _descCtrl.text = saved.description;
    _category = saved.category.isEmpty ? null : saved.category;
    _pickupType = saved.pickupType;
    _expiryDate = saved.expiresAt.isEmpty ? null : DateTime.tryParse(saved.expiresAt);
    _imageBase64 = saved.imageBase64;
    _checklistConfirmed = saved.checklistConfirmed;

    // Sync local controllers back to provider on every change
    _nameCtrl.addListener(() {
      ref.read(addDonationFormProvider.notifier).setTitle(_nameCtrl.text);
    });
    _quantityCtrl.addListener(() {
      ref.read(addDonationFormProvider.notifier).setQuantity(_quantityCtrl.text);
    });
    _descCtrl.addListener(() {
      ref.read(addDonationFormProvider.notifier).setDescription(_descCtrl.text);
    });
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

  // ── Date picker ──────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: now,
      firstDate:   now,
      lastDate:    DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   _kGreen,
            onPrimary: Colors.white,
            surface:   Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
      ref.read(addDonationFormProvider.notifier).setExpiresAt(picked.toIso8601String());
    }
  }

  // ── Image picker ─────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    setState(() {
      _imageFile = file;
      _isUploadingImage = true;
    });

    try {
      // Compress image and convert to base64
      final compressedFile = await ImageUploadService.compressImage(File(file.path));
      final bytes = await compressedFile.readAsBytes();
      final base64String = convert.base64Encode(bytes);
      
      setState(() {
        _imageBase64 = base64String;
        _isUploadingImage = false;
      });
      // Persist image to provider so it survives navigation
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
              width: 40, height: 4,
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

  // ── Validation ───────────────────────────────────────────────────────────────
  String? _validateForm() {
    if (_imageBase64 == null)               return 'Please add a picture.';
    if (_nameCtrl.text.trim().isEmpty)      return 'Please enter a name.';
    if (_category == null)                  return 'Please select a category.';
    if (_quantityCtrl.text.trim().isEmpty)  return 'Please enter a quantity.';
    if (_expiryDate == null)                return 'Please pick an expiry date.';
    if (!_checklistConfirmed)               return 'Please confirm the checklist.';
    return null;
  }

  // ── Publish ──────────────────────────────────────────────────────────────────
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

    // ISO-8601 string required by the backend
    final expiresAt = _expiryDate!.toIso8601String();

    // Show loading indicator while creating donation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating donation...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 30), // Auto-hide after 30s if success
      ),
    );

    // Wait for the donation to be created
    final success = await ref.read(donationsProvider.notifier).createDonation(
      title:              _nameCtrl.text.trim(),
      category:           _category!,
      pickupType:         _pickupType,
      quantity:           _quantityCtrl.text.trim(),
      expiresAt:          expiresAt,
      description:        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      imageBase64:        _imageBase64,
      checklistConfirmed: _checklistConfirmed,
    );

    if (!mounted) return;

    // Clear the loading snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show result based on success
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('✅ Donation published successfully! 🎉'),
          backgroundColor: _kGreen,
          behavior:        SnackBarBehavior.floating,
          duration:        Duration(seconds: 3),
        ),
      );
      // Close the screen after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.maybePop(context);
      });
    } else {
      // Read error from state
      final state = ref.read(donationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('❌ Error: ${state.error ?? "Failed to create donation"}'),
          backgroundColor: Colors.redAccent,
          behavior:        SnackBarBehavior.floating,
          duration:        const Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kTextDark, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Add a post',
          style: TextStyle(
            color:      _kTextDark,
            fontWeight: FontWeight.w700,
            fontSize:   20,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            // ── Scrollable form ──────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image picker ───────────────────────────────────────────
                  _ImagePickerCard(
                    imageFile: _imageFile,
                    imageBytes: _savedImageBytes,
                    onTap: _showImageSourceSheet,
                    onRemove: () => setState(() {
                      _imageFile = null;
                      _imageBase64 = null;
                      ref.read(addDonationFormProvider.notifier).setImageBase64(
                        null,
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // 2. Name ───────────────────────────────────────────────────
                  const _FieldLabel('Name'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller:  _nameCtrl,
                    focusNode:   _nameFocus,
                    hint:        'Homemade cupcakes',
                    nextFocus:   _quantityFocus,
                  ),
                  const SizedBox(height: 20),

                  // 3. Category + Quantity ────────────────────────────────────
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
                              value:     _category,
                              onChanged: (v) {
                                setState(() => _category = v);
                                if (v != null) {
                                  ref.read(addDonationFormProvider.notifier).setCategory(v);
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
                              focusNode:  _quantityFocus,
                              hint:       '2.5 kg ...',
                              nextFocus:  _descFocus,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Expiry Date ────────────────────────────────────────────
                  const _FieldLabel('Expiry Date'),
                  const SizedBox(height: 8),
                  _DateField(date: _expiryDate, onTap: _pickDate),
                  const SizedBox(height: 20),

                  // 5. Description ────────────────────────────────────────────
                  const _FieldLabel('Description'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _descCtrl,
                    focusNode:  _descFocus,
                    hint:       'Optional details about the donation…',
                    maxLines:   3,
                  ),
                  const SizedBox(height: 20),

                  // 6. Pickup type ────────────────────────────────────────────
                  const _FieldLabel('Pickup type'),
                  const SizedBox(height: 8),
                  _PickupTypeSelector(
                    value:     _pickupType,
                    onChanged: (v) {
                      setState(() => _pickupType = v);
                      ref.read(addDonationFormProvider.notifier).setPickupType(v);
                    },
                  ),
                  const SizedBox(height: 24),

                  // 7. Map visualization ──────────────────────────────────────
                  const _MapVisualizationCard(),
                  const SizedBox(height: 24),

                  // 8. Checklist confirmation ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kGreenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGreen, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Donation Checklist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '✓ Food is in good condition\n✓ Expiry date is correct\n✓ Properly packaged\n✓ Ready for pickup/delivery',
                          style: TextStyle(
                            fontSize: 13,
                            color: _kTextGrey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _checklistConfirmed,
                              onChanged: (v) {
                                final isChecked = v ?? false;
                                setState(() => _checklistConfirmed = isChecked);
                                ref
                                    .read(addDonationFormProvider.notifier)
                                    .setChecklist(isChecked);
                              },
                              activeColor: _kGreen,
                              checkColor: Colors.white,
                            ),
                            const Expanded(
                              child: Text(
                                'I confirm all checklist items are met',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _kTextDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Publish button (pinned at bottom) ────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _PublishBar(
                isLoading: state.isLoading,
                onPublish: _publish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color:      _kTextDark,
          fontWeight: FontWeight.w600,
          fontSize:   15,
        ),
      );
}

// ── Generic text field ─────────────────────────────────────────────────────────
class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final String                hint;
  final FocusNode?            nextFocus;
  final TextInputType         keyboardType;
  final int                   maxLines;

  const _AppTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.nextFocus,
    this.keyboardType = TextInputType.text,
    this.maxLines     = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:      controller,
      focusNode:       focusNode,
      keyboardType:    keyboardType,
      maxLines:        maxLines,
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
        hintText:       hint,
        hintStyle:      const TextStyle(color: _kTextGrey, fontSize: 15),
        filled:         true,
        fillColor:      _kFieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   const BorderSide(color: _kGreen, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   const BorderSide(color: _kGreen, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   const BorderSide(color: _kGreen, width: 2),
        ),
      ),
    );
  }
}

// ── Category dropdown ──────────────────────────────────────────────────────────
class _CategoryDropdown extends StatelessWidget {
  final String?             value;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:        _kFieldBg,
        borderRadius: BorderRadius.circular(30),
        border:       Border.all(color: _kGreen, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:         value,
          hint:          const Text('Select',
              style: TextStyle(color: _kTextGrey, fontSize: 15)),
          icon:          const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kGreen),
          isExpanded:    true,
          dropdownColor: Colors.white,
          style:         const TextStyle(color: _kTextDark, fontSize: 15),
          items:         _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged:     onChanged,
        ),
      ),
    );
  }
}

// ── Pickup type selector ───────────────────────────────────────────────────────
class _PickupTypeSelector extends StatelessWidget {
  final String                value;
  final ValueChanged<String>  onChanged;

  const _PickupTypeSelector({required this.value, required this.onChanged});

  static const _labels = {
    'DELIVERY': 'Delivery',
    'PICKUP':   'Pickup',
    'BOTH':     'Both',
  };

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
                color:        selected ? _kGreen : _kFieldBg,
                borderRadius: BorderRadius.circular(30),
                border:       Border.all(color: _kGreen, width: 1.2),
              ),
              child: Text(
                _labels[type]!,
                style: TextStyle(
                  color:      selected ? Colors.white : _kTextDark,
                  fontSize:   14,
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

// ── Date field ─────────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final DateTime?   date;
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
          color:        _kFieldBg,
          borderRadius: BorderRadius.circular(30),
          border:       Border.all(color: _kGreen, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:    date != null ? _kTextDark : _kTextGrey,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: _kTextGrey),
          ],
        ),
      ),
    );
  }
}

// ── Image picker card ──────────────────────────────────────────────────────────
class _ImagePickerCard extends StatelessWidget {
  final XFile?       imageFile;
  final Uint8List?   imageBytes;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImagePickerCard({
    required this.imageFile,
    required this.imageBytes,
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
          color:        _kGreenLight,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: _kGreen, width: 1.5),
        ),
        child: imageFile != null || imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageFile != null
                        ? Image.file(
                            File(imageFile!.path),
                            fit: BoxFit.cover,
                          )
                        : Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.redAccent),
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
          width: 60, height: 60,
          decoration: const BoxDecoration(
              color: _kGreen, shape: BoxShape.circle),
          child: const Icon(Icons.camera_alt_outlined,
              color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        const Text('Add a picture',
            style: TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('Required',
            style: TextStyle(color: _kTextGrey, fontSize: 13)),
      ],
    );
  }
}

// ── Map visualization card ─────────────────────────────────────────────────────
class _MapVisualizationCard extends StatelessWidget {
  const _MapVisualizationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color:        _kMapBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🗺️', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Map visualization',
              style: TextStyle(
                  color: _kTextDark, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'Showing donation hotspots\nby wilaya',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextGrey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Publish bar ────────────────────────────────────────────────────────────────
class _PublishBar extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onPublish;

  const _PublishBar({required this.isLoading, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: _kBg,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPublish,
          style: ElevatedButton.styleFrom(
            backgroundColor:         _kGreen,
            disabledBackgroundColor: _kGreen.withOpacity(0.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'Publish',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize:   16,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
