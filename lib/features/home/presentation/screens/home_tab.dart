import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';

import 'package:ne3ma/features/donations/data/models/donation_model.dart';
import 'package:ne3ma/features/donations/presentation/screens/donation_detail_screen.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';
import 'package:ne3ma/features/profile/provider/profile_provider.dart';
import 'package:ne3ma/features/donations/presentation/widgets/donation_card.dart';
import 'package:ne3ma/features/donations/presentation/widgets/donation_card.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
      // Helper to filter only the user's own donations (assuming all in state.donations are user's if fetched with getMyDonations)
      List<DonationModel> get myDonations => ref.watch(donationsProvider).donations;
  // Fetch my donations and update state
  Future<void> _fetchMyDonations() async {
    await ref.read(donationsProvider.notifier).fetchMyDonations();
  }
  double? _lat;
  double? _lng;
  final _searchController    = TextEditingController();
  final _carouselController  = PageController();
  int    _carouselIndex      = 0;

  // ── Filter chip options (null = All) ──────────────────────────────────────
  static const _filterOptions = <String?>[null, 'FRESH', 'DRY', 'URGENT', 'MY'];
  static const _filterLabels  = <String?>['All', 'Fresh', 'Dry', 'Urgent', 'My Donations'];

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Fetch your own donations on Home tab load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(donationsProvider.notifier).fetchMyDonations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  // ── Location + initial fetch ───────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      _fetchDonations(lat: position.latitude, lng: position.longitude);
    } catch (e) {
      debugPrint('❌ HomeTab: Location error - $e');
      _fetchDonations(lat: 36.8976, lng: 7.7459); // Skikda default
    }
  }

  void _fetchDonations({required double lat, required double lng}) {
    ref.read(donationsProvider.notifier).fetchNearbyDonations(
      lat: lat,
      lng: lng,
    );
  }

  Future<void> _onRefresh() async {
    _fetchDonations(
      lat: _lat ?? 36.8976,
      lng: _lng ?? 7.7459,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final donationsState = ref.watch(donationsProvider);
    final profile        = ref.watch(profileProvider).profile;

    // Use filteredDonations for category filters, but handle 'MY' filter separately
    final activeFilter = donationsState.filter.category;
    final isMyDonations = activeFilter == 'MY';
    final displayed = isMyDonations
        ? donationsState.myDonations // Show my own donations
        : donationsState.filteredDonations;
    final grouped   = _groupByCategory(displayed);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryMid,
          child: CustomScrollView(
            slivers: [

              // (Removed always-on My Donations section. Now handled by filter chip.)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      // ── Location ───────────────────────────────────────────
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Algeria',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  profile?.baladiya != null
                                      ? '${profile!.baladiya}, ${profile.wilaya ?? ''}'
                                      : 'Skikda, Skikda',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
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

                      // ── Icons ──────────────────────────────────────────────
                      _IconButton(
                        icon: Icons.search_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _IconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () {},
                        hasBadge: true,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search Bar ──────────────────────────────────────────────────
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
                      decoration: const InputDecoration(
                        hintText: 'Search Anything...',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Filter Chips ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filterOptions.length, (i) {
                        final option   = _filterOptions[i];
                        final label    = _filterLabels[i]!;
                        final selected = activeFilter == option;
                        return GestureDetector(
                          onTap: () {
                            if (option == 'MY') {
                              // Fetch my donations and set filter
                              ref.read(donationsProvider.notifier).fetchMyDonations();
                              ref.read(donationsProvider.notifier).setFilter('MY');
                            } else {
                              ref.read(donationsProvider.notifier).setFilter(option);
                            }
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

              // ── Near You Carousel ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        'Near You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // ✅ Carousel uses filtered list too
                    _buildCarousel(displayed),
                  ],
                ),
              ),

              // ── Grouped Category Sections ───────────────────────────────────
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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = grouped.entries.toList()[index];
                      return _buildCategorySection(
                        category:  entry.key,
                        donations: entry.value,
                      );
                    },
                    childCount: grouped.length,
                  ),
                ),

              // ── Bottom spacing for navbar ───────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carousel ───────────────────────────────────────────────────────────────
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
        child: const Center(
          child: Text('🍽️', style: TextStyle(fontSize: 48)),
        ),
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
              final d = carouselItems[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primarySurface,
                ),
                clipBehavior: Clip.antiAlias,
                child: d.imageUrl != null
                    ? Image.network(
                        d.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _carouselPlaceholder(d),
                      )
                    : _carouselPlaceholder(d),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ── Dots ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselItems.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width:  _carouselIndex == i ? 20 : 7,
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

  Widget _carouselPlaceholder(DonationModel d) {
    return Container(
      color: AppColors.primarySurface,
      child: Center(
        child: Text(
          d.isFresh ? '🥗' : d.isUrgent ? '⚡' : '🌾',
          style: const TextStyle(fontSize: 52),
        ),
      ),
    );
  }

  // ── Category Section ───────────────────────────────────────────────────────
  Widget _buildCategorySection({
    required String             category,
    required List<DonationModel> donations,
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
                _categoryLabel(category),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                // ✅ "see all" applies the matching filter chip
                onTap: () => ref
                    .read(donationsProvider.notifier)
                    .setFilter(category),
                child: const Text(
                  'see all',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...donations.map((d) => _buildHorizontalCard(d)),
      ],
    );
  }

  // ── Horizontal Donation Card ───────────────────────────────────────────────
  Widget _buildHorizontalCard(DonationModel donation) {
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
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        children: [

          // ── Image ─────────────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: donation.imageUrl != null
                    ? Image.network(
                        donation.imageUrl!,
                        width:  110,
                        height: 130,
                        fit:    BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _cardImagePlaceholder(donation),
                      )
                    : _cardImagePlaceholder(donation),
              ),

              // ── Expire badge ───────────────────────────────────────────────
              Positioned(
                bottom: 8, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: donation.isUrgent
                          ? AppColors.error
                          : Colors.black.withOpacity(0.6),
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

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Title + Heart ────────────────────────────────────────
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

                  // ── Tags ──────────────────────────────────────────────────
                  Wrap(
                    spacing: 4, runSpacing: 4,
                    children: [
                      _Tag(label: _categoryLabel(donation.category)),
                      _Tag(label: donation.quantity),
                      _CategoryTag(category: donation.category),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── User info ─────────────────────────────────────────────
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.primaryMid,
                        child: const Text(
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

                  // ── Location + Reserve ────────────────────────────────────
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

                      // ✅ Reserve button wired to reserveDonation()
                      if (donation.isAvailable)
                        GestureDetector(
                          onTap: () async {
                            final success = await ref
                                .read(donationsProvider.notifier)
                                .reserveDonation(donation.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? '✅ Reserved successfully!'
                                    : '❌ Reservation failed'),
                                backgroundColor: success
                                    ? AppColors.primaryMid
                                    : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Reserve',
                              style: TextStyle(
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
          donation.isFresh ? '🥗' : donation.isUrgent ? '⚡' : '🌾',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Map<String, List<DonationModel>> _groupByCategory(
    List<DonationModel> donations,
  ) {
    final Map<String, List<DonationModel>> grouped = {};
    for (final d in donations) {
      grouped.putIfAbsent(d.category, () => []).add(d);
    }
    return grouped;
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'FRESH':  return 'Fresh';
      case 'DRY':    return 'Dry Goods';
      case 'URGENT': return 'Urgent';
      default:       return category;
    }
  }

  String _expireText(String expiresAt) {
    try {
      final expiry = DateTime.parse(expiresAt);
      final diff   = expiry.difference(DateTime.now());
      if (diff.inDays > 0)    return 'Expires in ${diff.inDays}d';
      if (diff.inHours > 0)   return 'Expires in ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'Expires in ${diff.inMinutes}min';
      return 'Expired';
    } catch (_) {
      return 'Expire soon';
    }
  }
}

// ── Icon Button ────────────────────────────────────────────────────────────────
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  final IconData     icon;
  final VoidCallback onTap;
  final bool         hasBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          if (hasBadge)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tag ────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color:      AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Category Tag (colored) ─────────────────────────────────────────────────────
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    Color  bg;
    Color  textColor;
    String label;

    switch (category) {
      case 'FRESH':
        bg        = AppColors.primarySurface;
        textColor = AppColors.primary;
        label     = 'Fresh';
        break;
      case 'URGENT':
        bg        = AppColors.errorSurface;
        textColor = AppColors.error;
        label     = 'Urgent';
        break;
      default:
        bg        = AppColors.accentSurface;
        textColor = AppColors.accent;
        label     = 'Dry';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color:      textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
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