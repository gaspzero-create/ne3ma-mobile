import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/features/profile/data/model/profile_model.dart';
import 'package:ne3ma/features/profile/provider/profile_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/providers/auth_provider.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile      = profileState.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: profileState.isLoading && profile == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryMid),
            )
          : _buildBody(context, ref, profile),
    );
  }

  // ── AppBar ─────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Body ───────────────────────────────────────
  Widget _buildBody(BuildContext context, WidgetRef ref, ProfileModel? profile) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.md,
      ),
      children: [

        // ── Profile Header ───────────────────────
        _buildProfileHeader(profile),
        const SizedBox(height: AppSizes.xl),

        // ── Account Section ──────────────────────
        _SectionLabel(label: 'Account'),
        const SizedBox(height: AppSizes.sm),
        _SettingsCard(
          items: [
            _SettingsItem(
              icon: Icons.person_outline_rounded,
              label: 'Edit profile',
              onTap: () => context.go('/profile'),
            ),
            _SettingsItem(
              icon: Icons.security_outlined,
              label: 'Security',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.lock_outline_rounded,
              label: 'Privacy',
              onTap: () {},
              showDivider: false,
            ),
          ],
        ),

        const SizedBox(height: AppSizes.lg),

        // ── Support & About Section ──────────────
        _SectionLabel(label: 'Support & About'),
        const SizedBox(height: AppSizes.sm),
        _SettingsCard(
          items: [
            _SettingsItem(
              icon: Icons.credit_card_outlined,
              label: 'My Subscription',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              label: 'Terms and Policies',
              onTap: () {},
              showDivider: false,
            ),
          ],
        ),

        const SizedBox(height: AppSizes.lg),

        // ── Actions Section ──────────────────────
        _SectionLabel(label: 'Actions'),
        const SizedBox(height: AppSizes.sm),
        _SettingsCard(
          items: [
            _SettingsItem(
              icon: Icons.flag_outlined,
              label: 'Report a problem',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.logout_rounded,
              label: 'Log out',
              labelColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => _showLogoutDialog(context, ref),
              showDivider: false,
            ),
          ],
        ),

        const SizedBox(height: AppSizes.xl),
      ],
    );
  }

  // ── Profile Header ─────────────────────────────
  Widget _buildProfileHeader(ProfileModel? profile) {
    return Row(
      children: [
        // ── Avatar ──────────────────────────────
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: ClipOval(
            child: _buildAvatarImage(profile?.avatarUrl),
          ),
        ),
        const SizedBox(width: AppSizes.md),

        // ── Name & Email ─────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.fullName ?? '...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile?.email ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Avatar Image ───────────────────────────────
  Widget _buildAvatarImage(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        width: 60,
        height: 60,
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
          debugPrint('❌ Settings: Avatar load error - $error');
          return const Icon(
            Icons.person_rounded,
            size: 34,
            color: AppColors.textHint,
          );
        },
      );
    }

    return const Icon(
      Icons.person_rounded,
      size: 34,
      color: AppColors.textHint,
    );
  }

  // ── Logout Dialog ──────────────────────────────
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text(
          'Log out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              debugPrint('📤 Settings: Logging out...');
              await ref.read(authProvider.notifier).logout();
              debugPrint('✅ Settings: Logged out');
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Log out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Settings Card ──────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.items});
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(children: items),
    );
  }
}

// ── Settings Item ──────────────────────────────────────
class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.showDivider = true,
  });

  final IconData    icon;
  final String      label;
  final VoidCallback onTap;
  final Color?      labelColor;
  final Color?      iconColor;
  final bool        showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? AppColors.textPrimary,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: labelColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.md + 22 + AppSizes.md,
            ),
            child: Divider(
              height: 1,
              color: AppColors.border.withOpacity(0.6),
            ),
          ),
      ],
    );
  }
}