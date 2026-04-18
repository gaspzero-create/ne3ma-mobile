import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/providers/location_provider.dart';
import 'package:ne3ma/features/donations/data/models/donation_model.dart';
import 'package:ne3ma/features/donations/presentation/screens/add_donation_screen.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';
import 'package:ne3ma/features/profile/data/model/profile_model.dart';
import 'package:ne3ma/features/profile/provider/profile_provider.dart';
import 'package:ne3ma/l10n/generated/app_localizations.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final _searchController = TextEditingController();
  final _carouselController = PageController();
  int _carouselIndex = 0;
  String? _locationCountry;
  String? _locationLabel;

  static const _filterOptions = <String?>[null, 'FRESH', 'DRY', 'URGENT', 'MY'];

  List<String> _getFilterLabels(AppLocalizations loc) {
    return [loc.all, loc.fresh, loc.dry, loc.urgent, loc.myDonations];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationProvider.notifier).fetchLocation();
      if (!mounted) return;

      final loc = ref.read(locationProvider);
      await _syncLocationHeader(loc);
      _fetchDonations(lat: loc.safeLat, lng: loc.safeLng);
      await ref.read(donationsProvider.notifier).fetchMyDonations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _syncLocationHeader(LocationState location) async {
    if (!location.hasLocation) {
      if (!mounted) return;
      setState(() {
        _locationCountry = null;
        _locationLabel = null;
      });
      return;
    }

    await _resolveLocationLabel(lat: location.lat!, lng: location.lng!);
  }

  Future<void> _resolveLocationLabel({
    required double lat,
    required double lng,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      final country = _firstNonEmpty([placemark?.country, 'Algeria']);
      final locality = _firstNonEmpty([
        placemark?.locality,
        placemark?.subAdministrativeArea,
        placemark?.subLocality,
      ]);
      final region = _firstNonEmpty([
        placemark?.administrativeArea,
        placemark?.subAdministrativeArea,
        placemark?.locality,
      ]);

      final labelParts = <String>[];
      if (locality != null) {
        labelParts.add(locality);
      }
      if (region != null && region != locality) {
        labelParts.add(region);
      }

      if (!mounted) return;
      setState(() {
        _locationCountry = country ?? 'Algeria';
        _locationLabel = labelParts.isEmpty ? null : labelParts.join(', ');
      });
    } catch (e) {
      debugPrint('❌ HomeTab: Reverse geocoding error - $e');
      if (!mounted) return;
      setState(() {
        _locationCountry = null;
        _locationLabel = null;
      });
    }
  }

  void _fetchDonations({required double lat, required double lng}) {
    ref
        .read(donationsProvider.notifier)
        .fetchNearbyDonations(lat: lat, lng: lng);
  }

  Future<void> _onRefresh() async {
    await ref.read(locationProvider.notifier).fetchLocation();
    final loc = ref.read(locationProvider);
    await _syncLocationHeader(loc);
    _fetchDonations(lat: loc.safeLat, lng: loc.safeLng);
    await ref.read(donationsProvider.notifier).fetchMyDonations();
  }

  @override
  Widget build(BuildContext context) {
    final donationsState = ref.watch(donationsProvider);
    final profile = ref.watch(profileProvider).profile;
    final loc = AppLocalizations.of(context);

    final activeFilter = donationsState.filter.categoryId;
    final isMyDonations = activeFilter == 'MY';
    final displayed = isMyDonations
        ? donationsState.myDonations
        : donationsState.filteredDonations;
    final grouped = _groupByCategory(displayed);

    final displayCountry = _locationCountry ?? 'Algeria';
    final displayLocation =
        _locationLabel ??
        _profileLocationLabel(profile) ??
        'Location unavailable';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryMid,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayCountry,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    displayLocation,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      _IconButton(icon: Icons.search_rounded, onTap: () {}),
                      const SizedBox(width: 8),
                      _IconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () => context.push('/notifications'),
                        hasBadge: true,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceVariant,
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child:
                                (profile?.avatarUrl != null &&
                                    (profile?.avatarUrl ?? '').isNotEmpty)
                                ? Image.network(
                                    profile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _buildProfilePlaceholder(),
                                  )
                                : _buildProfilePlaceholder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: loc.searchAnything,
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filterOptions.length, (i) {
                        final option = _filterOptions[i];
                        final label = _getFilterLabels(loc)[i];
                        final selected = activeFilter == option;

                        return GestureDetector(
                          onTap: () {
                            if (option == 'MY') {
                              ref
                                  .read(donationsProvider.notifier)
                                  .fetchMyDonations();
                              ref
                                  .read(donationsProvider.notifier)
                                  .setFilter('MY');
                              return;
                            }

                            ref
                                .read(donationsProvider.notifier)
                                .setFilter(option);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        loc.nearYou,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _buildCarousel(displayed),
                  ],
                ),
              ),
              if (donationsState.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryMid,
                    ),
                  ),
                )
              else if (displayed.isEmpty)
                const SliverToBoxAdapter(child: _EmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = grouped.entries.toList()[index];
                    return _buildCategorySection(
                      category: entry.key,
                      donations: entry.value,
                      isMyDonations: isMyDonations,
                      loc: loc,
                    );
                  }, childCount: grouped.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<DonationModel> donations) {
    final carouselItems = donations.take(4).toList();
    if (carouselItems.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 48))),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: carouselItems.length,
            onPageChanged: (i) => setState(() => _carouselIndex = i),
            itemBuilder: (context, index) {
              final donation = carouselItems[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primarySurface,
                ),
                clipBehavior: Clip.antiAlias,
                child: donation.imageUrl != null
                    ? Image.network(
                        donation.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) =>
                            _carouselPlaceholder(donation),
                      )
                    : _carouselPlaceholder(donation),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselItems.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _carouselIndex == i ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _carouselIndex == i
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _carouselPlaceholder(DonationModel donation) {
    return Container(
      color: AppColors.primarySurface,
      child: Center(
        child: Text(
          donation.isFresh
              ? '🥗'
              : donation.isUrgent
              ? '⚡'
              : '🌾',
          style: const TextStyle(fontSize: 52),
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String category,
    required List<DonationModel> donations,
    required bool isMyDonations,
    required AppLocalizations loc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _categoryLabel(category, loc),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    ref.read(donationsProvider.notifier).setFilter(category),
                child: Text(
                  loc.seeAll,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...donations.map((donation) {
          return _buildHorizontalCard(
            donation,
            isMyDonationCard: isMyDonations,
            loc: loc,
          );
        }),
      ],
    );
  }

  Widget _buildHorizontalCard(
    DonationModel donation, {
    required bool isMyDonationCard,
    required AppLocalizations loc,
  }) {
    return GestureDetector(
      onTap: () {
        context.go('/donation/${donation.id}', extra: donation);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: donation.imageUrl != null
                      ? Image.network(
                          donation.imageUrl!,
                          width: 110,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _cardImagePlaceholder(donation),
                        )
                      : _cardImagePlaceholder(donation),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: donation.isUrgent
                            ? AppColors.error
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _expireText(donation.expiresAt),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            donation.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.favorite_border_rounded,
                          size: 18,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _Tag(label: _categoryLabel(donation.category, loc)),
                        _Tag(label: donation.quantity),
                        _CategoryTag(category: donation.category, loc: loc),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primaryMid,
                          child: Text(
                            'K',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Karima',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: Color(0xFFFFC107),
                        ),
                        const Text(
                          ' 4.7 · 56 Posts',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            donation.meetingZone ??
                                'Les arcades, Skikda ${donation.distanceText}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isMyDonationCard)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CardActionButton(
                                label: loc.update,
                                backgroundColor: AppColors.primarySurface,
                                textColor: AppColors.primary,
                                onTap: () => _onUpdateDonation(donation),
                              ),
                              const SizedBox(width: 6),
                              _CardActionButton(
                                label: loc.delete,
                                backgroundColor: AppColors.errorSurface,
                                textColor: AppColors.error,
                                onTap: () => _onDeleteDonation(donation),
                              ),
                            ],
                          )
                        else if (donation.isAvailable)
                          GestureDetector(
                            onTap: () async {
                              final success = await ref
                                  .read(donationsProvider.notifier)
                                  .reserveDonation(donation.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? '✅ Reserved successfully!'
                                        : '❌ Reservation failed',
                                  ),
                                  backgroundColor: success
                                      ? AppColors.primaryMid
                                      : AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                loc.reserve,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardImagePlaceholder(DonationModel donation) {
    return Container(
      width: 110,
      height: 130,
      color: donation.isFresh
          ? AppColors.primarySurface
          : donation.isUrgent
          ? AppColors.errorSurface
          : AppColors.accentSurface,
      child: Center(
        child: Text(
          donation.isFresh
              ? '🥗'
              : donation.isUrgent
              ? '⚡'
              : '🌾',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  Map<String, List<DonationModel>> _groupByCategory(
    List<DonationModel> donations,
  ) {
    final grouped = <String, List<DonationModel>>{};
    for (final donation in donations) {
      grouped.putIfAbsent(donation.category, () => []).add(donation);
    }
    return grouped;
  }

  String _categoryLabel(String category, AppLocalizations loc) {
    switch (category) {
      case 'FRESH':
        return loc.fresh;
      case 'DRY':
        return loc.dry;
      case 'URGENT':
        return loc.urgent;
      default:
        return category;
    }
  }

  String _expireText(String expiresAt) {
    try {
      final expiry = DateTime.parse(expiresAt);
      final diff = expiry.difference(DateTime.now());
      if (diff.inDays > 0) return 'Expires in ${diff.inDays}d';
      if (diff.inHours > 0) return 'Expires in ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'Expires in ${diff.inMinutes}min';
      return 'Expired';
    } catch (_) {
      return 'Expire soon';
    }
  }

  Widget _buildProfilePlaceholder() {
    return const Center(child: Text('👤', style: TextStyle(fontSize: 20)));
  }

  String? _profileLocationLabel(ProfileModel? profile) {
    final baladiya = profile?.baladiya?.trim();
    final wilaya = profile?.wilaya?.trim();

    final parts = <String>[];
    if (baladiya != null && baladiya.isNotEmpty) {
      parts.add(baladiya);
    }
    if (wilaya != null && wilaya.isNotEmpty && wilaya != baladiya) {
      parts.add(wilaya);
    }

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> _onUpdateDonation(DonationModel donation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddDonationScreen(initialDonation: donation),
      ),
    );
  }

  Future<void> _onDeleteDonation(DonationModel donation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Donation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${donation.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref
        .read(donationsProvider.notifier)
        .deleteDonation(donation.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Donation deleted successfully'
              : 'Failed to delete donation',
        ),
        backgroundColor: success ? AppColors.primaryMid : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          if (hasBadge)
            const Positioned(
              top: 6,
              right: 6,
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category, required this.loc});

  final String category;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;

    switch (category) {
      case 'FRESH':
        bg = AppColors.primarySurface;
        textColor = AppColors.primary;
        label = loc.fresh;
        break;
      case 'URGENT':
        bg = AppColors.errorSurface;
        textColor = AppColors.error;
        label = loc.urgent;
        break;
      default:
        bg = AppColors.accentSurface;
        textColor = AppColors.accent;
        label = loc.dry;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Text('🍽️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'No donations nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share food\nin your neighborhood!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
