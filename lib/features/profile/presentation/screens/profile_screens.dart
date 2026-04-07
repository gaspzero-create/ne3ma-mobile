import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/features/profile/provider/profile_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/image_upload_service.dart';


class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController  = TextEditingController();

  String? _selectedWilaya;
  String? _selectedBaladiya;

  // ── Avatar state ───────────────────────────────
  File?   _localImageFile;       // picked but not yet uploaded
  String? _uploadedAvatarUrl;    // already uploaded URL
  bool    _isUploadingImage = false;
  bool    _isSaving         = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).profile;
      if (profile != null) {
        debugPrint('📋 EditProfile: Pre-filling - ${profile.fullName}');
        _nameController.text = profile.fullName;
        _bioController.text  = profile.bio ?? '';
        setState(() {
          _selectedWilaya    = profile.wilaya;
          _selectedBaladiya  = profile.baladiya;
          _uploadedAvatarUrl = profile.avatarUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Pick & upload avatar ───────────────────────
  Future<void> _onPickAvatar() async {
    debugPrint('🖼️ EditProfile: Starting avatar pick...');
    try {
      setState(() => _isUploadingImage = true);

      final file = await ImageUploadService.pickFromGallery();
      if (file == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      // Show local preview immediately
      setState(() => _localImageFile = file);
      debugPrint('✅ EditProfile: Local preview set');

      // Compress + Upload in background
      final compressed = await ImageUploadService.compressImage(file);
      final url = await ImageUploadService.uploadToCloudinary(compressed);

      setState(() {
        _uploadedAvatarUrl = url;
        _isUploadingImage  = false;
      });
      debugPrint('✅ EditProfile: Avatar uploaded - $url');

    } catch (e) {
      debugPrint('❌ EditProfile: Avatar upload failed - $e');
      setState(() {
        _localImageFile   = null;
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Save profile ───────────────────────────────
  Future<void> _onSave() async {
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for image to finish uploading...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    debugPrint('📤 EditProfile: Saving...');
    debugPrint('📝 Name: ${_nameController.text}');
    debugPrint('🖼️ Avatar URL: $_uploadedAvatarUrl');

    setState(() => _isSaving = true);

    final success = await ref.read(profileProvider.notifier).updateProfile(
      fullName:  _nameController.text.trim(),
      bio:       _bioController.text.trim(),
      avatarUrl: _uploadedAvatarUrl,
      wilaya:    _selectedWilaya,
      baladiya:  _selectedBaladiya,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      debugPrint('✅ EditProfile: Saved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated!'),
          backgroundColor: AppColors.primaryMid,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      );
      context.go('/profile-tab');
    } else {
      final error = ref.read(profileProvider).error;
      debugPrint('❌ EditProfile: Error - $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Update failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding,
          vertical: AppSizes.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Avatar ──────────────────────────────
            _buildAvatar(),
            const SizedBox(height: AppSizes.xl),

            // ── Full Name ────────────────────────────
            _buildLabel('Name'),
            const SizedBox(height: AppSizes.sm),
            _buildTextField(
              controller: _nameController,
              hint: 'Your Name',
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Bio ──────────────────────────────────
            _buildLabel('Bio'),
            const SizedBox(height: AppSizes.sm),
            _buildTextField(
              controller: _bioController,
              hint: 'Tell us about yourself',
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Wilaya ───────────────────────────────
            _buildLabel('Wilaya'),
            const SizedBox(height: AppSizes.sm),
            _buildDropdownField(
              value: _selectedWilaya,
              hint: 'Select wilaya',
              onTap: () => _showWilayaPicker(context),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Baladiya ─────────────────────────────
            _buildLabel('Baladiya'),
            const SizedBox(height: AppSizes.sm),
            _buildDropdownField(
              value: _selectedBaladiya,
              hint: 'Select baladiya',
              onTap: () => _showBaladiyaPicker(context),
            ),
            const SizedBox(height: AppSizes.xxxl),

            // ── Save Button ──────────────────────────
            _buildSaveButton(),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => context.go('/settings'),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ── Avatar widget ──────────────────────────────
  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          // ── Circle image ───────────────────────────
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: ClipOval(
              child: _buildAvatarImage(),
            ),
          ),

          // ── Upload loading overlay ─────────────────
          if (_isUploadingImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.4),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // ── Camera button ──────────────────────────
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _onPickAvatar,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isUploadingImage
                      ? AppColors.textHint
                      : AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar image logic ─────────────────────────
  Widget _buildAvatarImage() {
    // 1. Show local file preview first (just picked)
    if (_localImageFile != null) {
      return Image.file(
        _localImageFile!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }

    // 2. Show network image (from backend)
    if (_uploadedAvatarUrl != null && _uploadedAvatarUrl!.isNotEmpty) {
      return Image.network(
        _uploadedAvatarUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryMid,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person_rounded,
            size: 60,
            color: AppColors.textHint,
          );
        },
      );
    }

    // 3. Placeholder
    return const Icon(
      Icons.person_rounded,
      size: 60,
      color: AppColors.textHint,
    );
  }

  // ── Label ──────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ── Text Field ─────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 15,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            maxLines > 1 ? AppSizes.radiusLg : AppSizes.radiusFull,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            maxLines > 1 ? AppSizes.radiusLg : AppSizes.radiusFull,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            maxLines > 1 ? AppSizes.radiusLg : AppSizes.radiusFull,
          ),
          borderSide: const BorderSide(
            color: AppColors.primaryMid,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Dropdown Field ─────────────────────────────
  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 15,
                color: value != null
                    ? AppColors.textSecondary
                    : AppColors.textHint,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Save Button ────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: (_isSaving || _isUploadingImage) ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMid,
          disabledBackgroundColor: AppColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _isUploadingImage ? 'Uploading image...' : 'Save changes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ── Wilaya picker ──────────────────────────────
  void _showWilayaPicker(BuildContext context) {
    final wilayas = [
      'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna',
      'Béjaïa', 'Biskra', 'Béchar', 'Blida', 'Bouira',
      'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret', 'Tizi Ouzou',
      'Alger', 'Djelfa', 'Jijel', 'Sétif', 'Saïda',
      'Skikda', 'Sidi Bel Abbès', 'Annaba', 'Guelma', 'Constantine',
      'Médéa', 'Mostaganem', 'M\'Sila', 'Mascara', 'Ouargla',
      'Oran', 'El Bayadh', 'Illizi', 'Bordj Bou Arréridj', 'Boumerdès',
      'El Tarf', 'Tindouf', 'Tissemsilt', 'El Oued', 'Khenchela',
      'Souk Ahras', 'Tipaza', 'Mila', 'Aïn Defla', 'Naâma',
      'Aïn Témouchent', 'Ghardaïa', 'Relizane',
    ];
    _showBottomSheet(
      context: context,
      title: 'Wilaya',
      options: wilayas,
      selected: _selectedWilaya,
      onSelect: (val) => setState(() => _selectedWilaya = val),
    );
  }

  void _showBaladiyaPicker(BuildContext context) {
    _showBottomSheet(
      context: context,
      title: 'Baladiya',
      options: ['Centre', 'Nord', 'Sud', 'Est', 'Ouest'],
      selected: _selectedBaladiya,
      onSelect: (val) => setState(() => _selectedBaladiya = val),
    );
  }

  void _showBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: AppSizes.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: options.map((opt) => ListTile(
                  title: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: opt == selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: opt == selected
                          ? AppColors.primaryMid
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: opt == selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryMid,
                        )
                      : null,
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(ctx);
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}