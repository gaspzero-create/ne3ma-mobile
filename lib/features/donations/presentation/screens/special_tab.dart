import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/chat/presentation/screens/chat_screen.dart';
import 'package:ne3ma/features/donations/data/models/donation_model.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';
import 'package:ne3ma/features/donations/presentation/screens/reservation_confirmed_screen.dart';
import 'package:ne3ma/features/donations/presentation/screens/reservation_declined_screen.dart';

class SpecialTab extends ConsumerStatefulWidget {
  const SpecialTab({super.key});

  @override
  ConsumerState<SpecialTab> createState() => _SpecialTabState();
}

class _SpecialTabState extends ConsumerState<SpecialTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ── Fetch both on open ─────────────────────
      ref.read(donationsProvider.notifier).fetchMyReservations();
      ref.read(donationsProvider.notifier).fetchMyDonationReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Center(
                child: Text(
                  'Special',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Bar ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'My Reservation'), // beneficiary view
                    Tab(text: 'Reserved'), // donor view
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab Views ────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MyReservedTab(), // Tab 0 — I reserved from others
                  _MyDonationsTab(), // Tab 1 — people who reserved from me
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// TAB 0 — My Donations (donor sees who reserved from him)
// ══════════════════════════════════════════════════════
class _MyDonationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donationsProvider);

    if (state.isDonationReservationsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMid),
      );
    }

    if (state.myDonationReservations.isEmpty) {
      return _EmptyState(
        emoji: '📦',
        title: 'No reservations yet',
        subtitle: 'When someone reserves\nyour donation it appears here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(donationsProvider.notifier).fetchMyDonationReservations(),
      color: AppColors.primaryMid,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: state.myDonationReservations.length,
        itemBuilder: (context, index) {
          final reservation = state.myDonationReservations[index];
          return _DonorReservationCard(
            reservation: reservation,
            onConfirm: () =>
                _onConfirm(context, ref, reservation.id, reservation),
            onComplete: () =>
                _onComplete(context, ref, reservation.id, reservation),
            onCancel: () =>
                _onCancel(context, ref, reservation.id, reservation),
            onChat: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: reservation.id,
                  otherUserName: reservation.beneficiaryName ?? 'Beneficiary',
                  otherUserAvatarUrl: reservation.beneficiaryAvatarUrl,
                  donationTitle: reservation.donationTitle ?? 'Donation',
                  donationStatus: reservation.status,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onConfirm(
    BuildContext context,
    WidgetRef ref,
    String reservationId,
    ReservationModel reservation,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Reservation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Accept this reservation? The beneficiary will be notified and chat will open.',
          style: TextStyle(color: AppColors.textSecondary),
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
              'Confirm',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    debugPrint('📤 SpecialTab: Confirming $reservationId...');
    final success = await ref
        .read(donationsProvider.notifier)
        .confirmReservation(reservationId);

    if (!context.mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReservationConfirmedScreen(
            beneficiaryName: reservation.beneficiaryName ?? 'Beneficiary',
            reservationId: reservationId,
            donationTitle: reservation.donationTitle,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Failed to confirm'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _onComplete(
    BuildContext context,
    WidgetRef ref,
    String reservationId,
    ReservationModel reservation,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Complete Donation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Has the beneficiary received the donation? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Not yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, Complete',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    debugPrint('📤 SpecialTab: Completing $reservationId...');
    final success = await ref
        .read(donationsProvider.notifier)
        .completeReservation(reservationId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '✅ Donation completed!' : '❌ Failed to complete',
        ),
        backgroundColor: success ? AppColors.primaryMid : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _onCancel(
    BuildContext context,
    WidgetRef ref,
    String reservationId,
    ReservationModel reservation,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Reject this reservation? The donation will return to available.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, Cancel',
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
        .cancelReservation(reservationId);

    if (!context.mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReservationDeclinedScreen(
            beneficiaryName: reservation.beneficiaryName ?? 'Beneficiary',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to cancel'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════
// TAB 1 — My Reserved (beneficiary sees what he reserved)
// ══════════════════════════════════════════════════════
class _MyReservedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donationsProvider);

    if (state.isReservationsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMid),
      );
    }

    if (state.myReservations.isEmpty) {
      return _EmptyState(
        emoji: '🛒',
        title: 'No reservations yet',
        subtitle: 'Reserve a donation from\nthe home page!',
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(donationsProvider.notifier).fetchMyReservations(),
      color: AppColors.primaryMid,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: state.myReservations.length,
        itemBuilder: (context, index) {
          final reservation = state.myReservations[index];
          return _BeneficiaryReservationCard(
            reservation: reservation,
            onCancel: () => _onCancel(context, ref, reservation.id),
            onChat: reservation.status == 'CONFIRMED'
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: reservation.id,
                        otherUserName: reservation.donorName ?? 'Donor',
                        otherUserAvatarUrl: reservation.donorAvatarUrl,
                        donationTitle: reservation.donationTitle ?? 'Donation',
                        donationStatus: reservation.status,
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _onCancel(
    BuildContext context,
    WidgetRef ref,
    String reservationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to cancel this reservation?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes, Cancel',
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
        .cancelReservation(reservationId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Reservation cancelled' : 'Failed to cancel'),
        backgroundColor: success ? AppColors.primaryMid : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// DONOR RESERVATION CARD
// ══════════════════════════════════════════════════════
class _DonorReservationCard extends StatelessWidget {
  const _DonorReservationCard({
    required this.reservation,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
    required this.onChat,
  });

  final ReservationModel reservation;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final isPending = reservation.status == 'PENDING';
    final isConfirmed = reservation.status == 'CONFIRMED';
    final beneficiaryName = reservation.beneficiaryName?.isNotEmpty == true
        ? reservation.beneficiaryName!
        : 'Someone';
    final initial = beneficiaryName[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (Avatar, Name, Rating, Time) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7FA668), // Sage
                  radius: 18,
                  backgroundImage: reservation.beneficiaryAvatarUrl != null
                      ? NetworkImage(reservation.beneficiaryAvatarUrl!)
                      : null,
                  child: reservation.beneficiaryAvatarUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beneficiaryName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: const [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 14,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '4.7',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _timeAgo(reservation.reservedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Action Text ──────────────────────────
          if (isPending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: '$beneficiaryName ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(
                      text:
                          'reserved your item. Confirm within 2 hours or it will be released.',
                    ),
                  ],
                ),
              ),
            ),

          if (isPending) const SizedBox(height: 12),

          // ── Inner Item Card ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: reservation.donationImageUrl != null
                        ? Image.network(
                            reservation.donationImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _ImagePlaceholder(
                              category: reservation.donationCategory,
                            ),
                          )
                        : _ImagePlaceholder(
                            category: reservation.donationCategory,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.donationTitle ?? 'Donation',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: [
                            if (reservation.donationCategory != null)
                              _SmallTag(
                                label: _categoryLabel(
                                  reservation.donationCategory!,
                                ),
                              ),
                            if (reservation.donationQuantity != null)
                              _SmallTag(label: reservation.donationQuantity!),
                            if (reservation.donationCategory == 'FRESH' ||
                                reservation.donationCategory == 'Fruits' ||
                                reservation.donationCategory == 'Vegetables')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7FA668),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Text(
                                  'Fresh',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (reservation.donationMeetingZone != null)
                          Text(
                            reservation.donationMeetingZone!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Timer
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '1:59:56',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Buttons ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // ── Chat (only if CONFIRMED) ───────
                if (isConfirmed)
                  Expanded(
                    child: _ActionButton(
                      label: 'Chat',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: AppColors.surfaceVariant,
                      textColor: AppColors.textPrimary,
                      onTap: onChat,
                    ),
                  ),

                if (isConfirmed) const SizedBox(width: 10),

                // ── Complete (only if CONFIRMED) ───
                if (isConfirmed)
                  Expanded(
                    child: _ActionButton(
                      label: 'Complete',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF2E7D32),
                      onTap: onComplete,
                    ),
                  ),

                if (isConfirmed) const SizedBox(width: 10),

                // ── Confirm (only if PENDING) ──────
                if (isPending)
                  Expanded(
                    child: _ActionButton(
                      label: 'Confirm',
                      icon: Icons.check,
                      color: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF2E7D32),
                      onTap: onConfirm,
                    ),
                  ),

                if (isPending) const SizedBox(width: 10),

                // ── Cancel / Decline ───────────────
                if (isPending || isConfirmed)
                  Expanded(
                    child: _ActionButton(
                      label: isPending ? 'Decline' : 'Cancel',
                      icon: Icons.close,
                      color: AppColors.errorSurface,
                      textColor: AppColors.error,
                      onTap: onCancel,
                    ),
                  ),

                // ── Done state ─────────────────────
                if (!isPending && !isConfirmed)
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          _statusLabel(reservation.status),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// BENEFICIARY RESERVATION CARD
// ══════════════════════════════════════════════════════
class _BeneficiaryReservationCard extends StatelessWidget {
  const _BeneficiaryReservationCard({
    required this.reservation,
    required this.onCancel,
    this.onChat,
  });

  final ReservationModel reservation;
  final VoidCallback onCancel;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final isPending = reservation.status == 'PENDING';
    final isConfirmed = reservation.status == 'CONFIRMED';

    // Dynamic donor fetching with fallback
    final String donorName = reservation.donorName?.isNotEmpty == true
        ? reservation.donorName!
        : 'Karima';
    final String initial = donorName[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: reservation.donationImageUrl != null
                      ? Image.network(
                          reservation.donationImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _ImagePlaceholder(
                            category: reservation.donationCategory,
                          ),
                        )
                      : _ImagePlaceholder(
                          category: reservation.donationCategory,
                        ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            reservation.donationTitle ?? 'Donation',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isConfirmed || reservation.status == 'COMPLETED')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: reservation.status == 'COMPLETED'
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFF388E3C),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              reservation.status == 'COMPLETED'
                                  ? '✓ Completed'
                                  : '✓ Confirmed',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (reservation.donationCategory != null)
                          _SmallTag(
                            label: _categoryLabel(
                              reservation.donationCategory!,
                            ),
                          ),
                        if (reservation.donationQuantity != null)
                          _SmallTag(label: reservation.donationQuantity!),
                        if (reservation.donationCategory == 'FRESH' ||
                            reservation.donationCategory == 'Fruits' ||
                            reservation.donationCategory == 'Vegetables')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7FA668),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Fresh',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // User info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF7FA668),
                          radius: 14,
                          backgroundImage: reservation.donorAvatarUrl != null
                              ? NetworkImage(reservation.donorAvatarUrl!)
                              : null,
                          child: reservation.donorAvatarUrl == null
                              ? Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donorName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '4.7 · 47 Posts',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Location ──────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_pin,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reservation.donationMeetingZone ?? 'Les arcades,Skikda',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  '8km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7FA668),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Buttons ───────────────────────────
          Row(
            children: [
              if (isPending || isConfirmed)
                Expanded(
                  child: _ActionButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble,
                    color: AppColors.surfaceVariant,
                    textColor: const Color(0xFF2E7D32),
                    onTap: onChat ?? () {},
                  ),
                ),

              if (isPending) const SizedBox(width: 12),

              if (isPending)
                Expanded(
                  child: _ActionButton(
                    label: 'Cancel',
                    icon: null,
                    color: AppColors.errorSurface,
                    textColor: AppColors.error,
                    onTap: onCancel,
                  ),
                ),

              if (!isPending && !isConfirmed)
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Text(
                        _statusLabel(reservation.status),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────
String _categoryLabel(String c) {
  switch (c) {
    case 'FRESH':
      return 'Fresh';
    case 'DRY':
      return 'Dry';
    case 'URGENT':
      return 'Urgent';
    default:
      return c;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'PENDING':
      return 'Pending';
    case 'CONFIRMED':
      return 'Confirmed';
    case 'CANCELLED':
      return 'Cancelled';
    case 'COMPLETED':
      return 'Completed';
    default:
      return s;
  }
}

String _timeAgo(String dateStr) {
  try {
    final d = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return dateStr;
  }
}

// ── Small Tag ──────────────────────────────────────────
class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.label});
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

// ── Action Button ──────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image Placeholder ──────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.category});
  final String? category;

  @override
  Widget build(BuildContext context) {
    Color bg;
    String emoji;

    switch (category) {
      case 'FRESH':
        bg = AppColors.primarySurface;
        emoji = '🥗';
        break;
      case 'URGENT':
        bg = AppColors.errorSurface;
        emoji = '⚡';
        break;
      default:
        bg = AppColors.accentSurface;
        emoji = '🌾';
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
    );
  }
}

// ── Empty State ────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
