import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/l10n/generated/app_localizations.dart';
import 'package:ne3ma/features/donations/providers/add_donation_form_provider.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';
import 'package:ne3ma/features/profile/data/model/profile_model.dart';
import 'package:ne3ma/features/profile/provider/profile_provider.dart';
import 'package:ne3ma/core/providers/locale_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

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
      title: Text(
        AppLocalizations.of(context).settings,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Body ───────────────────────────────────────
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ProfileModel? profile,
  ) {
    final loc = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.only(
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        top: AppSizes.md,
        bottom: AppSizes.xl + 80, // Extra padding for bottom nav bar
      ),
      children: [
        // ── Profile Header ───────────────────────
        _buildProfileHeader(profile),
        const SizedBox(height: AppSizes.xl),

        // ── Account Section ──────────────────────
        _SectionLabel(label: loc.account),
        const SizedBox(height: AppSizes.sm),
        _SettingsCard(
          items: [
            _SettingsItem(
              icon: Icons.person_outline_rounded,
              label: loc.editProfile,
              onTap: () async => context.push('/profile'),
            ),
            _SettingsItem(
              icon: Icons.leaderboard_rounded,
              label: 'Leaderboard',
              onTap: () async => context.push('/leaderboard'),
            ),
            _SettingsItem(
              icon: Icons.language_rounded,
              label: loc.language,
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => const _LanguageSelectionSheet(),
                );
              },
            ),
            _SettingsItem(
              icon: Icons.lock_outline_rounded,
              label: loc.privacy,
              onTap: () async => context.push('/privacy-policy'),
              showDivider: false,
            ),
          ],
        ),

        const SizedBox(height: AppSizes.lg),

        // ── Support & About Section ──────────────
        _SectionLabel(label: loc.supportAndAbout),
        const SizedBox(height: AppSizes.sm),
        _SettingsCard(
          items: [
            _SettingsItem(
              icon: Icons.help_outline_rounded,
              label: loc.helpAndSupport,
              onTap: () async => context.push('/help-support'),
            ),
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              label: loc.termsAndPolicies,
              onTap: () async => context.push('/terms-and-conditions'),
              showDivider: false,
            ),
          ],
        ),

        const SizedBox(height: AppSizes.lg),

        // ── Actions Section ──────────────────────
        _SectionLabel(label: loc.actions),
        const SizedBox(height: AppSizes.sm),
        _SettingsCard(
          items: [
            _SettingsItem(
              icon: Icons.flag_outlined,
              label: loc.reportProblem,
              onTap: () async {},
            ),
            _SettingsItem(
              icon: Icons.bug_report_outlined,
              label: 'Push debug',
              onTap: () async => context.push('/push-debug'),
            ),
            _SettingsItem(
              icon: Icons.logout_rounded,
              label: loc.logOut,
              labelColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () async {
                final shouldLogout = await _showLogoutConfirmDialog(context);
                if (shouldLogout && context.mounted) {
                  ref.read(profileProvider.notifier).clearProfile();
                  ref.read(donationsProvider.notifier).clearSessionData();
                  ref.read(addDonationFormProvider.notifier).reset();
                  await ref.read(authProvider.notifier).logout();
                  ref.invalidate(profileProvider);
                  ref.invalidate(donationsProvider);
                  ref.invalidate(addDonationFormProvider);
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
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
          child: ClipOval(child: _buildAvatarImage(profile?.avatarUrl)),
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

  // ── Logout Confirmation Dialog ──────────────────
  Future<bool> _showLogoutConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface,
          title: const Text(
            'Log Out?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out? You\'ll need to sign in again to access your account.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
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

  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;
  final Color? labelColor;
  final Color? iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap != null ? () async => await onTap!() : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor ?? AppColors.textPrimary),
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
              color: AppColors.border.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}

// ── Language Selection Sheet ───────────────────────────
class _LanguageSelectionSheet extends ConsumerStatefulWidget {
  const _LanguageSelectionSheet();

  @override
  ConsumerState<_LanguageSelectionSheet> createState() =>
      _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState
    extends ConsumerState<_LanguageSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.selectLanguage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageOption('English', 'en', currentLocale),
          _buildLanguageOption('العربية', 'ar', currentLocale),
          _buildLanguageOption('Français', 'fr', currentLocale),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String title, String code, Locale currentLocale) {
    final isSelected = currentLocale.languageCode == code;
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) Navigator.pop(context);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
