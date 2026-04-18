import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ne3ma/core/providers/location_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/donation_model.dart';
import '../../providers/donation_provider.dart';

class DonationDetailScreen extends ConsumerStatefulWidget {
  const DonationDetailScreen({
    super.key,
    required this.donation,
  });

  final DonationModel donation;

  @override
  ConsumerState<DonationDetailScreen> createState() =>
      _DonationDetailScreenState();
}

class _DonationDetailScreenState extends ConsumerState<DonationDetailScreen> {
  bool _isReserving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = ref.read(locationProvider);
      if (!location.hasLocation) {
        ref.read(locationProvider.notifier).fetchLocation();
      }
    });
  }

  Future<void> _onReserve() async {
    if (_isReserving) return;

    // ── Already reserved ──────────────────────
    if (!widget.donation.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This donation is no longer available'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isReserving = true);
    debugPrint('📤 DonationDetail: Reserving ${widget.donation.id}...');

    final success = await ref
        .read(donationsProvider.notifier)
        .reserveDonation(widget.donation.id);

    if (!mounted) return;
    setState(() => _isReserving = false);

    if (success) {
      debugPrint('✅ DonationDetail: Reserved!');
      _showSuccessDialog();
    } else {
      debugPrint('❌ DonationDetail: Reservation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reserved!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your reservation is pending confirmation from the donor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Scrollable content ───────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Hero Image ───────────────
                  _buildHeroImage(donation),

                  // ── Content ──────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Title + Tags + Expire
                        _buildTitleSection(donation),

                        const SizedBox(height: 16),

                        // ── User Card ────────────
                        _buildUserCard(donation),

                        const SizedBox(height: 20),

                        // ── Description ──────────
                        _buildDescription(donation),

                        const SizedBox(height: 20),

                        // ── Location ─────────────
                        _buildLocation(donation),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Bar ───────────────────────
          _buildBottomBar(donation),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  // ── Hero Image ─────────────────────────────────
  Widget _buildHeroImage(DonationModel donation) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: donation.imageUrl != null && donation.imageUrl!.isNotEmpty
          ? Image.network(
              donation.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imagePlaceholder(donation),
            )
          : _imagePlaceholder(donation),
    );
  }

  Widget _imagePlaceholder(DonationModel donation) {
    return Container(
      color: donation.isFresh
          ? AppColors.primarySurface
          : donation.isUrgent
              ? AppColors.errorSurface
              : AppColors.accentSurface,
      child: Center(
        child: Text(
          donation.isFresh ? '🥗' : donation.isUrgent ? '⚡' : '🌾',
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  // ── Title Section ──────────────────────────────
  Widget _buildTitleSection(DonationModel donation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title ─────────────────────────────
        Text(
          donation.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),

        // ── Tags row ──────────────────────────
        Row(
          children: [
            _Tag(
              label: _categoryLabel(donation.category),
              bg: AppColors.surfaceVariant,
              textColor: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            _Tag(
              label: donation.quantity,
              bg: AppColors.surfaceVariant,
              textColor: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            if (donation.isUrgent)
              _Tag(
                label: 'Urgent',
                bg: AppColors.error,
                textColor: Colors.white,
              )
            else if (donation.isFresh)
              _Tag(
                label: 'Fresh',
                bg: AppColors.primarySurface,
                textColor: AppColors.primary,
              )
            else
              _Tag(
                label: 'Dry',
                bg: AppColors.accentSurface,
                textColor: AppColors.accent,
              ),

            const Spacer(),

            // ── Expire badge ──────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                _expireText(donation.expiresAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── User Card ──────────────────────────────────
  Widget _buildUserCard(DonationModel donation) {
    final donorName = donation.donorName?.trim().isNotEmpty == true
        ? donation.donorName!.trim()
        : 'Community Member';
    final donorInitial = donorName.characters.first.toUpperCase();
    final donorLocation = _donorLocation(donation);
    final donorRole = _formatUserRole(donation.donorRole);
    final donorBadge = _formatBadge(donation.donorBadge);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // ── Avatar ────────────────────────────
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryMid,
            backgroundImage: donation.donorAvatarUrl != null &&
                    donation.donorAvatarUrl!.isNotEmpty
                ? NetworkImage(donation.donorAvatarUrl!)
                : null,
            child: donation.donorAvatarUrl == null ||
                    donation.donorAvatarUrl!.isEmpty
                ? Text(
                    donorInitial,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // ── Name + donor info ─────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donorName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    Flexible(
                      child: Text(
                        ' $donorLocation',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (donorRole != null)
                      Flexible(
                        child: Text(
                          '  •  $donorRole',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Badge ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  donorBadge ?? 'Member',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ────────────────────────────────
  Widget _buildDescription(DonationModel donation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        if (donation.description != null)
          Text(
            donation.description!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

        const SizedBox(height: 14),

        // ── Quantity ──────────────────────────
        _InfoRow(
          label: 'Quantity Available :',
          value: donation.quantity,
        ),
        const SizedBox(height: 6),

        // ── Pickup type ───────────────────────
        _InfoRow(
          label: 'Pickup Type :',
          value: donation.pickupType == 'PICKUP' ? 'Pickup' : 'Drop off',
        ),
      ],
    );
  }

  // ── Location ───────────────────────────────────
  Widget _buildLocation(DonationModel donation) {
    final locationState = ref.watch(locationProvider);
    final hasDonationLocation = donation.lat != null && donation.lng != null;

    if (!hasDonationLocation) {
      return _buildLocationPlaceholder(donation);
    }

    final donationPoint = LatLng(donation.lat!, donation.lng!);
    final userPoint = locationState.hasLocation
        ? LatLng(locationState.lat!, locationState.lng!)
        : null;
    final center = userPoint == null
        ? donationPoint
        : LatLng(
            (donationPoint.latitude + userPoint.latitude) / 2,
            (donationPoint.longitude + userPoint.longitude) / 2,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _mapZoomForPoints(
                      donationPoint: donationPoint,
                      userPoint: userPoint,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ne3ma',
                    ),
                    if (userPoint != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [userPoint, donationPoint],
                            color: AppColors.primary.withValues(alpha: 0.28),
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: donationPoint,
                          width: 52,
                          height: 52,
                          child: const _MapMarker(
                            icon: Icons.location_on_rounded,
                            color: AppColors.primary,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        if (userPoint != null)
                          Marker(
                            point: userPoint,
                            width: 44,
                            height: 44,
                            child: const _MapMarker(
                              icon: Icons.my_location_rounded,
                              color: AppColors.accent,
                              backgroundColor: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 10,
                  right: 54,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          donation.meetingZone ?? 'Meeting zone',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (donation.distanceKm != null || userPoint != null)
                          const SizedBox(height: 2),
                        if (donation.distanceKm != null)
                          Text(
                            '${donation.distanceKm!.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else if (userPoint != null)
                          const Text(
                            'Showing your location and donation point',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPlaceholder(DonationModel donation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 150,
            width: double.infinity,
            color: const Color(0xFFE8F0E8),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 40,
                        color: AppColors.primaryMid,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        donation.meetingZone ?? 'Meeting zone',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (donation.distanceKm != null)
                        Text(
                          '${donation.distanceKm!.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _mapZoomForPoints({
    required LatLng donationPoint,
    LatLng? userPoint,
  }) {
    if (userPoint == null) return 15;

    final distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      donationPoint,
      userPoint,
    );

    if (distanceKm < 1) return 15;
    if (distanceKm < 3) return 14;
    if (distanceKm < 8) return 13;
    if (distanceKm < 15) return 12;
    if (distanceKm < 30) return 11;
    return 10;
  }

  // ── Bottom Bar ─────────────────────────────────
  Widget _buildBottomBar(DonationModel donation) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [

          // ── Chat button ──────────────────────
          GestureDetector(
            onTap: () {
              // TODO: navigate to chat
              debugPrint('💬 DonationDetail: Opening chat...');
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Reserve button ───────────────────
          Expanded(
            child: GestureDetector(
              onTap: _onReserve,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: !donation.isAvailable
                      ? AppColors.border
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: _isReserving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          !donation.isAvailable
                              ? _statusLabel(donation.status)
                              : 'Reserve',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: !donation.isAvailable
                                ? AppColors.textSecondary
                                : Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────
  String _categoryLabel(String category) {
    switch (category) {
      case 'FRESH':  return 'Fruits';
      case 'DRY':    return 'Grains';
      case 'URGENT': return 'Meals';
      default:       return category;
    }
  }

  String _expireText(String expiresAt) {
    try {
      final expiry = DateTime.parse(expiresAt);
      final diff   = expiry.difference(DateTime.now());
      if (diff.isNegative)     return 'Expired';
      if (diff.inDays > 0)     return 'Expire in ${diff.inDays}d';
      if (diff.inHours > 0)    return 'Expire in ${diff.inHours}h ${diff.inMinutes % 60}min';
      if (diff.inMinutes > 0)  return 'Expire in ${diff.inMinutes}min';
      return 'Expiring soon';
    } catch (_) {
      return 'Expire soon';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'RESERVED':  return 'Already Reserved';
      case 'CONFIRMED': return 'Confirmed';
      case 'COMPLETED': return 'Completed';
      case 'EXPIRED':   return 'Expired';
      default:          return status;
    }
  }

  String _donorLocation(DonationModel donation) {
    final baladiya = donation.donorBaladiya?.trim();
    final wilaya = donation.donorWilaya?.trim();

    if (baladiya != null &&
        baladiya.isNotEmpty &&
        wilaya != null &&
        wilaya.isNotEmpty) {
      return '$baladiya, $wilaya';
    }
    if (baladiya != null && baladiya.isNotEmpty) {
      return baladiya;
    }
    if (wilaya != null && wilaya.isNotEmpty) {
      return wilaya;
    }
    if (donation.meetingZone?.trim().isNotEmpty == true) {
      return donation.meetingZone!.trim();
    }
    return 'Location unavailable';
  }

  String? _formatUserRole(String? rawRole) {
    switch (rawRole) {
      case 'ASSOCIATION':
        return 'Association';
      case 'MAYOR':
        return 'Mayor';
      case 'ADMIN':
        return 'Admin';
      case 'USER':
        return 'User';
      default:
        return null;
    }
  }

  String? _formatBadge(String? rawBadge) {
    switch (rawBadge) {
      case 'FOOD_DONATOR':
        return 'Food Donator';
      case 'BRONZE':
        return 'Bronze';
      case 'SILVER':
        return 'Silver';
      case 'GOLD':
        return 'Gold';
      default:
        return null;
    }
  }
}

// ── Tag Widget ─────────────────────────────────────────
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.bg,
    required this.textColor,
  });

  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Info Row Widget ────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          TextSpan(
            text: ' $value',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.size = 20,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: size, color: color),
    );
  }
}
